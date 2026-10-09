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
      {
        'label': 'Today',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_filled,
      },
      {
        'label': 'Progress',
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart_rounded,
      },
      {
        'label': 'Practice',
        'icon': Icons.outlined_flag_rounded,
        'activeIcon': Icons.flag_rounded,
      },
      {
        'label': 'Profile',
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
      },
    ];

    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final bottomPad = isIOS ? (safeBottom > 0 ? 12.0 : 8.0) : safeBottom + 8;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBorderLight, width: 1)),
      ),
      padding: EdgeInsets.only(top: 8, bottom: bottomPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = currentIndex == index;
          final item = items[index];

          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSelected ? (item['activeIcon'] as IconData) : (item['icon'] as IconData),
                    color: isSelected ? AppColors.royalBlue : AppColors.textMuted,
                    size: 24,
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
                  const SizedBox(height: 3),
                  // Royal blue dot indicator below active tab
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
    );
  }
}
