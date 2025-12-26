import 'package:flutter/material.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';

class CalorieInfoCard extends StatelessWidget {
  final RecommendationPreviewController controller;

  const CalorieInfoCard({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColor.primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColor.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Calories hàng ngày',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildCalorieItem(
              context,
              'BMR (Chuyển hóa cơ bản)',
              '${controller.bmr} cal',
              Icons.bedtime,
            ),
            const SizedBox(height: 12),
            _buildCalorieItem(
              context,
              'TDEE (Tổng năng lượng tiêu hao)',
              '${controller.tdee} cal',
              Icons.bolt,
            ),
            const Divider(height: 24),
            _buildCalorieItem(
              context,
              'Calories cần nạp',
              '${controller.dailyIntakeCalories} cal',
              Icons.restaurant,
              isHighlight: true,
            ),
            const SizedBox(height: 12),
            _buildCalorieItem(
              context,
              'Calories cần đốt',
              '${controller.dailyOuttakeCalories} cal',
              Icons.fitness_center,
              isHighlight: true,
            ),
            const SizedBox(height: 12),
            _buildCalorieItem(
              context,
              'Mục tiêu net calories',
              '${controller.dailyGoalCalories} cal',
              Icons.track_changes,
              isHighlight: true,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isHighlight = false,
    bool isPrimary = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isPrimary
              ? AppColor.primaryColor
              : AppColor.textColor.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isHighlight
                      ? AppColor.textColor
                      : AppColor.textColor.withOpacity(0.7),
                  fontWeight: isHighlight ? FontWeight.w500 : FontWeight.normal,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPrimary
                ? AppColor.primaryColor
                : isHighlight
                    ? AppColor.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.white : AppColor.primaryColor,
                ),
          ),
        ),
      ],
    );
  }
}

