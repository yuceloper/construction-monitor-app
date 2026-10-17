import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../site_selection/models/site_summary.dart';
import '../models/auth_response.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  static const _authKey = 'auth_session';
  static const _siteKey = 'selected_site';
  static const _secureStorage = FlutterSecureStorage();

  AuthResponse? _auth;
  SiteSummary? _selectedSite;

  AuthResponse? get auth => _auth;
  String? get accessToken => _auth?.accessToken;
  String? get refreshToken => _auth?.refreshToken;
  bool get isAuthenticated => (_auth?.accessToken.isNotEmpty ?? false);
  int? get companyId => _auth?.companyId;
  String? get companyName => _auth?.companyName;

  SiteSummary? get selectedSite => _selectedSite;
  int? get selectedSiteId => _selectedSite?.id;
  String? get selectedSiteName => _selectedSite?.name;

  Future<void> restore() async {
    try {
      final authJson = await _read(_authKey);
      if (authJson == null || authJson.isEmpty) return;

      final decoded = jsonDecode(authJson);
      if (decoded is! Map<String, dynamic>) return;
      final auth = AuthResponse.fromJson(decoded);
      if (auth.accessToken.isEmpty || auth.refreshToken.isEmpty) return;
      _auth = auth;

      final siteJson = await _read(_siteKey);
      if (siteJson != null && siteJson.isNotEmpty) {
        final siteDecoded = jsonDecode(siteJson);
        if (siteDecoded is Map<String, dynamic>) {
          final site = SiteSummary.fromJson(siteDecoded);
          if (site.id > 0) _selectedSite = site;
        }
      }
    } catch (_) {
      _auth = null;
      _selectedSite = null;
      await _delete(_authKey);
      await _delete(_siteKey);
    }
  }

  Future<void> setAuth(AuthResponse auth) async {
    _auth = auth;
    await _write(_authKey, jsonEncode(auth.toJson()));
  }

  Future<void> setSelectedSite(SiteSummary site) async {
    _selectedSite = site;
    await _write(_siteKey, jsonEncode(site.toJson()));
  }

  Future<void> clear() async {
    _auth = null;
    _selectedSite = null;
    await _delete(_authKey);
    await _delete(_siteKey);
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    return _secureStorage.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    await _secureStorage.delete(key: key);
  }
}
