import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/ingredient.dart';
import 'package:vipt/app/global_widgets/app_bar_icon_button.dart';
import 'package:vipt/app/global_widgets/network_image.dart';

class IngredientDetailScreen extends StatelessWidget {
  IngredientDetailScreen({Key? key}) : super(key: key);

  final Ingredient ingredient = Get.arguments as Ingredient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Kiểm tra imageUrl có hợp lệ không
    final isValidImageUrl = ingredient.imageUrl != null &&
        ingredient.imageUrl!.isNotEmpty &&
        (ingredient.imageUrl!.contains('.') ||
            ingredient.imageUrl!.contains('http'));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: AppBarIconButton(
          iconData: Icons.arrow_back_ios_new_rounded,
          hero: 'leadingButtonAppBar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Nguyên liệu'.tr,
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              width: double.infinity,
              height: 250,
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              child: isValidImageUrl
                  ? MyNetworkImage(
                      url: ingredient.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                    ),
            ),

            // Ingredient Name
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                ingredient.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),

            // Nutritional Information Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin dinh dưỡng'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Calories Card
                  _buildNutritionCard(
                    context,
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    label: 'Calories',
                    value: '${ingredient.kcal.toInt()}',
                    unit: 'kcal',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Protein Card
                  _buildNutritionCard(
                    context,
                    icon: Icons.fitness_center,
                    iconColor: Colors.blue,
                    label: 'Protein',
                    value: '${ingredient.protein.toInt()}',
                    unit: 'g',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Carbs Card
                  _buildNutritionCard(
                    context,
                    icon: Icons.grain,
                    iconColor: Colors.green,
                    label: 'Carbs',
                    value: '${ingredient.carbs.toInt()}',
                    unit: 'g',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Fat Card
                  _buildNutritionCard(
                    context,
                    icon: Icons.water_drop,
                    iconColor: Colors.amber,
                    label: 'Fat',
                    value: '${ingredient.fat.toInt()}',
                    unit: 'g',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Note: Values are per 100g
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColor.textColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Giá trị dinh dưỡng trên 100g'.tr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        unit,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

