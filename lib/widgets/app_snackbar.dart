import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum SnackBarType { info, success, error }

/// Unified, modern floating snackbar for Hakkiri.
/// Replaces the default black rectangular bar with a clean, rounded,
/// floating white card with soft shadows, an icon badge, and crisp typography.
class AppSnackBar {
  AppSnackBar._();

  /// Show a floating snackbar with an icon and optional action.
  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(milliseconds: 2400),
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    // Clear previous snackbars immediately so there is zero queue delay.
    messenger.clearSnackBars();

    final iconData = icon ?? _defaultIcon(type);
    final iconColor = _iconColor(type);
    final iconBgColor = _iconBgColor(type);
    final borderColor = _borderColor(type);

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(iconData, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.royalBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Convenience helper for success notifications.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    show(
      context,
      message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(milliseconds: 2400),
      icon: icon,
    );
  }

  /// Convenience helper for errors and warnings.
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    show(
      context,
      message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(milliseconds: 3000),
      icon: icon,
    );
  }

  /// Convenience helper for informational toasts.
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    IconData? icon,
  }) {
    show(
      context,
      message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(milliseconds: 2400),
      icon: icon,
    );
  }

  static IconData _defaultIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_outline_rounded;
      case SnackBarType.info:
        return Icons.info_outline_rounded;
    }
  }

  static Color _iconColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF10B981);
      case SnackBarType.error:
        return AppColors.coralRed;
      case SnackBarType.info:
        return AppColors.royalBlue;
    }
  }

  static Color _iconBgColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFFECFDF5);
      case SnackBarType.error:
        return const Color(0xFFFEF2F2);
      case SnackBarType.info:
        return const Color(0xFFEFF6FF);
    }
  }

  static Color _borderColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF10B981).withValues(alpha: 0.25);
      case SnackBarType.error:
        return AppColors.coralRed.withValues(alpha: 0.25);
      case SnackBarType.info:
        return const Color(0xFFE2E8F0);
    }
  }
}
