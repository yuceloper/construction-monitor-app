import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import 'empty_illustration.dart';
import 'panel.dart';
import 'pressable.dart';

/// Shown while a screen waits for the backend. Quiet on purpose - a centred
/// indicator and nothing else, because the wait is normally short.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: context.colors.ink,
        ),
      ),
    );
  }
}

/// Shown when a request fails. Always offers a way forward: the message says
/// what went wrong and the button retries without leaving the screen.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBox(icon: LucideIcons.cloudOff, color: c.bad, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 13.5,
                height: 1.5,
                color: c.sub,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A whole screen with nothing to list. Not an error: the request worked,
/// there is simply no content yet.
///
/// Says what is missing ([title]), why or what happens next ([message]) and,
/// where the user can do something about it, offers that one action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Blok dikeyde ortalanmiyor. Oranli hizalama kullanilsa icerik alaninin
    // yuksekligi her ekranda farkli oldugu icin isaret kimi ekranda ortada,
    // kimi ekranda yukarida kaliyordu; artik hepsinde ustten ayni uzaklikta.
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, kEmptyTopGap, 32, 32),
        child: FadeSlideIn(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const EmptyIllustration(),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: c.sub,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 13,
                      height: 1.55,
                      color: c.sub,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  SmallButton(
                    label: actionLabel!,
                    icon: actionIcon,
                    onTap: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste bosken gosterilen mesaj: EmptyView ile ayni blok, ustte durur ve
/// asagi cekince yenileme yine calisir.
class CenteredScrollMessage extends StatelessWidget {
  const CenteredScrollMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    // Icerik EmptyView ile ayni: ayni isaret, ayni hiza, ayni yazi bicimi.
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: EmptyView(title: message),
          ),
        ],
      ),
    );
  }
}
