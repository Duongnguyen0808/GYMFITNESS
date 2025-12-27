import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/global_widgets/app_bar_icon_button.dart';
import 'package:vipt/app/modules/workout_collection/widgets/exercise_in_collection_tile.dart';
import 'package:vipt/app/modules/workout_plan/workout_plan_controller.dart';

class AllPlanNutritionScreen extends StatelessWidget {
  final List<MealNutrition> nutritionList;
  final Function(MealNutrition) elementOnPress;
  final DateTime startDate;
  final bool isLoading;
  const AllPlanNutritionScreen(
      {Key? key,
      required this.startDate,
      required this.nutritionList,
      required this.elementOnPress,
      required this.isLoading})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.only(top: 48),
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                AppBarIconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  iconData: Icons.close,
                  hero: '',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'DANH SÁCH BỮA ĂN',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              children: _buildNutritionList(
                context,
                startDate: startDate,
                nutritionList: nutritionList,
                elementOnPress: elementOnPress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildNutritionList(context,
      {required DateTime startDate,
      required List<MealNutrition> nutritionList,
      required Function(MealNutrition) elementOnPress}) {
    List<Widget> results = [];

    // Nhóm meals theo ngày từ controller
    final controller = Get.find<WorkoutPlanController>();
    debugPrint(
        '🔍 AllPlanNutritionScreen._buildNutritionList called: nutritionList.length=${nutritionList.length}, planMeal.length=${controller.planMeal.length}, planMealCollection.length=${controller.planMealCollection.length}');
    Map<DateTime, List<MealNutrition>> mealsByDate = {};

    // Lấy collections từ controller để có thông tin ngày chính xác
    final allCollections = controller.planMealCollection;

    // Nếu không có planMealCollection (ví dụ khi người dùng chưa tạo plan),
    // hiển thị nutritionList thẳng hàng (fallback) thay vì nhóm theo ngày rỗng.
    if (allCollections.isEmpty) {
      // Thêm một tiêu đề ngắn để báo là đang hiển thị gợi ý/không theo ngày
      if (nutritionList.isNotEmpty) {
        results.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            'Gợi ý món ăn',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ));
      }

      for (var nutrition in nutritionList) {
        Widget collectionToWidget = Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ExerciseInCollectionTile(
              asset: nutrition.meal.asset == ''
                  ? JPGAssetString.meal
                  : nutrition.meal.asset,
              title: nutrition.getName(),
              description: nutrition.calories.toStringAsFixed(0) + ' kcal',
              onPressed: () {
                elementOnPress(nutrition);
              }),
        );

        results.add(collectionToWidget);
      }

      return results;
    }

    // Tạo map từ meal ID sang MealNutrition
    final nutritionMap = <String, MealNutrition>{};
    for (var nutri in nutritionList) {
      nutritionMap[nutri.meal.id ?? ''] = nutri;
    }

    // Nhóm theo ngày từ plan collections
    for (var planCol in allCollections) {
      if (planCol.id == null || planCol.id!.isEmpty) continue;
      final planMeals =
          controller.planMeal.where((pm) => pm.listID == planCol.id).toList();
      final dateKey = DateUtils.dateOnly(planCol.date);
      for (var planMeal in planMeals) {
        final nutrition = nutritionMap[planMeal.mealID];
        if (nutrition != null) {
          mealsByDate.putIfAbsent(dateKey, () => []);
          mealsByDate[dateKey]!.add(nutrition);
        }
      }
    }

    // Xác định khoảng ngày hiển thị: dùng plan.startDate..plan.endDate nếu có, ngược lại 30 ngày từ startDate
    DateTime rangeStart = DateUtils.dateOnly(startDate);
    DateTime rangeEnd;
    if (controller.currentWorkoutPlan.value != null) {
      rangeEnd =
          DateUtils.dateOnly(controller.currentWorkoutPlan.value!.endDate);
    } else {
      rangeEnd = rangeStart.add(const Duration(days: 29));
    }

    int dayNumber = 1;
    for (DateTime date = rangeStart;
        !date.isAfter(rangeEnd);
        date = date.add(const Duration(days: 1))) {
      final dateKey = DateUtils.dateOnly(date);

      // Thêm day indicator
      Widget dayIndicator = Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Divider(
                thickness: 1,
                color: AppColor.textFieldUnderlineColor,
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NGÀY $dayNumber',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColor.textColor.withOpacity(
                          AppColor.subTextOpacity,
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                color: AppColor.textFieldUnderlineColor,
              ),
            ),
          ],
        ),
      );

      results.add(dayIndicator);

      final dayMeals = mealsByDate[dateKey] ?? [];

      if (dayMeals.isNotEmpty) {
        for (var nutrition in dayMeals) {
          Widget collectionToWidget = Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExerciseInCollectionTile(
                asset: nutrition.meal.asset == ''
                    ? JPGAssetString.meal
                    : nutrition.meal.asset,
                title: nutrition.getName(),
                description: nutrition.calories.toStringAsFixed(0) + ' kcal',
                onPressed: () {
                  elementOnPress(nutrition);
                }),
          );
          results.add(collectionToWidget);
        }
      } else {
        // Nếu ngày không có meal theo plan, hiển thị tối đa 2 món gợi ý để không để trống
        final fallback = nutritionList.take(2).toList();
        for (var nutrition in fallback) {
          Widget collectionToWidget = Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExerciseInCollectionTile(
                asset: nutrition.meal.asset == ''
                    ? JPGAssetString.meal
                    : nutrition.meal.asset,
                title: nutrition.getName(),
                description: nutrition.calories.toStringAsFixed(0) + ' kcal',
                onPressed: () {
                  elementOnPress(nutrition);
                }),
          );
          results.add(collectionToWidget);
        }
      }

      dayNumber++;
    }

    return results;
  }
}
