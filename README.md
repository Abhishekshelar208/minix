# Minix - AI-Powered Academic Project Mentor

> **A comprehensive Flutter application that guides engineering students through every stage of their academic projects — from intelligent topic selection to viva preparation with AI-powered assistance.**

**One-line pitch:** The complete academic project companion that transforms student stress into structured success through AI-powered guidance, automated documentation, and comprehensive project management.

---

## 🎯 The Problem We Solve

Engineering students face recurring challenges every semester:

- **Vague Topic Selection** → AI-generated ideas without real-world relevance
- **No Clear Roadmap** → Deadlines slip, tasks pile up, progress tracking fails
- **Copy-Paste Coding** → No real learning, errors not understood
- **Poor Team Coordination** → Lack of structured task division and accountability
- **Time-Consuming Documentation** → Hours spent on formatting instead of content
- **Viva Anxiety** → Last-minute preparation, no structured practice

**Result:** Stress, delays, poor learning outcomes, and subpar project quality.

## 🚀 Our Solution

Minix provides an **end-to-end, AI-powered academic project experience**:

- 🎲 **Smart Problem Discovery** → Real-world problems based on domain, year, and skills
- 🗺️ **Intelligent Roadmaps** → Personalized task breakdowns with progress tracking
- 💻 **Guided Code Generation** → Learn-by-doing approach with step-by-step AI assistance
- 👥 **Team Collaboration** → Structured task division and real-time progress updates
- 📄 **Automated Documentation** → Professional reports, presentations, and college-format compliance
- 🎤 **AI-Powered Viva Prep** → Dynamic question generation, mock simulations, and performance analytics

---

## 📊 Project Status Overview

### **Current Progress: ~85% Complete** 🎉

Minix has evolved into a **production-ready academic project management platform** with advanced AI integration and comprehensive feature set.

---

## ✅ **FULLY IMPLEMENTED FEATURES**

### **🔐 Authentication & Core Infrastructure**
- ✅ **Professional splash screen** with animated branding and auth verification
- ✅ **Interactive intro flow** with 3 value proposition slides
- ✅ **Cross-platform Google Sign-In** (Android, iOS, Web)
- ✅ **Firebase Realtime Database** integration with user bootstrapping
- ✅ **Responsive home dashboard** with profile, statistics, and project overview

### **📋 Project Management & Workflow**
- ✅ **Project Space Creation** with comprehensive team setup and platform selection
- ✅ **9-Step Guided Workflow** with intelligent progress tracking
- ✅ **AI-Powered Topic Selection** using Gemini API across 8+ domains
- ✅ **Real-World Problem Library** with 200+ curated problems
- ✅ **Smart Project Naming** with AI-generated suggestions
- ✅ **Solution Design Interface** with technology stack recommendations
- ✅ **Student-Friendly Roadmaps** with 12-18 achievable tasks

### **🤖 Advanced AI Integration**
- ✅ **Multi-Domain Problem Generation** (College, Hospital, E-commerce, Finance, etc.)
- ✅ **Contextual Solution Suggestions** with detailed implementation guidance
- ✅ **Technology Stack Recommendations** based on project requirements
- ✅ **Intelligent Content Generation** for documentation and presentations
- ✅ **Dynamic Viva Question Creation** tailored to specific projects

### **📄 Professional Documentation System** (Recently Enhanced)
- ✅ **4 College-Format Templates** (Academic Report, Professional Presentation, Project Synopsis, User Manual)
- ✅ **Advanced Citation Management** with APA, IEEE, MLA support
- ✅ **Automated Bibliography Generation** with 100+ pre-built tech citations
- ✅ **Rich Text Editor** with Quill integration
- ✅ **PDF/Word Export** with professional formatting
- ✅ **Document Versioning** and history tracking
- ✅ **Template Customization** for college-specific requirements

### **🎨 Presentation Generation System**
- ✅ **4 Professional PPT Templates** (Academic Standard, Professional Clean, Technical Detailed, Minimal Simple)
- ✅ **Automated Content Population** from project data
- ✅ **11 Slide Types** with smart data integration
- ✅ **Custom Template Upload** for college formats
- ✅ **PDF Export** with high-quality output
- ✅ **Template Customization** with real-time preview

### **🎤 Comprehensive Viva Preparation**
- ✅ **AI-Generated Question Bank** with 10 categories (Technical, Conceptual, Implementation, etc.)
- ✅ **Interactive Practice Sessions** with hint system
- ✅ **Mock Viva Simulations** with real-time timer and scoring
- ✅ **Performance Analytics** with detailed feedback
- ✅ **Presentation Guidelines** across 10 professional categories
- ✅ **Common Mistakes Guide** and preparation checklist

---

## 🚧 **IN PROGRESS FEATURES**

### **💻 Code Generation System** (~70% Complete)
- 🚧 **7-Step Code Generation** workflow with AI guidance
- 🚧 **Multi-Platform Support** (Flutter, Web, Desktop, Generic)
- 🚧 **Learning vs Direct Modes** for different skill levels
- 🚧 **Platform-Specific Modules** and code templates
- 🚧 **Step-by-Step Prompts** for educational guidance
- **Status:** Core architecture complete, platform implementations in progress

---

## ⏳ **PLANNED FEATURES**

### **👥 Team Collaboration** (Next Major Release)
- ⏳ Real-time task assignment and progress tracking
- ⏳ Team communication and file sharing
- ⏳ Role-based permissions and access control
- ⏳ Collaborative document editing

### **🔔 Smart Notifications & Reminders**
- ⏳ Deadline tracking and alerts
- ⏳ Progress milestone notifications
- ⏳ Team activity updates
- ⏳ Viva preparation reminders

### **📊 Advanced Analytics**
- ⏳ Project progress insights
- ⏳ Team performance metrics
- ⏳ Learning outcome tracking
- ⏳ Success rate analytics

---

## 🔄 Complete App Flow

### **Authentication Flow**
```
Splash Screen → Auth Check → {
  ✅ Logged In → Home Dashboard
  ❌ Not Logged In → Intro Slides → Google Sign-In → User Bootstrap → Home Dashboard
}
```

### **9-Step Project Workflow** (Production Ready)

| Step | Feature | Status | Implementation |
|------|---------|--------|-----------------|
| **1** | **Topic Selection** | ✅ Complete | AI-powered problem generation across 8 domains with detailed problem library |
| **2** | **Project Naming** | ✅ Complete | AI-generated name suggestions with context awareness |
| **3** | **Solution Design** | ✅ Complete | Technology stack selection with implementation guidance |
| **4** | **Roadmap Creation** | ✅ Complete | Student-friendly task breakdown (12-18 achievable milestones) |
| **5** | **Code Generation** | 🚧 In Progress | Multi-platform code generation with learning modes (70% complete) |
| **6** | **Documentation** | ✅ Complete | Professional documentation with 4 college-format templates |
| **7** | **PPT Generation** | ✅ Complete | Automated presentation creation with 4 professional templates |
| **8** | **Testing & QA** | 🚧 Integrated | Part of code generation workflow |
| **9** | **Viva Preparation** | ✅ Complete | AI-powered question bank, mock simulations, and performance analytics |

### **User Journey Examples**

**New User Experience:**
1. Opens app → Animated splash screen
2. Views intro slides explaining Minix value proposition
3. Signs in with Google (seamless cross-platform)
4. Completes user profile setup
5. Lands on personalized dashboard
6. Creates first project space
7. Follows 9-step guided workflow

**Returning User Experience:**
1. Opens app → Quick auth verification
2. Lands on dashboard with project progress
3. Continues from last completed step
4. Accesses generated documents and presentations
5. Reviews viva preparation materials

---

## ⚡ Technical Architecture
### **Frontend Technology**
- **Flutter 3.8.1+** with Dart for cross-platform development
- **Material 3 Design System** with adaptive theming (dark/light modes)
- **Google Fonts** for professional typography
- **Lottie Animations** for engaging user interactions
- **Responsive Design** optimized for mobile, tablet, and desktop

### **Backend & AI Services**
- **Firebase Realtime Database** for real-time data synchronization
- **Firebase Authentication** with Google Sign-In integration
- **Google Generative AI (Gemini 2.0)** for intelligent content generation
- **REST API Integration** for external service communication

### **Advanced Dependencies**
```yaml
# Core Firebase & Authentication
firebase_core: ^4.1.1
firebase_auth: ^6.1.0
firebase_database: ^12.0.2
google_sign_in: ^7.2.0

# AI & Content Generation
google_generative_ai: ^0.4.4
http: ^1.2.2

# Professional Document Generation
syncfusion_flutter_pdf: ^28.1.33
flutter_quill: ^11.4.2
flutter_html: ^3.0.0
pdf: ^3.11.1
printing: ^5.13.2

# UI & User Experience
google_fonts: ^6.1.0
lottie: ^3.1.0
url_launcher: ^6.2.5

# File Management & Export
file_picker: ^8.1.2
path_provider: ^2.1.4
share_plus: ^10.0.2
open_file: ^3.5.7

# Utilities
uuid: ^4.5.1
archive: ^4.0.2
xml: ^6.5.0
```

---

## 📁 Project Architecture

### **Clean Architecture Implementation**
```
lib/
├── main.dart                           # App entry point & Firebase initialization
├── firebase_options.dart               # Firebase configuration
├── config/
│   └── secrets.dart                    # API keys & configuration
├── models/                             # Data Models
│   ├── problem.dart                    # Problem domain models
│   ├── solution.dart                   # Solution & tech stack models
│   ├── project_roadmap.dart            # Task & roadmap models
│   ├── code_generation.dart            # Code generation models
│   ├── citation.dart                   # Citation & bibliography models
│   ├── document_template.dart          # Document template models
│   ├── ppt_generation.dart             # Presentation models
│   ├── viva_question.dart              # Viva preparation models
│   ├── mock_viva_session.dart          # Mock simulation models
│   └── presentation_tip.dart           # Presentation guidance models
├── services/                           # Business Logic Layer
│   ├── gemini_problems_service.dart    # AI problem generation
│   ├── project_service.dart            # Project management
│   ├── solution_service.dart           # Solution management
│   ├── code_generation_service.dart    # Code generation engine
│   ├── documentation_service.dart      # Document generation
│   ├── ppt_generation_service.dart     # Presentation creation
│   ├── viva_service.dart               # Viva preparation
│   ├── citation_service.dart           # Citation management
│   ├── template_service.dart           # Template management
│   ├── export_service.dart             # File export utilities
│   └── splash_services.dart            # App initialization
├── pages/                              # User Interface Layer
│   ├── splash_screen.dart              # App launch & auth verification
│   ├── login_signup_screen.dart        # Authentication flow
│   ├── home_screen.dart                # Main dashboard
│   ├── project_space_creation_page.dart # Project initialization
│   ├── project_steps_page.dart         # Workflow navigation
│   ├── topic_selection_page.dart       # AI-powered topic selection
│   ├── project_solution_page.dart      # Solution design interface
│   ├── solution_details_page.dart      # Detailed solution view
│   ├── project_roadmap_page.dart       # Roadmap visualization
│   ├── code_generation_page.dart       # Code generation interface
│   ├── enhanced_documentation_page.dart # Documentation system
│   ├── ppt_generation_page.dart        # Presentation creation
│   ├── viva_preparation_page.dart      # Viva preparation hub
│   └── mock_viva_session_page.dart     # Mock viva simulations
├── utils/
│   └── theme_helper.dart               # App theming utilities
└── assets/
    ├── images/                         # App imagery
    ├── animations/                     # Lottie animations
    └── icons/                          # Custom icons
```

### **Key Architectural Decisions**

- **🏠 Clean Architecture:** Separation of concerns with distinct layers
- **🔄 Service-Based Design:** Modular services for each feature domain
- **🗺️ State Management:** Firebase Realtime Database for reactive state
- **🎨 Material 3 Design:** Consistent, accessible, and modern UI
- **🤖 AI-First Approach:** Gemini AI integration throughout the workflow
- **📄 Document-Centric:** Professional document and presentation generation
- **📱 Cross-Platform:** Single codebase for Android, iOS, and Web

---

## 🚀 Quick Start Guide

### **Prerequisites**
- **Flutter SDK 3.8.1+** with Dart support
- **Android Studio/Xcode** with platform-specific SDKs
- **Firebase Project** with Google Sign-In enabled
- **Google AI Studio API Key** for Gemini integration
- **Git** for version control

### **1️⃣ Installation**

**Clone and Setup:**
```bash
# Clone the repository
git clone <your-repo-url>
cd minix

# Install Flutter dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### **2️⃣ Firebase Configuration**

**Android Setup:**
```bash
# Place your google-services.json file at:
# android/app/google-services.json
```

**iOS Setup:**
```bash
# Add GoogleService-Info.plist to:
# ios/Runner/GoogleService-Info.plist
# Ensure URL Schemes include REVERSED_CLIENT_ID
```

**Firebase Security Rules:**
```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "projects": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

### **3️⃣ API Configuration**

**Gemini AI Setup:**
1. Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create `lib/config/secrets.dart`:

```dart
class Secrets {
  static const String geminiApiKey = 'your-gemini-api-key-here';
}
```

**Alternative (Command Line):**
```bash
flutter run --dart-define=GEMINI_API_KEY=your-api-key-here
```

### **4️⃣ Platform-Specific Setup**

**Android Configuration:**
- **Minimum SDK:** 23 (pre-configured)
- **NDK Version:** 27.0.12077973 (pre-configured)
- **Install NDK:** Android Studio → SDK Tools → NDK (Side by side)

**iOS Configuration:**
```bash
# Install CocoaPods (one time)
brew install cocoapods

# Setup iOS dependencies
cd ios
pod repo update
pod install
cd ..
```

### **5️⃣ Launch Application**

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web (optional)
flutter run -d chrome

# Release builds
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

---

## 🛠️ Development Guide

### **Authentication System**
- **Mobile (Android/iOS):** `FirebaseAuth.signInWithProvider(GoogleAuthProvider())`
- **Web:** `FirebaseAuth.signInWithPopup(GoogleAuthProvider())`
- **User Storage:** Firebase Realtime Database with automatic bootstrapping
- **Security:** No pre-login data collection, privacy-first approach

### **AI Integration Patterns**
```dart
// Example Gemini API integration
final model = GenerativeModel(
  model: 'gemini-2.0-flash-exp',
  apiKey: Secrets.geminiApiKey,
  generationConfig: GenerationConfig(temperature: 0.7),
);

final response = await model.generateContent([
  Content.text('Generate project ideas for: $domain')
]);
```

### **State Management**
- **Firebase Realtime Database** for reactive state management
- **StreamBuilder** patterns for real-time UI updates
- **Service-based architecture** for business logic separation

### **Troubleshooting Common Issues**

**Pigeon Type Errors:**
```bash
# Clean and reinstall iOS dependencies
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

**Android Build Issues:**
```bash
# Verify Java version (JDK 17 required)
echo $JAVA_HOME

# Clean and rebuild
flutter clean
flutter pub get
flutter build apk
```

**Gradle Version Conflicts:**
```bash
# Point to correct JDK
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

---

## 🗺️ Development Roadmap

### **🏁 Current Sprint: Code Generation Completion**
**Target:** Complete the multi-platform code generation system

| Priority | Feature | Status | Timeline |
|----------|---------|--------|----------|
| **P0** | **Flutter Code Generation** | 🚧 70% | 2 weeks |
| **P0** | **Web Code Generation** | ⏳ Planned | 3 weeks |
| **P0** | **Desktop Code Generation** | ⏳ Planned | 4 weeks |
| **P1** | **Learning Mode Implementation** | ⏳ Planned | 2 weeks |
| **P1** | **Code Testing & QA Integration** | ⏳ Planned | 1 week |

### **🚀 Next Major Release: v2.0 (Team Collaboration)**
**Theme:** Multi-user project collaboration and real-time synchronization

- ⏳ **Real-time Team Collaboration** with role-based permissions
- ⏳ **Task Assignment & Progress Tracking** across team members
- ⏳ **In-app Communication** with comments and notifications
- ⏳ **Collaborative Document Editing** with version control
- ⏳ **Team Analytics Dashboard** with contribution insights

### **🔔 Future Enhancements: v3.0 (Smart Automation)**
**Theme:** Advanced AI automation and intelligent assistance

- ⏳ **Smart Notifications & Reminders** with ML-powered scheduling
- ⏳ **Advanced Analytics & Insights** with predictive project success
- ⏳ **Deep Links & Shareable Projects** for portfolio creation
- ⏳ **Offline-First Architecture** with intelligent sync
- ⏳ **Voice Interaction** for hands-free project management
- ⏳ **AR/VR Presentation Mode** for immersive project demos

---

## 📊 Current Achievement Summary

### **🎆 Major Milestones Completed**

- ✅ **Complete Authentication System** with cross-platform Google Sign-In
- ✅ **AI-Powered Problem Discovery** across 8+ professional domains
- ✅ **Intelligent Project Workflow** with 9-step guided process
- ✅ **Professional Documentation System** with college-format templates
- ✅ **Advanced Presentation Generation** with 4 template varieties
- ✅ **Comprehensive Viva Preparation** with mock simulations
- ✅ **Rich Text Editing & Export** with PDF/Word capabilities
- ✅ **Citation Management** with multiple academic formats

### **📈 Key Performance Indicators**

| Metric | Value | Status |
|--------|-------|--------|
| **Features Implemented** | 7/9 Core Features | 🟢 85% Complete |
| **Code Quality** | 0 Critical Issues | 🟢 Production Ready |
| **Platform Support** | 3 Platforms (Android/iOS/Web) | 🟢 Cross-Platform |
| **AI Integration** | Gemini 2.0 Flash | 🟢 Latest AI Technology |
| **Document Templates** | 8 Professional Templates | 🟢 College-Ready |
| **Test Coverage** | Manual Testing Complete | 🟡 Needs Automation |

---

## 🤝 Contributing to Minix

### **🌟 How to Contribute**

1. **Fork the repository** and create your feature branch
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

2. **Follow our coding standards:**
   - Use **meaningful commit messages** with conventional commits format
   - Include **comprehensive documentation** for new features
   - Add **screenshots/videos** for UI changes
   - Ensure **cross-platform compatibility**

3. **Submit a Pull Request** with:
   - Clear description of changes
   - Screenshots of new UI features
   - Testing instructions
   - Reference to related issues

### **📝 Development Guidelines**

- **Code Style:** Follow Flutter/Dart official style guide
- **Architecture:** Maintain clean architecture separation
- **Testing:** Add unit tests for business logic
- **Documentation:** Update README for significant changes
- **AI Integration:** Use consistent Gemini API patterns

### **🎁 Areas Seeking Contributors**

- 💻 **Code Generation Enhancement** - Platform-specific implementations
- 📈 **Analytics Dashboard** - User insights and progress tracking
- 🔔 **Notification System** - Smart reminders and alerts
- 🎨 **UI/UX Improvements** - Design system enhancements
- 🤖 **AI Features** - Advanced Gemini API integrations
- 📱 **Mobile Optimization** - Performance and responsiveness

---

## 📋 License & Acknowledgments

### **License**
This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### **Acknowledgments**
- **Google AI** for Gemini API integration
- **Firebase** for backend infrastructure
- **Flutter Team** for cross-platform framework
- **Syncfusion** for professional document generation
- **Engineering Students** worldwide for inspiration and feedback

### **Special Thanks**
To all engineering students who struggle with project management - this is for you! 🎓✨

---

## 📞 Contact & Support

- **Issues:** [GitHub Issues](https://github.com/your-repo/minix/issues)
- **Discussions:** [GitHub Discussions](https://github.com/your-repo/minix/discussions)
- **Email:** [your-email@domain.com](mailto:your-email@domain.com)
- **Documentation:** [Wiki](https://github.com/your-repo/minix/wiki)

---

<div align="center">

### **🎆 Minix: Transforming Academic Projects with AI 🎆**

*Built with ❤️ by students, for students*

**[Star ⭐](https://github.com/your-repo/minix) | [Fork 🍴](https://github.com/your-repo/minix/fork) | [Contribute 🤝](https://github.com/your-repo/minix/blob/main/CONTRIBUTING.md)**

</div>
