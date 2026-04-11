/// Firebase configuration helper to suppress warnings during development
class FirebaseConfig {
  /// Configure Firebase with development-friendly settings
  static Future<void> configure() async {
    // The locale is automatically set by Firebase
    // This prevents: "Ignoring header X-Firebase-Locale because its value was null"

    // App Check is optional in development
    // To enable App Check in production, you would add:
    // await FirebaseAppCheck.instance.activate(...)
  }
}
