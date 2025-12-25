import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/modules/nutrition/nutrition_controller.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';
import 'package:vipt/app/routes/pages.dart';

class DishListScreen extends StatelessWidget {
  DishListScreen({Key? key}) : super(key: key);

  final _controller = Get.find<NutritionController>();
  final Category cate = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Hero(
            tag: 'leadingButtonAppBar',
            child: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Hero(
          tag: 'titleAppBar',
          child: Text(
            cate.name.tr,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _controller.refreshMealData();
          // Reload meals for current category after refresh
          _controller.reloadMealsForCategory(cate);
        },
        child: Obx(() => ListView.separated(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          itemBuilder: (_, index) {
          final meal = _controller.meals[index];
          final nutrition = MealNutrition(meal: meal);
          return FutureBuilder(
              future: nutrition.getIngredients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Container(
                    width: 200.0,
                    height: 100.0,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColor.textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }
                // Kiểm tra asset có hợp lệ không (phải có đuôi file hoặc là URL)
                final isValidAsset = nutrition.meal.asset.isNotEmpty && 
                    (nutrition.meal.asset.contains('.') || nutrition.meal.asset.contains('http'));
                return CustomTile(
                  type: 3,
                  asset: isValidAsset ? nutrition.meal.asset : '',
                  onPressed: () {
                    // Truyền meal ID thay vì object để màn hình detail fetch dữ liệu mới
                    Get.toNamed(Routes.dishDetail, arguments: meal.id);
                  },
                  title: meal.name,
                  description: '${nutrition.calories.toInt()} kcal',
                );
              });
        },
        separatorBuilder: (_, index) => const Divider(
          indent: 24,
        ),
        //itemCount: _controller.workouts.length),
        itemCount: _controller.meals.length,
        )),
      ),
    );
  }
}
