import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sandboxnotion/services/analytics_service.dart';
import 'package:sandboxnotion/utils/constants.dart';
import 'package:sandboxnotion/utils/platform_utils.dart';

/// A placeholder subscription screen that displays premium features and plans
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Selected plan (0 = monthly, 1 = yearly)
  int _selectedPlan = 1;
  
  // Subscription plans
  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'Monthly',
      'price': 9.99,
      'period': 'month',
      'savings': null,
    },
    {
      'name': 'Yearly',
      'price': 99.99,
      'period': 'year',
      'savings': '17% off',
    },
  ];
  
  // Premium features
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.dashboard_customize,
      'title': 'Unlimited Modules',
      'description': 'Create as many modules as you need with no restrictions',
    },
    {
      'icon': Icons.sync,
      'title': 'Cloud Sync',
      'description': 'Sync your data across all your devices automatically',
    },
    {
      'icon': Icons.smart_toy,
      'title': 'AI Features',
      'description': 'Access advanced AI features for content generation and analysis',
    },
    {
      'icon': Icons.color_lens,
      'title': 'Custom Themes',
      'description': 'Create and customize your own themes and colors',
    },
    {
      'icon': Icons.backup,
      'title': 'Automatic Backups',
      'description': 'Never lose your data with automatic cloud backups',
    },
    {
      'icon': Icons.support_agent,
      'title': 'Priority Support',
      'description': 'Get priority support from our team when you need help',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    // Log screen view
    AnalyticsService.instance.logScreenView(
      screenName: 'subscription',
      screenClass: 'SubscriptionScreen',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Subscription',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back to Settings',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current plan card
              _buildCurrentPlanCard(context, isDarkMode),
              
              const SizedBox(height: 24),
              
              // Premium plans
              _buildPremiumPlans(context, isDarkMode),
              
              const SizedBox(height: 24),
              
              // Premium features
              _buildPremiumFeatures(context, isDarkMode),
              
              const SizedBox(height: 24),
              
              // Upgrade button
              _buildUpgradeButton(context),
              
              const SizedBox(height: 16),
              
              // Coming soon message
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.grey[850] 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppConstants.seedColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.construction,
                        size: 32,
                        color: AppConstants.seedColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Payment Processing Coming Soon',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subscription functionality will be available in the next update.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Terms and conditions
              Text(
                'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions will automatically renew unless canceled at least 24 hours before the end of the current period. You can manage your subscriptions in your account settings.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the current plan card
  Widget _buildCurrentPlanCard(BuildContext context, bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Plan icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Free',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Limitations
            const Text(
              'Free Plan Limitations:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Limitation items
            _buildLimitationItem(
              context,
              'Limited to 5 modules',
              isDarkMode,
            ),
            _buildLimitationItem(
              context,
              'Basic features only',
              isDarkMode,
            ),
            _buildLimitationItem(
              context,
              'No AI features',
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a limitation item
  Widget _buildLimitationItem(BuildContext context, String text, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.remove_circle_outline,
            size: 16,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the premium plans section
  Widget _buildPremiumPlans(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREMIUM PLANS',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Plan toggle
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Monthly plan
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPlan == 0
                          ? AppConstants.seedColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Monthly',
                      style: TextStyle(
                        color: _selectedPlan == 0
                            ? Colors.white
                            : isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Yearly plan
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlan = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPlan == 1
                          ? AppConstants.seedColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Yearly',
                      style: TextStyle(
                        color: _selectedPlan == 1
                            ? Colors.white
                            : isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Selected plan details
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: AppConstants.seedColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppConstants.seedColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium,
                        color: AppConstants.seedColor,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Plan info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Premium ${_plans[_selectedPlan]['name']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Unlock all premium features',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '\$${_plans[_selectedPlan]['price']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: '/${_plans[_selectedPlan]['period']}',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Savings badge
                        if (_plans[_selectedPlan]['savings'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _plans[_selectedPlan]['savings']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Platform-specific payment info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getPaymentIcon(),
                        size: 24,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getPaymentText(),
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the premium features section
  Widget _buildPremiumFeatures(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREMIUM FEATURES',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Features grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _features.length,
          itemBuilder: (context, index) {
            final feature = _features[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Feature icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppConstants.seedColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature['icon'],
                        color: AppConstants.seedColor,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Feature title
                    Text(
                      feature['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Feature description
                    Expanded(
                      child: Text(
                        feature['description'],
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds the upgrade button
  Widget _buildUpgradeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Show coming soon message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription functionality coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Log event
          AnalyticsService.instance.logCustomEvent(
            eventName: 'subscription_upgrade_attempt',
            parameters: {
              'plan': _plans[_selectedPlan]['name'],
              'price': _plans[_selectedPlan]['price'],
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.seedColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Upgrade to Premium ${_plans[_selectedPlan]['name']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// Returns the appropriate payment icon based on platform
  IconData _getPaymentIcon() {
    if (PlatformUtils.isIOS) {
      return Icons.apple;
    } else if (PlatformUtils.isAndroid) {
      return Icons.android;
    } else {
      return Icons.credit_card;
    }
  }

  /// Returns the appropriate payment text based on platform
  String _getPaymentText() {
    if (PlatformUtils.isIOS) {
      return 'Payment will be charged to your Apple ID account at confirmation of purchase.';
    } else if (PlatformUtils.isAndroid) {
      return 'Payment will be charged to your Google Play account at confirmation of purchase.';
    } else {
      return 'Payment will be processed securely via credit card or PayPal at confirmation of purchase.';
    }
  }
}
