import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';
import 'package:vipt/app/modules/workout_collection/widgets/exercise_in_collection_tile.dart';
import 'package:vipt/app/routes/pages.dart';
// Import ApiClient
import 'package:vipt/app/data/services/api_client.dart';

class ExercisePreviewList extends StatelessWidget {
  final RecommendationPreviewController controller;

  const ExercisePreviewList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.recommendedExercises.isEmpty) {
          return const SizedBox.shrink();
        }

        final exercisesToShow = controller.recommendedExercises.take(6).toList();
        final hasMore = controller.recommendedExercises.length > 6;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${controller.recommendedExercises.length} bài tập',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (hasMore)
                      Text(
                        'Xem tất cả',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColor.primaryColor,
                            ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              ...exercisesToShow.map((exercise) {
                // 1. Dùng Thumbnail (ảnh tĩnh)
                String assetToShow = exercise.thumbnail;
                
                // 2. Nếu đường dẫn là tương đối (/uploads...), ghép với serverUrl động
                if (assetToShow.startsWith('/uploads')) {
                  // Dùng biến serverUrl từ ApiClient thay vì hardcode IP
                  assetToShow = '${ApiClient.instance.serverUrl}$assetToShow';
                }
                
                return ExerciseInCollectionTile(
                  asset: assetToShow,
                  title: exercise.name,
                  description: exercise.metValue > 0 ? 'MET: ${exercise.metValue}' : '',
                  onPressed: () {
                    Get.toNamed(Routes.exerciseDetail, arguments: exercise);
                  },
                );
              }).toList(),
              
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '... và ${controller.recommendedExercises.length - 6} bài tập khác',
                    style: TextStyle(color: AppColor.textColor.withOpacity(0.6)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}