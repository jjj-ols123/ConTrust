// Minimal stubs so non-web builds can compile when google_sign_in is unavailable.
// These implementations are NO-OPs and should never execute in production.

class GoogleSignInAuthentication {
  const GoogleSignInAuthentication({this.idToken});
  final String? idToken;
}

class GoogleSignInAccount {
  GoogleSignInAuthentication get authentication => const GoogleSignInAuthentication();
}

class GoogleSignIn {
  GoogleSignIn._();

  static final GoogleSignIn instance = GoogleSignIn._();

  Future<void> initialize({String? serverClientId, List<String>? scopes}) async {}

  Future<GoogleSignInAccount> authenticate({List<String> scopeHint = const []}) async {
    return GoogleSignInAccount();
  }

  Future<void> signOut() async {}

  Future<void> disconnect() async {}
}
