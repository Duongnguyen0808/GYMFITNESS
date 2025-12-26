import 'package:flutter/material.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';

class PlanInfoCard extends StatelessWidget {
  final RecommendationPreviewController controller;

  const PlanInfoCard({
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppColor.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Thông tin lộ trình',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(
              context,
              'Thời gian',
              '${controller.planLengthInDays} ngày',
              Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Bắt đầu',
              controller.startDate,
              Icons.play_arrow,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Kết thúc',
              controller.endDate,
              Icons.flag,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColor.textColor.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColor.textColor.withOpacity(0.7),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

