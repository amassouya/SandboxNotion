# 🛠️ SandboxNotion – Developer Setup Guide

Welcome to the **SandboxNotion** code-base!  
This document explains how to get the project running on your machine and describes the roadmap for the next development iterations.

---

## 1. Current Project Status ▸ _July 2025_

| Area | Status |
|------|--------|
| Repository | Initialised, Git workflow & CI/CD (GitHub Actions) committed |
| Flutter code | App shell (`main.dart`), routing, core services, utilities scaffolded |
| Firebase | Project **sandboxnotion** created, config placeholders checked-in (`*.example` files) |
| Cloud Functions | TypeScript project scaffolding (`openaiProxy`, subscription hooks) present |
| CI/CD | Builds, tests & deploys on push to `main` (web hosting + functions) |
| Missing | Sandbox UI widgets, feature modules, full tests, production Firebase credentials, payments logic |

---

## 2. Install Flutter 3.22 +

1. **Download SDK**

   | Platform | Link |
   |----------|------|
   | Windows | https://docs.flutter.dev/get-started/install/windows |
   | macOS   | https://docs.flutter.dev/get-started/install/macos |
   | Linux   | https://docs.flutter.dev/get-started/install/linux |

2. **Extract & add to `PATH`**

   ```bash
   # Example (macOS)
   unzip ~/Downloads/flutter_macos_3.22.0-stable.zip -d $HOME
   echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Verify installation**

   ```bash
   flutter --version          # should print ≥ 3.22
   flutter doctor             # fix any missing dependencies (Android Studio, Xcode, etc.)
   ```

---

## 3. Firebase Setup

> All commands assume you are inside the repository root `SandboxNotion/`.

1. **Install CLI**

   ```bash
   npm i -g firebase-tools
   ```

2. **Login & select project**

   ```bash
   firebase login
   firebase use sandboxnotion
   ```

3. **Generate platform configs**

   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure --project=sandboxnotion
   ```

   This creates / updates `firebase_options.dart` and native files.

4. **Provide secret config files (never commit!)**

   ```
   android/app/google-services.json
   ios/Runner/GoogleService-Info.plist
   ~/.sandboxnotion/serviceAccount-sandbox.json
   ```

5. **Enable services inside Firebase Console**

   - Authentication → Email/Password, Google, Apple
   - Firestore (production mode)
   - Cloud Storage
   - Cloud Functions
   - App Check (reCAPTCHA v3, Play Integrity)
   - Billing account for Functions & Play Integrity

---

## 4. Environment Configuration

1. Copy template:

   ```bash
   cp .env.example .env
   ```

2. Fill values:

   | Key | Description |
   |-----|-------------|
   | `OPENAI_API_KEY` | Personal / organisation key used by Cloud Function |
   | `FIREBASE_SERVICE_ACCOUNT_BASE64` or `FIREBASE_SERVICE_ACCOUNT_PATH` | Needed for CI deploys |
   | `FIREBASE_CLI_TOKEN` (optional) | Non-interactive deploys |
   | Payment keys | `GOOGLE_PAY_MERCHANT_ID`, `GOOGLE_PLAY_LICENSE_KEY` |
   | Misc | `APP_ENV` (`development` / `staging` / `production`) |

3. **Local load order**

   `flutter_dotenv` loads `.env` at runtime **only on local builds**.  
   Secrets never ship in release builds – CI injects them via GitHub Secrets.

---

## 5. Running the App Locally

```bash
# Install Dart/Flutter deps
flutter pub get

# Android / iOS
flutter run -d android          # or -d ios, macos, windows

# Web
flutter run -d chrome --web-hostname localhost --web-port 8080

# Optional – run Firebase emulators
firebase emulators:start --only firestore,functions
```

### Hot reload / restart

- `r` → hot-reload UI
- `R` → full restart
- `q` → quit running session

---

## 6. Next Development Steps

| Priority | Task |
|----------|------|
| 🔧 P0 | Finish **Sandbox UI grid** (drag, resize, persist layout in Firestore) |
| 🔧 P0 | Implement first two modules (To-Do & Notes) with CRUD + offline cache |
| 🔧 P0 | Wire **openaiProxy** callable to UI (summaries, flash-cards) |
| 🔧 P1 | Add Google Play Billing & StoreKit2 flows (premium subscription) |
| 🔧 P1 | Unit & widget tests, integrate with `flutter_test` and CI |
| 🔧 P1 | Add web payment flow (Google Pay JS) |
| 🔧 P2 | Polish theming, icons, responsive layouts |
| 🔧 P2 | Write comprehensive documentation for each module |

Open issues and progress live in the GitHub **Projects → Roadmap** board.

---

## 7. Modular Sandbox UI Concept

SandboxNotion’s signature interface is a **snap-grid** canvas:

| Concept | Details |
|---------|---------|
| Grid | 8 px spacing, CSS-like fractional columns (`1fr 1fr …`) |
| Tile | Encapsulates a _module_ (Calendar, To-Do, Notes, Whiteboard, Cards) |
| Interactions | Drag & drop, pinch-to-resize, double-tap to maximise |
| Persistence | Layout saved per-device in localStorage and synced to Firestore for backup |
| Responsiveness | Breakpoints adapt grid columns; on mobile tiles stack vertically |
| Extensibility | New modules implement `SandboxModule` interface → automatically get drag/resizing & persistence |
| Accessibility | Keyboard drag (arrow keys + space) and screen-reader labels planned |

When coding a new module:

1. Create a `ModuleXWidget` implementing `SandboxModuleMixin`.
2. Provide `minSize`, `defaultSize`, and a Riverpod `Provider` for state.
3. Register in `modules_registry.dart`; it becomes instantly draggable.

---

### Need Help?

Ping `@maintainers` in the **#sandboxnotion-dev** Slack channel or open a GitHub Discussion.

Happy building! 🚀
