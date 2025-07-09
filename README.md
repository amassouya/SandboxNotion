# SandboxNotion

Production-ready, cross-platform productivity app built with Flutter 3.22+ (Android · iOS · Web).  
SandboxNotion combines Calendar, Tasks, Notes, Whiteboards, and Flash-cards in a draggable **sandbox UI**, powered by Firebase and Google-native payments. OpenAI features enable one-tap summaries, flash-card generation, vision captioning, and speech-to-text.

---

## ✨ Features
- Modular snap-grid “sandbox” interface – move & resize Calendar, To-Do, Notes, Whiteboard, Cards.
- Google / Email / Apple sign-in via Firebase Authentication.
- GPT-4o Vision, Whisper & Text endpoints proxied through Cloud Functions with monthly quotas.
- Premium subscription (Google Play Billing v6 · StoreKit 2 · Google Pay Web).
- Realtime sync with Firebase Firestore + offline cache.
- Media uploads to Firebase Storage.
- Dark / Light themes, Lottie empty states, motion transitions.
- CI/CD via GitHub Actions → Firebase Hosting + Functions + Android APK artifact + TestFlight.

---

## 🛠 Tech Stack
| Layer | Technology |
|-------|------------|
| UI | Flutter 3.22, flutter_drawing_board, flutter_quill, Lottie, animations |
| State | Riverpod (Async & Code-gen) |
| Routing | `go_router` |
| Backend | Firebase Auth · Firestore · Storage · Cloud Functions (TypeScript 20) |
| Payments | Play Billing v6 · StoreKit 2 · Google Pay JS |
| AI | OpenAI API (via callable function `openaiProxy`) |
| Tooling | GitHub Actions · Firebase CLI · Melos |

---

## ⚙️ Installation Requirements

| Tool | Version | Docs |
|------|---------|------|
| Flutter SDK | 3.22 or newer | https://docs.flutter.dev |
| Android Studio | Hedgehog or newer (with SDK Manager & AVD) | https://developer.android.com/studio |
| Xcode | 15+ (for iOS / visionOS builds) | https://developer.apple.com/xcode |
| Node.js | 20+ | https://nodejs.org |
| Firebase CLI | `npm i -g firebase-tools` | https://firebase.google.com/docs/cli |
| Git | 2.50+ | https://git-scm.com |

---

## 🚀 Setup Instructions

```bash
# 1. Clone the repo
git clone https://github.com/amassouya/SandboxNotion.git
cd SandboxNotion

# 2. Install Flutter deps
flutter pub get

# 3. Configure Firebase for all platforms
flutterfire configure --project=sandboxnotion

# 4. Copy private config files (NOT committed)
mkdir -p ~/.sandboxnotion
#   place google-services.json, GoogleService-Info.plist, serviceAccount-sandbox.json here

# 5. Run emulators if desired
firebase emulators:start --only firestore,functions
```

---

## 🔑 Firebase Configuration

| File | Location | Notes |
|------|----------|-------|
| `google-services.json.example` | `android/app/` | Copy real file & rename without `.example`. |
| `GoogleService-Info.plist.example` | `ios/Runner/` | Same rule for iOS. |
| Service Account | `~/.sandboxnotion/serviceAccount-sandbox.json` | Used only in CI/CD. |

Environment vars used in CI (`Settings → Secrets and variables → Actions`):

```
OPENAI_API_KEY
FIREBASE_SERVICE_ACCOUNT_SANDBOX
FIREBASE_CLI_TOKEN            # optional, for deploy step
```

---

## ▶️ Running the App

```bash
# Android / iOS (hot-reload)
flutter run -d android      # or -d ios, -d macos, -d chrome

# Web dev server
flutter run -d chrome --web-hostname localhost --web-port 8080
```

---

## 📦 Build & Deploy

| Target | Command |
|--------|---------|
| Android (release APK) | `flutter build apk --release` |
| iOS (archived IPA)    | `flutter build ios --release` |
| Web (release)         | `flutter build web --release` |
| Firebase Hosting      | `firebase deploy --only hosting --project sandboxnotion` |
| Cloud Functions       | `firebase deploy --only functions --project sandboxnotion` |

CI/CD: Every push to `main` triggers `.github/workflows/flutter_firebase.yml`  
– builds, tests, uploads artifacts, and deploys Hosting + Functions.

Preview URL (live): https://sandboxnotion.web.app

---

## 🤝 Contributing

1. Fork the repo & create a feature branch:
   ```bash
   git checkout -b feat/awesome
   ```
2. Commit with conventional messages (`feat:`, `fix:` …).
3. Run `flutter test` and `dart format .`.
4. Open a Pull Request; CI must pass.

We follow the [Contributor Covenant](https://www.contributor-covenant.org/).  
By contributing you agree to abide by its terms.

---

## 📄 License

```
Apache-2.0
Copyright © 2025 SandboxNotion
```

See [LICENSE](LICENSE) for full details.
