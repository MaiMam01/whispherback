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

/// Snackbars and toasts that float just above the shell bottom navigation
/// bar.
///
/// Safe to call right after `context.pop()` — the snackbar is enqueued on the
/// root [ScaffoldMessenger] (not the local Scaffold) so it survives the route
/// transition, and its bottom margin is measured against the destination
/// (shell) context so it sits above the nav bar instead of behind it.
///
/// Styling: the snackbar uses a high-contrast dark background with WHITE
/// text, WHITE close icon, and WHITE action label so it stays legible in
/// both light and dark themes. The previous default theme left the close
/// icon and action label rendered in onSurface (dark) on a dark-backed
/// snackbar → user reported "CROSS ICON and OPEN SETTINGS button text is
/// black and hence not visible in dark theme".
extension ShellMessenger on BuildContext {
  void showShellSnackBar(
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(milliseconds: 2200),
    IconData? icon,
  }) {
    // Defer one frame so any in-flight pop completes first; otherwise the
    // bottom inset is measured against the dying route which has no nav bar,
    // and the snackbar ends up rendered behind the shell's floating bar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = rootMessengerKey.currentState;
      if (messenger == null) return;
      final ctx = _resolveMessengerContext(this);
      // Sit JUST above the floating nav bar — only the safe-area padding
      // plus a thin 4 px gap so the snackbar visually anchors to the
      // navigation bar instead of floating in the middle of the screen.
      // The previous +12 was visible as a fat empty gap on Samsung
      // devices and was the "notifications are coming too much on top
      // and distanced from the bottom navbar" QA complaint.
      final reserved =
          ShellMetrics.reservedBottomHeight(ctx, miniPlayerVisible: false);
      final bottom = reserved + 4;

      // Promote the action label to white so it stays legible on the
      // forced-dark snackbar background. Without this, on light theme
      // the action label would inherit the theme's onSurface (dark)
      // color and disappear against the dark snackbar fill.
      final styledAction = action == null
          ? null
          : SnackBarAction(
              label: action.label,
              textColor: Colors.white,
              onPressed: action.onPressed,
            );

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B1F2A),
            content: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(12, 0, 12, bottom),
            duration: duration,
            showCloseIcon: true,
            closeIconColor: Colors.white,
            action: styledAction,
          ),
        );
    });
  }
}
