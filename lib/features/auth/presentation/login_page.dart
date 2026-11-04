import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/ekran_sigdir.dart';
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
  final _emailController = TextEditingController();
  final _authService = AuthService();
  final _siteService = SiteService();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _forgotMode = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Kutu dolunca temizleme dugmesi beliriyor, bosalinca kayboluyor.
    _usernameController.addListener(_yaziDegisti);
    _passwordController.addListener(_yaziDegisti);
  }

  void _yaziDegisti() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _usernameController
      ..removeListener(_yaziDegisti)
      ..dispose();
    _passwordController
      ..removeListener(_yaziDegisti)
      ..dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Kutunun sagindaki temizleme dugmesi. Kutu bosken yer kaplamiyor.
  Widget? _temizleDugmesi(
    AppColors c,
    TextEditingController denetleyici, {
    Widget? digerDugme,
  }) {
    final dolu = denetleyici.text.isNotEmpty;
    if (!dolu && digerDugme == null) return null;
    if (!dolu) return digerDugme;

    final temizle = IconButton(
      tooltip: 'Temizle',
      onPressed: _isLoading
          ? null
          : () {
              denetleyici.clear();
              _hatayiTemizle('');
            },
      icon: Icon(LucideIcons.circleX, size: 20, color: c.muted),
    );

    if (digerDugme == null) return temizle;
    // Once goz, sonra temizle: parolada temizle dugmesi disa bakiyor.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [digerDugme, temizle],
    );
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

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'E-posta adresi zorunludur.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final message = await _authService.forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _successMessage = message);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Kullanici yazmaya baslayinca eski hata mesaji kalkiyor.
  void _hatayiTemizle(String _) {
    if (_errorMessage != null || _successMessage != null) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      // Kutulardan birinin disina dokununca klavye kapaniyor; eskiden
      // yalnizca klavyedeki tik kapatiyordu.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            // Genis ekranda form tek sutuna sikisip ortalaniyor; aksi
            // halde kullanici adi kutusu 1900 piksel genisliginde
            // uzuyordu.
            child: EkranSigdir(
              enBoy: kFormEniMax,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 44).clamp(
                    0.0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Center(child: BrandLogo(height: 74)),
                    const SizedBox(height: 34),
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: c.border),
                        boxShadow: kartGolgesi(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_forgotMode) ...[
                            _Field(
                              label: 'Kullanıcı Adı',
                              child: TextField(
                                controller: _usernameController,
                                enabled: !_isLoading,
                                onChanged: _hatayiTemizle,
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(25),
                                ],
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 17,
                                  color: c.ink,
                                ),
                                cursorColor: c.accent,
                                decoration: _inputDecoration(c).copyWith(
                                  suffixIcon: _temizleDugmesi(
                                    c,
                                    _usernameController,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _Field(
                              label: 'Parola',
                              child: TextField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                onChanged: _hatayiTemizle,
                                obscureText: !_passwordVisible,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(25),
                                ],
                                onSubmitted: (_) {
                                  if (!_isLoading) _login();
                                },
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 17,
                                  color: c.ink,
                                ),
                                cursorColor: c.accent,
                                decoration: _inputDecoration(c).copyWith(
                                  suffixIcon: _temizleDugmesi(
                                    c,
                                    _passwordController,
                                    digerDugme: IconButton(
                                      tooltip: _passwordVisible
                                          ? 'Parolayı gizle'
                                          : 'Parolayı göster',
                                      onPressed: _isLoading
                                          ? null
                                          : () => setState(
                                              () => _passwordVisible =
                                                  !_passwordVisible,
                                            ),
                                      icon: Icon(
                                        _passwordVisible
                                            ? LucideIcons.eyeOff
                                            : LucideIcons.eye,
                                        size: 20,
                                        color: c.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() {
                                          _forgotMode = true;
                                          _errorMessage = null;
                                          _successMessage = null;
                                        }),
                                child: const Text('Şifremi Unuttum'),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Kayıtlı e-posta adresinizi girin. Yeni geçici parolanız e-posta ile gönderilecektir.',
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 14.5,
                                height: 1.45,
                                color: c.sub,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _Field(
                              label: 'E-posta',
                              child: TextField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onChanged: _hatayiTemizle,
                                onSubmitted: (_) {
                                  if (!_isLoading) _forgotPassword();
                                },
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 17,
                                  color: c.ink,
                                ),
                                cursorColor: c.accent,
                                decoration: _inputDecoration(c),
                              ),
                            ),
                          ],
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                color: c.bad.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                          if (_successMessage != null) ...[
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                color: c.ok.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 14.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                  color: c.ok,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 26),
                          PrimaryButton(
                            label: _forgotMode ? 'YENİ PAROLA GÖNDER' : 'GİRİŞ',
                            busy: _isLoading,
                            onPressed: _isLoading
                                ? null
                                : (_forgotMode ? _forgotPassword : _login),
                          ),
                          if (_forgotMode) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(() {
                                        _forgotMode = false;
                                        _errorMessage = null;
                                        _successMessage = null;
                                      }),
                              child: const Text('Giriş ekranına dön'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      '© Copyright 2026 SefaTech tüm hakları saklıdır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 12.5,
                        color: c.faint,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
