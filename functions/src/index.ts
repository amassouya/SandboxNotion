import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import OpenAI from 'openai';
import * as express from 'express';
import * as cors from 'cors';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { defineSecret } from 'firebase-functions/params';
import { logger } from 'firebase-functions';

// Initialize Firebase Admin
admin.initializeApp();

const db = getFirestore();
const auth = getAuth();

// Define secrets
const openaiApiKey = defineSecret('OPENAI_API_KEY');

// Initialize OpenAI client
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Constants
const MONTHLY_QUOTA = {
  FREE: {
    TEXT_TOKENS: 10000,
    VISION_REQUESTS: 10,
    WHISPER_SECONDS: 60,
  },
  PREMIUM: {
    TEXT_TOKENS: 100000,
    VISION_REQUESTS: 100,
    WHISPER_SECONDS: 600,
  },
};

const RATE_LIMITS = {
  FREE: {
    REQUESTS_PER_MINUTE: 10,
  },
  PREMIUM: {
    REQUESTS_PER_MINUTE: 60,
  },
};

// Interfaces
interface UserQuota {
  textTokensUsed: number;
  visionRequestsUsed: number;
  whisperSecondsUsed: number;
  lastResetDate: admin.firestore.Timestamp;
}

interface UserSubscription {
  status: 'free' | 'premium';
  expiryDate?: admin.firestore.Timestamp;
  platform?: 'android' | 'ios' | 'web';
  productId?: string;
}

// Middleware
const validateAuth = async (req: functions.https.Request): Promise<admin.auth.DecodedIdToken> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new HttpsError('unauthenticated', 'Unauthorized request');
  }

  const idToken = authHeader.split('Bearer ')[1];
  try {
    return await auth.verifyIdToken(idToken);
  } catch (error) {
    logger.error('Auth verification failed', error);
    throw new HttpsError('unauthenticated', 'Invalid authentication');
  }
};

const checkRateLimit = async (userId: string, subscriptionStatus: 'free' | 'premium'): Promise<void> => {
  const rateRef = db.collection('rateLimits').doc(userId);
  
  await db.runTransaction(async (transaction) => {
    const rateDoc = await transaction.get(rateRef);
    const now = admin.firestore.Timestamp.now();
    const oneMinuteAgo = new admin.firestore.Timestamp(
      now.seconds - 60,
      now.nanoseconds
    );
    
    let requestsInLastMinute = 0;
    let requests: { timestamp: admin.firestore.Timestamp }[] = [];
    
    if (rateDoc.exists) {
      const data = rateDoc.data();
      requests = data?.requests || [];
      // Filter requests from last minute
      requests = requests.filter(r => r.timestamp.toMillis() >= oneMinuteAgo.toMillis());
      requestsInLastMinute = requests.length;
    }
    
    const limit = subscriptionStatus === 'premium' 
      ? RATE_LIMITS.PREMIUM.REQUESTS_PER_MINUTE 
      : RATE_LIMITS.FREE.REQUESTS_PER_MINUTE;
    
    if (requestsInLastMinute >= limit) {
      throw new HttpsError(
        'resource-exhausted',
        `Rate limit exceeded. Maximum ${limit} requests per minute.`
      );
    }
    
    // Add current request
    requests.push({ timestamp: now });
    
    transaction.set(rateRef, { requests }, { merge: true });
  });
};

const checkAndUpdateQuota = async (
  userId: string, 
  subscriptionStatus: 'free' | 'premium',
  quotaType: 'textTokens' | 'visionRequests' | 'whisperSeconds',
  amount: number
): Promise<void> => {
  const quotaRef = db.collection('userQuotas').doc(userId);
  
  await db.runTransaction(async (transaction) => {
    const quotaDoc = await transaction.get(quotaRef);
    const now = admin.firestore.Timestamp.now();
    const currentMonth = new Date(now.toDate()).getMonth();
    const currentYear = new Date(now.toDate()).getFullYear();
    
    let quota: UserQuota = {
      textTokensUsed: 0,
      visionRequestsUsed: 0,
      whisperSecondsUsed: 0,
      lastResetDate: now,
    };
    
    if (quotaDoc.exists) {
      const data = quotaDoc.data() as UserQuota;
      quota = data;
      
      // Check if we need to reset monthly quota
      const lastResetMonth = new Date(data.lastResetDate.toDate()).getMonth();
      const lastResetYear = new Date(data.lastResetDate.toDate()).getFullYear();
      
      if (lastResetMonth !== currentMonth || lastResetYear !== currentYear) {
        // Reset quota for new month
        quota = {
          textTokensUsed: 0,
          visionRequestsUsed: 0,
          whisperSecondsUsed: 0,
          lastResetDate: now,
        };
      }
    }
    
    // Check quota limits
    const limits = subscriptionStatus === 'premium' ? MONTHLY_QUOTA.PREMIUM : MONTHLY_QUOTA.FREE;
    
    if (quotaType === 'textTokens' && quota.textTokensUsed + amount > limits.TEXT_TOKENS) {
      throw new HttpsError(
        'resource-exhausted',
        `Monthly text token quota exceeded. Limit: ${limits.TEXT_TOKENS}`
      );
    } else if (quotaType === 'visionRequests' && quota.visionRequestsUsed + amount > limits.VISION_REQUESTS) {
      throw new HttpsError(
        'resource-exhausted',
        `Monthly vision requests quota exceeded. Limit: ${limits.VISION_REQUESTS}`
      );
    } else if (quotaType === 'whisperSeconds' && quota.whisperSecondsUsed + amount > limits.WHISPER_SECONDS) {
      throw new HttpsError(
        'resource-exhausted',
        `Monthly audio transcription quota exceeded. Limit: ${limits.WHISPER_SECONDS} seconds`
      );
    }
    
    // Update quota
    if (quotaType === 'textTokens') {
      quota.textTokensUsed += amount;
    } else if (quotaType === 'visionRequests') {
      quota.visionRequestsUsed += amount;
    } else if (quotaType === 'whisperSeconds') {
      quota.whisperSecondsUsed += amount;
    }
    
    transaction.set(quotaRef, quota);
  });
};

const getSubscriptionStatus = async (userId: string): Promise<'free' | 'premium'> => {
  const subscriptionDoc = await db.collection('subscriptions').doc(userId).get();
  
  if (!subscriptionDoc.exists) {
    return 'free';
  }
  
  const subscription = subscriptionDoc.data() as UserSubscription;
  
  // Check if subscription is active
  if (subscription.status === 'premium') {
    // If there's an expiry date, check if it's still valid
    if (subscription.expiryDate) {
      const now = admin.firestore.Timestamp.now();
      if (subscription.expiryDate.toMillis() < now.toMillis()) {
        // Subscription expired
        await db.collection('subscriptions').doc(userId).update({
          status: 'free'
        });
        return 'free';
      }
    }
    return 'premium';
  }
  
  return 'free';
};

// OpenAI Proxy Function
export const openaiProxy = onCall({ secrets: [openaiApiKey] }, async (request) => {
  try {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = request.auth.uid;
    const { type, data } = request.data;
    
    // Get subscription status
    const subscriptionStatus = await getSubscriptionStatus(userId);
    
    // Check rate limit
    await checkRateLimit(userId, subscriptionStatus);
    
    // Process request based on type
    switch (type) {
      case 'text': {
        // Check and update quota before processing
        const estimatedTokens = Math.ceil(data.prompt.length / 4); // Rough estimate
        await checkAndUpdateQuota(userId, subscriptionStatus, 'textTokens', estimatedTokens);
        
        const response = await openai.chat.completions.create({
          model: 'gpt-4o',
          messages: [{ role: 'user', content: data.prompt }],
          max_tokens: data.maxTokens || 1000,
          temperature: data.temperature || 0.7,
        });
        
        // Update actual tokens used
        const actualTokensUsed = response.usage?.total_tokens || estimatedTokens;
        await checkAndUpdateQuota(
          userId, 
          subscriptionStatus, 
          'textTokens', 
          actualTokensUsed - estimatedTokens
        );
        
        return {
          text: response.choices[0]?.message.content,
          usage: response.usage,
        };
      }
      
      case 'vision': {
        // Check quota for vision request
        await checkAndUpdateQuota(userId, subscriptionStatus, 'visionRequests', 1);
        
        const messages = [
          {
            role: 'user',
            content: [
              { type: 'text', text: data.prompt },
              {
                type: 'image_url',
                image_url: {
                  url: data.imageUrl,
                  detail: data.detail || 'auto',
                },
              },
            ],
          },
        ];
        
        const response = await openai.chat.completions.create({
          model: 'gpt-4o',
          messages,
          max_tokens: data.maxTokens || 1000,
        });
        
        return {
          text: response.choices[0]?.message.content,
          usage: response.usage,
        };
      }
      
      case 'whisper': {
        // Estimate audio duration in seconds (rough estimate based on file size)
        const estimatedSeconds = Math.ceil(data.fileSize / 16000); // Assuming 16KB per second
        
        // Check quota for audio transcription
        await checkAndUpdateQuota(userId, subscriptionStatus, 'whisperSeconds', estimatedSeconds);
        
        // For Whisper, we'd need the audio file buffer
        // In a real implementation, this would be handled by uploading to Storage first
        // and then passing the file reference to this function
        
        const response = await openai.audio.transcriptions.create({
          file: Buffer.from(data.audioBase64, 'base64'),
          model: 'whisper-1',
          language: data.language || 'en',
        });
        
        return {
          text: response.text,
          duration: estimatedSeconds,
        };
      }
      
      default:
        throw new HttpsError('invalid-argument', `Unsupported request type: ${type}`);
    }
  } catch (error) {
    logger.error('OpenAI proxy error:', error);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    if (error.response) {
      // OpenAI API error
      throw new HttpsError(
        'internal',
        `OpenAI API error: ${error.response.status} - ${error.response.data.error.message}`
      );
    }
    
    throw new HttpsError('internal', 'An unexpected error occurred');
  }
});

// Check subscription status function
export const checkSubscription = onCall(async (request) => {
  try {
    // Validate authentication
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = request.auth.uid;
    
    // Get subscription status
    const status = await getSubscriptionStatus(userId);
    
    // Get quota information
    const quotaDoc = await db.collection('userQuotas').doc(userId).get();
    let quota: UserQuota = {
      textTokensUsed: 0,
      visionRequestsUsed: 0,
      whisperSecondsUsed: 0,
      lastResetDate: admin.firestore.Timestamp.now(),
    };
    
    if (quotaDoc.exists) {
      quota = quotaDoc.data() as UserQuota;
    }
    
    // Get subscription details if premium
    let subscriptionDetails = null;
    if (status === 'premium') {
      const subscriptionDoc = await db.collection('subscriptions').doc(userId).get();
      if (subscriptionDoc.exists) {
        const data = subscriptionDoc.data() as UserSubscription;
        subscriptionDetails = {
          expiryDate: data.expiryDate?.toDate(),
          platform: data.platform,
          productId: data.productId,
        };
      }
    }
    
    // Calculate quota limits based on subscription
    const limits = status === 'premium' ? MONTHLY_QUOTA.PREMIUM : MONTHLY_QUOTA.FREE;
    
    return {
      status,
      subscriptionDetails,
      quota: {
        textTokens: {
          used: quota.textTokensUsed,
          limit: limits.TEXT_TOKENS,
          remaining: Math.max(0, limits.TEXT_TOKENS - quota.textTokensUsed),
        },
        visionRequests: {
          used: quota.visionRequestsUsed,
          limit: limits.VISION_REQUESTS,
          remaining: Math.max(0, limits.VISION_REQUESTS - quota.visionRequestsUsed),
        },
        whisperSeconds: {
          used: quota.whisperSecondsUsed,
          limit: limits.WHISPER_SECONDS,
          remaining: Math.max(0, limits.WHISPER_SECONDS - quota.whisperSecondsUsed),
        },
        nextReset: getNextMonthReset(quota.lastResetDate.toDate()),
      },
    };
  } catch (error) {
    logger.error('Check subscription error:', error);
    
    if (error instanceof HttpsError) {
      throw error;
    }
    
    throw new HttpsError('internal', 'An unexpected error occurred');
  }
});

// Webhook for handling subscription events from Google Play / App Store
export const subscriptionWebhook = functions.https.onRequest((req, res) => {
  const app = express();
  app.use(cors({ origin: true }));
  app.use(express.json());
  
  app.post('/google-play', async (req, res) => {
    try {
      // Verify the request is from Google Play
      // In production, you'd validate the signature
      
      const event = req.body;
      const { subscriptionId, purchaseToken, userId } = event;
      
      // Verify the purchase with Google Play API (simplified)
      // In production, you'd use the Google Play Developer API
      
      // Update subscription in Firestore
      await db.collection('subscriptions').doc(userId).set({
        status: 'premium',
        expiryDate: admin.firestore.Timestamp.fromMillis(Date.now() + 30 * 24 * 60 * 60 * 1000), // +30 days
        platform: 'android',
        productId: subscriptionId,
        purchaseToken,
        updatedAt: admin.firestore.Timestamp.now(),
      }, { merge: true });
      
      res.status(200).send({ success: true });
    } catch (error) {
      logger.error('Google Play webhook error:', error);
      res.status(500).send({ error: 'Internal server error' });
    }
  });
  
  app.post('/app-store', async (req, res) => {
    try {
      // Verify the request is from Apple App Store
      // In production, you'd validate the receipt with Apple
      
      const event = req.body;
      const { transactionId, originalTransactionId, userId, expiresDate } = event;
      
      // Update subscription in Firestore
      await db.collection('subscriptions').doc(userId).set({
        status: 'premium',
        expiryDate: admin.firestore.Timestamp.fromMillis(expiresDate),
        platform: 'ios',
        productId: originalTransactionId,
        transactionId,
        updatedAt: admin.firestore.Timestamp.now(),
      }, { merge: true });
      
      res.status(200).send({ success: true });
    } catch (error) {
      logger.error('App Store webhook error:', error);
      res.status(500).send({ error: 'Internal server error' });
    }
  });
  
  app.post('/web-payment', async (req, res) => {
    try {
      // Verify the payment was successful
      // In production, you'd validate with Google Pay / Stripe
      
      const { userId, paymentId, expiryTimestamp } = req.body;
      
      // Validate authentication
      try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          return res.status(401).send({ error: 'Unauthorized' });
        }
        
        const idToken = authHeader.split('Bearer ')[1];
        await auth.verifyIdToken(idToken);
      } catch (error) {
        return res.status(401).send({ error: 'Invalid authentication' });
      }
      
      // Update subscription in Firestore
      await db.collection('subscriptions').doc(userId).set({
        status: 'premium',
        expiryDate: admin.firestore.Timestamp.fromMillis(expiryTimestamp),
        platform: 'web',
        productId: paymentId,
        updatedAt: admin.firestore.Timestamp.now(),
      }, { merge: true });
      
      res.status(200).send({ success: true });
    } catch (error) {
      logger.error('Web payment webhook error:', error);
      res.status(500).send({ error: 'Internal server error' });
    }
  });
  
  app(req, res);
});

// Helper function to get next month reset date
function getNextMonthReset(lastReset: Date): Date {
  const nextReset = new Date(lastReset);
  nextReset.setMonth(nextReset.getMonth() + 1);
  nextReset.setDate(1); // First day of next month
  nextReset.setHours(0, 0, 0, 0); // Start of day
  return nextReset;
}
