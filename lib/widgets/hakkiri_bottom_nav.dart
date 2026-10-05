import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class HakkiriBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HakkiriBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Daily Anchor', 'icon': Icons.home_outlined, 'activeIcon': Icons.home_filled},
      {'label': 'Analytics', 'icon': Icons.bar_chart_outlined, 'activeIcon': Icons.bar_chart_rounded},
      {'label': 'Challenges', 'icon': Icons.flag_outlined, 'activeIcon': Icons.flag_rounded},
      {'label': 'Settings', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBorderLight, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = currentIndex == index;
            final item = items[index];

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                      color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Blue dot indicator below active tab
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.royalBlue : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
