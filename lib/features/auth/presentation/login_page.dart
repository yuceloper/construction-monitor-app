import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/brand.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/panel.dart';
import '../../site_selection/services/site_service.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _siteService = SiteService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Kullanıcı adı ve parola zorunludur.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = await _authService.login(
        username: username,
        password: password,
      );
      SessionManager.instance.setAuth(auth);

      final sites = await _siteService.getSites();
      if (!mounted) return;

      if (sites.isEmpty) {
        SessionManager.instance.clear();
        setState(() {
          _errorMessage = 'Bu kullanıcıya atanmış şantiye bulunmuyor.';
        });
        return;
      }

      if (sites.length == 1) {
        SessionManager.instance.setSelectedSite(sites.first);
        context.go('/dashboard');
        return;
      }

      context.go('/sites');
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on SiteException catch (error) {
      if (!mounted) return;
      SessionManager.instance.clear();
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Center(child: BrandLogo(height: 74)),
                  const SizedBox(height: 14),
                  Text(
                    'Şantiye Takip Uygulaması',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: c.sub,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: c.border),
                      boxShadow: kLiftShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Field(
                          label: 'Kullanıcı Adı',
                          child: TextField(
                            controller: _usernameController,
                            enabled: !_isLoading,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [LengthLimitingTextInputFormatter(50)],
                            style: TextStyle(fontFamily: kBody, fontSize: 17, color: c.ink),
                            cursorColor: c.accent,
                            decoration: _inputDecoration(c),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _Field(
                          label: 'Parola',
                          child: TextField(
                            controller: _passwordController,
                            enabled: !_isLoading,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [LengthLimitingTextInputFormatter(25)],
                            onSubmitted: (_) {
                              if (!_isLoading) _login();
                            },
                            style: TextStyle(fontFamily: kBody, fontSize: 17, color: c.ink),
                            cursorColor: c.accent,
                            decoration: _inputDecoration(c),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: c.bad.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(LucideIcons.circleAlert, size: 18, color: c.bad),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      fontFamily: kBody,
                                      fontSize: 14.5,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                      color: c.bad,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 26),
                        PrimaryButton(
                          label: 'GİRİŞ',
                          busy: _isLoading,
                          onPressed: _isLoading ? null : _login,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  ValueListenableBuilder<BrandConfig>(
                    valueListenable: Brand.config,
                    builder: (context, brand, _) => Text(
                      '© Copyright 2026 ${brand.name} tüm hakları saklıdır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: kBody, fontSize: 12.5, color: c.faint),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(AppColors c) {
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      isDense: true,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      filled: true,
      fillColor: c.surface2,
      border: border(c.border2),
      enabledBorder: border(c.border2),
      disabledBorder: border(c.border),
      focusedBorder: border(c.accent, 1.8),
    );
  }
}

/// Alan basligi kutunun ustunde - dar ekranda da kirilmiyor, uzun etiketler
/// alani daraltmiyor.
class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: .2,
            color: context.colors.ink,
          ),
        ),
        const SizedBox(height: 9),
        child,
      ],
    );
  }
}
