import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';

class MealPreviewList extends StatelessWidget {
  final RecommendationPreviewController controller;

  const MealPreviewList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.recommendedMeals.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Chưa có bữa ăn được đề xuất',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.textColor.withOpacity(0.6),
                      ),
                ),
              ),
            ),
          );
        }

        // Hiển thị tối đa 6 meals, có thể scroll
        final mealsToShow = controller.recommendedMeals.take(6).toList();
        final hasMore = controller.recommendedMeals.length > 6;

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
                      '${controller.recommendedMeals.length} bữa ăn',
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
              ...mealsToShow.map((meal) => _buildMealItem(context, meal)),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '... và ${controller.recommendedMeals.length - 6} bữa ăn khác',
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

  Widget _buildMealItem(BuildContext context, Meal meal) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColor.secondaryColor.withOpacity(0.1),
        ),
        child: meal.asset.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  meal.asset,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.restaurant,
                    color: AppColor.secondaryColor,
                  ),
                ),
              )
            : Icon(
                Icons.restaurant,
                color: AppColor.secondaryColor,
              ),
      ),
      title: Text(
        meal.name,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: meal.cookTime > 0
          ? Text(
              '${meal.cookTime} phút',
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

