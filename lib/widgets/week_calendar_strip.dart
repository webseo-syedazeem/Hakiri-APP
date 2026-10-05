import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WeekCalendarStrip extends StatelessWidget {
  final int selectedDayIndex;
  final ValueChanged<int>? onDaySelected;

  const WeekCalendarStrip({
    super.key,
    this.selectedDayIndex = 3, // Default Thursday 4 as in Page 5, or Monday 1 as in Page 3
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final days = [
      {'day': 'MON', 'num': '1'},
      {'day': 'TUE', 'num': '2'},
      {'day': 'WED', 'num': '3'},
      {'day': 'THU', 'num': '4'},
      {'day': 'FRI', 'num': '5'},
      {'day': 'SAT', 'num': '6'},
      {'day': 'SUN', 'num': '7'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEAE2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(days.length, (index) {
          final isSelected = selectedDayIndex == index;
          final d = days[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected?.call(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.royalBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d['day']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['num']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
