import 'package:flutter/material.dart';

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
        'activeIcon': Icons.home_rounded,
      },
      {
        'label': 'Progress',
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart_rounded,
      },
      {
        'label': 'Practice',
        'icon': Icons.school_outlined,
        'activeIcon': Icons.school_rounded,
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
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: EdgeInsets.only(top: 8, bottom: bottomPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = currentIndex == index;
          final item = items[index];

          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Icon(
                      isSelected
                          ? (item['activeIcon'] as IconData)
                          : (item['icon'] as IconData),
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontFamily: 'Inter',
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
