// Stub implementations for google_sign_in used ONLY on the web.
// They satisfy the type checker but will never be called because the
// code that uses them is guarded with `if (!kIsWeb) {...}`.
// If the guard were bypassed, the methods simply return null.


/// Stub for the Android/iOS `GoogleSignIn` class.
class GoogleSignIn {
  const GoogleSignIn({List<String> scopes = const []});

  /// Returns `null` on web – the call is never reached.
  Future<GoogleSignInAccount?> signIn() async => null;

  /// Web stub for signOut.
  Future<void> signOut() async {}

  /// Web stub for disconnect.
  Future<void> disconnect() async {}
}

/// Stub for the account object returned by `GoogleSignIn.signIn()`.
class GoogleSignInAccount {
  const GoogleSignInAccount();

  /// Stub for the authentication data.
  Future<GoogleSignInAuthentication> get authentication async =>
      const GoogleSignInAuthentication();
}

/// Stub for the authentication token container.
class GoogleSignInAuthentication {
  const GoogleSignInAuthentication();

  // The real class provides `accessToken` and `idToken` strings.
  // Returning `null` is safe because the stub is never used.
  String? get accessToken => null;
  String? get idToken => null;
}
