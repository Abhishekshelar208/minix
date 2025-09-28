// class Secrets {
//   // Prefer --dart-define; do NOT hardcode secrets in code.
//   // Pass at runtime: flutter run --dart-define=GEMINI_API_KEY=...
//   static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyCQktw7dH6hdRn0PMF1xd2vg238yh9KgPU');
//   static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
// }

class Secrets {
  // Prefer --dart-define; do NOT hardcode secrets in code.
  // Pass at runtime: flutter run --dart-define=GEMINI_API_KEY=...
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: 'AIzaSyCoFgpZdBBZtjPnfn-sUzs2k8yqt3Ey6wQ');
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
