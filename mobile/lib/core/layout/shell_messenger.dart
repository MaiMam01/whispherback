import 'package:flutter/material.dart';

import 'responsive.dart';

/// Root [ScaffoldMessenger] key so snackbars survive route pops & sit above
/// the floating bottom navigation bar.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Resolves a context that's safe to read MediaQuery / layout from when
/// computing the snackbar's bottom margin. After a `context.pop()` the calling
/// context is unmounted, so we prefer the root messenger's context which sits
/// on the still-mounted MaterialApp.
BuildContext _resolveMessengerContext(BuildContext fallback) {
  final state = rootMessengerKey.currentState;
  final ctx = state?.context;
  if (ctx != null && ctx.mounted) return ctx;
  return fallback;
}

/// Snackbars and toasts that float above the shell bottom navigation bar.
///
/// Safe to call right after `context.pop()` — the snackbar is enqueued on the
/// root [ScaffoldMessenger] (not the local Scaffold) so it survives the route
/// transition, and its bottom margin is measured against the destination
/// (shell) context so it sits above the nav bar instead of behind it.
extension ShellMessenger on BuildContext {
  void showShellSnackBar(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    IconData? icon,
  }) {
    // Defer one frame so any in-flight pop completes first; otherwise the
    // bottom inset is measured against the dying route which has no nav bar,
    // and the snackbar ends up rendered behind the shell's floating bar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = rootMessengerKey.currentState;
      if (messenger == null) return;
      final ctx = _resolveMessengerContext(this);
      final bottom =
          ShellMetrics.reservedBottomHeight(ctx, miniPlayerVisible: false) + 12;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(message)),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(16, 0, 16, bottom),
            duration: duration,
            showCloseIcon: true,
            action: action,
          ),
        );
    });
  }
}
