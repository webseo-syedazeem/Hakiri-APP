import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Full-screen blocking loader — centered dialog only (no top banner).
class HakkiriLoadingOverlay {
  HakkiriLoadingOverlay._();

  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String message = 'Getting your information…',
    String detail = 'Hang tight — this can take a moment.',
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      useRootNavigator: true,
      builder: (_) => PopScope(
        canPop: false,
        child: _HakkiriLoadingDialog(
          message: message,
          detail: detail,
        ),
      ),
    );

    try {
      return await action();
    } finally {
      if (dialogOpen && navigator.canPop()) {
        dialogOpen = false;
        navigator.pop();
      }
    }
  }
}

class _HakkiriLoadingDialog extends StatelessWidget {
  const _HakkiriLoadingDialog({
    required this.message,
    required this.detail,
  });

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 280,
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.royalBlueSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: AppColors.royalBlue,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
