// Minimal web stub matching google_sign_in v7.x API surface used in the app.
// NO-OP implementations; runtime web code paths should not call these.

class GoogleSignInAuthentication {
  const GoogleSignInAuthentication({this.idToken});
  final String? idToken;
}

class GoogleSignInAccount {
  Future<GoogleSignInAuthentication> get authentication async =>
      const GoogleSignInAuthentication();
}

class GoogleSignIn {
  GoogleSignIn._();

  static final GoogleSignIn instance = GoogleSignIn._();

  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {}

  Future<GoogleSignInAccount> authenticate({List<String>? scopes}) async =>
      GoogleSignInAccount();

  Future<void> signOut() async {}

  Future<void> disconnect() async {}
}
