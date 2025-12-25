import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/global_widgets/app_bar_icon_button.dart';
import 'package:vipt/app/modules/loading/screens/loading_screen.dart';
import 'package:vipt/app/modules/nutrition/widgets/dish_information_widget.dart';
import 'package:vipt/app/modules/nutrition/widgets/dish_ingredients_widget.dart';
import 'package:vipt/app/modules/nutrition/widgets/dish_instructions_widget.dart';

class DishDetailScreen extends StatelessWidget {
  DishDetailScreen({Key? key}) : super(key: key);

  // Lấy meal ID từ arguments (có thể là MealNutrition hoặc meal ID)
  final dynamic _argument = Get.arguments;
  
  // Fetch dữ liệu mới từ Firebase
  Future<MealNutrition> _fetchMealData() async {
    String mealId;
    
    // Nếu argument là MealNutrition, lấy ID từ đó
    if (_argument is MealNutrition) {
      mealId = (_argument as MealNutrition).meal.id ?? '';
    } else if (_argument is String) {
      mealId = _argument;
    } else {
      // Fallback: nếu không có ID, dùng argument cũ
      return _argument as MealNutrition;
    }
    
    // Fetch meal mới từ Firebase
    final mealProvider = MealProvider();
    final meal = await mealProvider.fetch(mealId);
    
    // Tạo MealNutrition mới với dữ liệu mới nhất
    final nutrition = MealNutrition(meal: meal);
    await nutrition.getIngredients();
    
    return nutrition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondaryBackgroudColor,
      body: SafeArea(
        child: FutureBuilder<MealNutrition>(
          future: _fetchMealData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingScreen();
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi khi tải dữ liệu',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              );
            }
            
            final nutrition = snapshot.data!;
            
            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: AppBarIconButton(
                      padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                      hero: 'leadingButtonAppBar',
                      iconData: Icons.arrow_back_ios_new_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                      }),
                  pinned: true,
                  expandedHeight: Get.size.height * 0.36,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildImage(nutrition),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    DishInformationWidget(mealNutrition: nutrition),
                    const SizedBox(
                      height: 24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DishIngredientsWidget(
                        ingredients: {
                          for (var item in nutrition.ingredients)
                            item.name: nutrition.meal.ingreIDToAmount[item.id] ?? ''
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DishInstructionsWidget(
                          instructions: nutrition.meal.steps),
                    ),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage(MealNutrition nutrition) {
    final asset = nutrition.meal.asset;
    
    return Padding(
      padding: const EdgeInsets.all(36.0),
      child: asset.isEmpty || !asset.contains('http')
          ? Image.asset(
              JPGAssetString.meal,
              fit: BoxFit.fitHeight,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColorLight!.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  ),
                );
              },
            )
          : CachedNetworkImage(
              imageUrl: asset,
              fit: BoxFit.fitHeight,
              progressIndicatorBuilder: (context, url, loadingProgress) {
                return Center(
                  child: CircularProgressIndicator(
                    color:
                        AppColor.textColor.withOpacity(AppColor.subTextOpacity),
                    value: loadingProgress.progress,
                  ),
                );
              },
              errorWidget: (context, url, error) => Image.asset(
                JPGAssetString.meal,
                fit: BoxFit.fitHeight,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColor.primaryColorLight!.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 64, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
