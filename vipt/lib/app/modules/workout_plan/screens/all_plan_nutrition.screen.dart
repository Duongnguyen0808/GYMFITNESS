import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/data/models/nutrition.dart';
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
    Map<DateTime, List<MealNutrition>> mealsByDate = {};
    
    // Lấy collections từ controller để có thông tin ngày chính xác
    final allCollections = controller.planMealCollection;
    
    // Tạo map từ meal ID sang MealNutrition
    final nutritionMap = <String, MealNutrition>{};
    for (var nutri in nutritionList) {
      nutritionMap[(nutri as MealNutrition).meal.id ?? ''] = nutri;
    }
    
    // Nhóm theo ngày
    for (var planCol in allCollections) {
      if (planCol.id == null || planCol.id!.isEmpty) continue;
      final planMeals = controller.planMeal
          .where((pm) => pm.listID == planCol.id)
          .toList();
      
      for (var planMeal in planMeals) {
        final nutrition = nutritionMap[planMeal.mealID];
        if (nutrition != null) {
          final dateKey = DateUtils.dateOnly(planCol.date);
          if (!mealsByDate.containsKey(dateKey)) {
            mealsByDate[dateKey] = [];
          }
          mealsByDate[dateKey]!.add(nutrition);
        }
      }
    }
    
    // Sắp xếp theo ngày
    final sortedDates = mealsByDate.keys.toList()..sort();
    
    int dayNumber = 1;
    for (var date in sortedDates) {
      final dayMeals = mealsByDate[date]!;
      
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
      
      // Thêm các meals của ngày đó
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
      
      dayNumber++;
    }

    return results;
  }
}
