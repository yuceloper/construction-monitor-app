import '../../site_selection/models/site_summary.dart';
import '../models/auth_response.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  AuthResponse? _auth;
  SiteSummary? _selectedSite;

  AuthResponse? get auth => _auth;
  String? get accessToken => _auth?.accessToken;
  String? get refreshToken => _auth?.refreshToken;
  bool get isAuthenticated => (_auth?.accessToken.isNotEmpty ?? false);

  SiteSummary? get selectedSite => _selectedSite;
  int? get selectedSiteId => _selectedSite?.id;
  String? get selectedSiteName => _selectedSite?.name;

  void setAuth(AuthResponse auth) {
    _auth = auth;
    _selectedSite = null;
  }

  void setSelectedSite(SiteSummary site) {
    _selectedSite = site;
  }

  void clear() {
    _auth = null;
    _selectedSite = null;
  }
}
