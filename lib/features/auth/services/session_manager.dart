import '../models/auth_response.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  AuthResponse? _auth;

  AuthResponse? get auth => _auth;
  String? get accessToken => _auth?.accessToken;
  String? get refreshToken => _auth?.refreshToken;
  bool get isAuthenticated => (_auth?.accessToken.isNotEmpty ?? false);

  void setAuth(AuthResponse auth) {
    _auth = auth;
  }

  void clear() {
    _auth = null;
  }
}
