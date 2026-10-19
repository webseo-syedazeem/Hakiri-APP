import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ActionPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final bool isDark;
  final bool showArrow;
  final bool isSecondary;
  final bool isEnabled;

  const ActionPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onTap,
    this.isDark = true,
    this.showArrow = true,
    this.isSecondary = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSecondary
        ? AppColors.surfaceWhite
        : (isEnabled ? const Color(0xFF13141F) : const Color(0xFF13141F).withValues(alpha: 0.35));
    final textColor = isSecondary
        ? AppColors.textPrimary
        : (isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.6));

    return SizedBox(
      height: 56,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap ?? onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: isSecondary ? Border.all(color: AppColors.surfaceBorder) : null,
            ),
            child: Row(
              children: [
                if (showArrow) const SizedBox(width: 36),
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (showArrow)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isEnabled ? AppColors.royalBlue : AppColors.royalBlue.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
