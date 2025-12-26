import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';

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
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Chưa có bài tập được đề xuất',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.textColor.withOpacity(0.6),
                      ),
                ),
              ),
            ),
          );
        }

        // Hiển thị tối đa 6 exercises, có thể scroll
        final exercisesToShow = controller.recommendedExercises.take(6).toList();
        final hasMore = controller.recommendedExercises.length > 6;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              ...exercisesToShow.map((exercise) => _buildExerciseItem(context, exercise)),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '... và ${controller.recommendedExercises.length - 6} bài tập khác',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColor.textColor.withOpacity(0.6),
                          ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExerciseItem(BuildContext context, Workout exercise) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColor.primaryColor.withOpacity(0.1),
        ),
        child: exercise.thumbnail.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  exercise.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.fitness_center,
                    color: AppColor.primaryColor,
                  ),
                ),
              )
            : Icon(
                Icons.fitness_center,
                color: AppColor.primaryColor,
              ),
      ),
      title: Text(
        exercise.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: exercise.metValue > 0
          ? Text(
              'MET: ${exercise.metValue}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColor.textColor.withOpacity(0.6),
                  ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: AppColor.textColor.withOpacity(0.4),
      ),
    );
  }
}

