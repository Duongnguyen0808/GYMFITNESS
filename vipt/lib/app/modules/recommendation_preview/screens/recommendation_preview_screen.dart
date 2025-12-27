import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';
import 'package:vipt/app/modules/recommendation_preview/widgets/calorie_info_card.dart';
import 'package:vipt/app/modules/recommendation_preview/widgets/exercise_preview_list.dart';
import 'package:vipt/app/modules/recommendation_preview/widgets/meal_preview_list.dart';
import 'package:vipt/app/modules/recommendation_preview/widgets/plan_info_card.dart';

class RecommendationPreviewScreen extends StatelessWidget {
  const RecommendationPreviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Lộ trình đề xuất',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GetX<RecommendationPreviewController>(
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColor.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => controller.loadRecommendation(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: AppDecoration.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Dựa trên thông tin của bạn, chúng tôi đã tạo một lộ trình phù hợp:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // Plan Info Card
                PlanInfoCard(controller: controller),
                const SizedBox(height: 16),

                // Calorie Info Card
                CalorieInfoCard(controller: controller),
                const SizedBox(height: 24),

                // Exercises Preview
                Text(
                  'Bài tập được đề xuất',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ExercisePreviewList(controller: controller),
                const SizedBox(height: 24),

                // Meals Preview
                Text(
                  'Bữa ăn được đề xuất',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                MealPreviewList(controller: controller),
                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(context, controller),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, RecommendationPreviewController controller) {
    return Column(
      children: [
        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isCreatingPlan.value
                  ? null
                  : () => controller.confirmAndCreatePlan(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isCreatingPlan.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Xác nhận và tạo lộ trình',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Regenerate Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: controller.isCreatingPlan.value
                ? null
                : () => controller.regenerateRecommendation(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColor.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tạo lại đề xuất',
              style: TextStyle(
                fontSize: 16,
                color: AppColor.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

