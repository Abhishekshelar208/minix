# Minix

A complete mentor app that guides engineering students through every stage of their academic projects — from idea selection to viva preparation.

One-line pitch: A single app that helps students select real-world topics, plan, build, document, and present their projects with confidence.

---

## Problem
Engineering students repeatedly face the same hurdles each semester:
- Topic selection is vague and often AI-generated without real-world grounding.
- No clear roadmap or tracking — deadlines slip, tasks pile up.
- Coding is copy–paste; errors aren’t understood; learning suffers.
- Teams lack structured task division and accountability.
- Documentation/PPT formats consume time and reduce quality.
- Viva prep is an afterthought — students don’t know what to expect.

Result: stress, delays, and poor learning outcomes.

## Solution
Minix provides an end-to-end, structured experience:
- Real-world problem discovery based on domain, year, and skills.
- Personalized roadmaps with tasks, reminders, and progress tracking.
- Two coding modes: direct code or step-by-step prompts to encourage learning.
- Team collaboration: task division and status tracking.
- Automated PPT, report, and documentation generation (college format or default).
- Viva preparation tailored to the selected project.

---

## Current Implementation Status

### ✅ **COMPLETED FEATURES**
**Authentication & Core Flow:**
- Splash screen with branding and auth check
- Intro slides (3) describing value prop
- Google Sign-In (mobile + web support)
- User bootstrap in Firebase Realtime Database
- Home dashboard with profile, stats, and projects overview

**Project Management:**
- Project Space creation (team setup, platform selection)
- 7-step guided project workflow
- Topic selection with AI-powered problem generation (Gemini API)
- Real-world problem library with detailed information
- Project name suggestions
- Solution design and selection page
- Student-friendly roadmap generation (simplified for mini projects)
- Task management and progress tracking

**AI-Powered Features:**
- Problem generation across multiple domains (College, Hospital, E-commerce, etc.)
- Detailed problem descriptions with real-life examples
- Solution suggestions with tech stack recommendations
- Simplified roadmap generation (12-18 student-friendly tasks)
- Bookmark system for favorite problems

### 🚧 **IN PROGRESS / PARTIALLY IMPLEMENTED**
- Code generation service (basic structure ready)
- Project roadmap page with task visualization
- Solution details page (recently updated from bottom sheet to full page)

### ❌ **NOT YET IMPLEMENTED**
- Code generation modes (direct code vs step-by-step learning)
- PPT/Report generator with custom college formats
- Viva Q&A generator based on project
- Team collaboration features (task assignment, real-time updates)
- Notifications and reminders
- Documentation generation

---

## App Flow (Current Implementation)
**Main Flow:**
Splash → Auth check → If logged-in → Home → Create Project Space → 7-Step Project Workflow

If not logged-in → Intro slides → Continue with Google → Save user → Home

**7-Step Project Workflow:**
1. **Topic Selection** - AI-powered problem generation with domain filtering
2. **Name Selection** - Project name suggestions
3. **Solution Design** - Choose solution approach with tech stack
4. **Roadmap Generation** - Student-friendly task timeline (12-18 tasks)
5. **Code Generation** - [In Progress] Code generation with learning modes
6. **Documentation** - [Not Implemented] PPT/Report generation
7. **Viva Preparation** - [Not Implemented] AI Q&A practice

---

## Tech Stack
**Frontend:**
- Flutter 3.8.1+ (Dart)
- Material 3-inspired theming with dark/light mode support
- Google Fonts for typography
- Lottie for animations

**Backend & Services:**
- Firebase (Authentication, Realtime Database)
- Google Generative AI (Gemini API for problem/roadmap generation)
- Google Sign-In integration

**Key Dependencies:**
```yaml
firebase_core: ^4.1.1
firebase_auth: ^6.1.0
firebase_database: ^12.0.2
google_generative_ai: ^0.4.4
google_sign_in: ^7.2.0
google_fonts: ^6.1.0
http: ^1.2.2
lottie: ^3.3.1
```

---

## Project Structure
```
lib/
├── main.dart                     # App entry, theme, Firebase init
├── models/                       # Data models
│   ├── problem.dart             # Problem/topic data structure
│   ├── solution.dart            # Project solution models
│   ├── task.dart                # Task/roadmap task models
│   └── project_roadmap.dart     # Roadmap data structure
├── pages/                        # UI screens
│   ├── splash_screen.dart       # Animated splash + auth check
│   ├── login_signup_screen.dart # Intro slides + Google Sign-In
│   ├── home_screen.dart         # Main dashboard
│   ├── project_space_creation_page.dart # Team setup
│   ├── project_steps_page.dart  # 7-step workflow navigation
│   ├── topic_selection_page.dart # AI problem generation
│   ├── project_solution_page.dart # Solution design
│   ├── solution_details_page.dart # Detailed solution view
│   ├── project_roadmap_page.dart # Roadmap visualization
│   └── code_generation_page.dart # Code generation [WIP]
├── services/                     # Business logic
│   ├── gemini_problems_service.dart # AI problem/roadmap generation
│   ├── project_service.dart     # Firebase project operations
│   ├── solution_service.dart    # Solution management
│   └── code_generation_service.dart # Code generation [WIP]
└── assets/                       # Images, animations, icons
```

---

## Setup & Run
**Prerequisites:**
- Flutter SDK 3.8.1+
- Android Studio/Xcode with platform SDKs
- Firebase project with Google Sign-In enabled
- Google AI Studio API key (for Gemini API)

**1) Install dependencies**
```bash
flutter pub get
```

**2) Configure Firebase**
- Android: place `google-services.json` at `android/app/google-services.json`
- iOS: add `GoogleService-Info.plist` to `ios/Runner`; ensure URL Schemes include REVERSED_CLIENT_ID

**3) Configure Gemini API**
- Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
- Add to `lib/config/secrets.dart`:
```dart
class Secrets {
  static const String geminiApiKey = 'your-gemini-api-key-here';
}
```
- Or pass via command line: `flutter run --dart-define=GEMINI_API_KEY=your-key`

3) Android build configuration
- Minimum SDK is 23 (required by Firebase plugins)
- NDK version pinned to match plugins (27.0.12077973)
Already set in:
```gradle path=null start=null
// /android/app/build.gradle.kts
android {
  defaultConfig {
    minSdk = 23
  }
  ndkVersion = "27.0.12077973"
}
```
Ensure NDK is installed via Android Studio (SDK Tools → NDK (Side by side)).

4) iOS (optional)
Install CocoaPods once:
```bash path=null start=null
brew install cocoapods
```
Then in the project root:
```bash path=null start=null
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod repo update && pod install
```

5) Run the app
```bash path=null start=null
flutter run -d android    # Android emulator/device
flutter run -d ios        # iOS simulator/device
flutter run -d chrome     # Web (optional)
```

---

## Authentication Details
- Mobile (Android/iOS): FirebaseAuth.signInWithProvider(GoogleAuthProvider())
  - Avoids Pigeon layers in google_sign_in and their version-mismatch issues.
- Web: FirebaseAuth.signInWithPopup(GoogleAuthProvider())
- User record stored in Realtime Database only if new (fields: Name, EmailID, PhotoURL, Provider, JoinDate).
- No pre-login user detail collection (name/college removed as requested).

---

## Development Notes
- If you see Pigeon type errors (e.g., List<Object?> cast to PigeonUserDetails), ensure you’re using signInWithProvider on mobile and have cleaned/reinstalled pods when updating Google Sign-In versions.
- If Android build complains about minSdk or NDK, verify the settings shown above and that the NDK version is installed.
- If Gradle shows "Unsupported class file major version 68", point JAVA_HOME to JDK 17 and rebuild.

---

## Roadmap (Next Milestones)

**Phase 1: Core Features Completion**
1. ✅ Topic selection and AI problem generation (DONE)
2. ✅ Student-friendly roadmap generation (DONE)
3. 🚧 Code generation with learning modes (IN PROGRESS)
4. ⏳ Team collaboration features (task assignment, real-time updates)

**Phase 2: Advanced Features**
5. ⏳ PPT/Report generator (college-format aware)
6. ⏳ Viva preparation with dynamic Q&A
7. ⏳ Notifications and reminders system
8. ⏳ Documentation auto-generation

**Phase 3: Enhancement Features**
9. ⏳ Deep links and shareable project pages
10. ⏳ Offline support and caching
11. ⏳ Advanced analytics and progress insights

---

## Status Snapshot (Updated)
- ✅ **Core navigation/auth:** DONE
- ✅ **Database bootstrap (user):** DONE
- ✅ **Dashboard UI:** DONE (with real project data)
- ✅ **Project Space creation:** DONE
- ✅ **Topic selection:** DONE (AI-powered with Gemini)
- ✅ **Problem generation:** DONE (8 domains, detailed info)
- ✅ **Solution design:** DONE (tech stack selection)
- ✅ **Roadmap generation:** DONE (student-friendly, 12-18 tasks)
- 🚧 **Code generation:** IN PROGRESS (basic structure ready)
- ⏳ **Documentation/PPT generation:** TODO
- ⏳ **Viva preparation:** TODO
- ⏳ **Team collaboration:** TODO (task assignment, real-time updates)

---

## Contributing
- Fork, create a feature branch, and open a PR.
- Keep commits focused; include screenshots or short videos for UX changes.

## License
- TBD (add a license of your choice if needed).
# minix
