import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/ekran_sigdir.dart';
import '../../../core/widgets/panel.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({super.key});

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _authService = AuthService();

  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _error;

  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_password.text);
  bool get _hasDigit => RegExp(r'\d').hasMatch(_password.text);
  bool get _hasSpecial => RegExp(r'[^A-Za-z0-9]').hasMatch(_password.text);
  bool get _hasLength => _password.text.length >= 10;
  bool get _matches =>
      _password.text.isNotEmpty && _password.text == _confirm.text;

  bool get _policyOk =>
      _hasUpper &&
      _hasLower &&
      _hasDigit &&
      _hasSpecial &&
      _hasLength &&
      _matches;

  @override
  void initState() {
    super.initState();
    _password.addListener(_refresh);
    _confirm.addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      if (_error != null) _error = null;
    });
  }

  @override
  void dispose() {
    _password
      ..removeListener(_refresh)
      ..dispose();
    _confirm
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_policyOk) {
      setState(() => _error = 'Parola kurallarını eksiksiz karşılayın.');
      return;
    }

    final session = SessionManager.instance;
    final token = session.accessToken;
    final auth = session.auth;
    if (token == null || token.isEmpty || auth == null) {
      context.go('/login');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _authService.changePassword(
        accessToken: token,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      await session.setAuth(auth.copyWith(mustChangePassword: false));
      if (!mounted) return;
      context.go('/dashboard');
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
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
                            Text(
                              'Parolanızı Güncelleyin',
                              style: TextStyle(
                                fontFamily: kDisplay,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Güvenliğiniz için e-posta ile gönderilen geçici parolayı değiştirmeniz gerekiyor.',
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 14,
                                height: 1.45,
                                color: c.sub,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _PasswordField(
                              label: 'Yeni Parola',
                              controller: _password,
                              visible: _showPassword,
                              enabled: !_busy,
                              onToggle: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _PasswordField(
                              label: 'Yeni Parola Tekrar',
                              controller: _confirm,
                              visible: _showConfirm,
                              enabled: !_busy,
                              onToggle: () => setState(
                                () => _showConfirm = !_showConfirm,
                              ),
                              onSubmitted: (_) {
                                if (!_busy) _submit();
                              },
                            ),
                            const SizedBox(height: 18),
                            _PolicyRow(label: 'En az 10 karakter', ok: _hasLength),
                            _PolicyRow(label: 'En az 1 büyük harf', ok: _hasUpper),
                            _PolicyRow(label: 'En az 1 küçük harf', ok: _hasLower),
                            _PolicyRow(label: 'En az 1 rakam', ok: _hasDigit),
                            _PolicyRow(label: 'En az 1 özel karakter', ok: _hasSpecial),
                            _PolicyRow(label: 'Parolalar eşleşiyor', ok: _matches),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.bad.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    fontFamily: kBody,
                                    color: c.bad,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            PrimaryButton(
                              label: 'PAROLAYI GÜNCELLE',
                              busy: _busy,
                              onPressed: _busy ? null : _submit,
                            ),
                          ],
                        ),
                      ),
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
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.visible,
    required this.enabled,
    required this.onToggle,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final bool visible;
  final bool enabled;
  final VoidCallback onToggle;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: c.ink,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: !visible,
          textInputAction:
              onSubmitted == null ? TextInputAction.next : TextInputAction.done,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          onSubmitted: onSubmitted,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 17,
            color: c.ink,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: c.surface2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: border(c.border2),
            enabledBorder: border(c.border2),
            disabledBorder: border(c.border),
            focusedBorder: border(c.accent, 1.8),
            suffixIcon: IconButton(
              onPressed: enabled ? onToggle : null,
              icon: Icon(
                visible ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 20,
                color: c.muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            ok ? LucideIcons.circleCheck : LucideIcons.circle,
            size: 17,
            color: ok ? c.ok : c.faint,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: kBody,
              fontSize: 13.5,
              color: ok ? c.ink : c.muted,
            ),
          ),
        ],
      ),
    );
  }
}
