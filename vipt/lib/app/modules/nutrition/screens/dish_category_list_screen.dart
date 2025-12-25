import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/modules/nutrition/nutrition_controller.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';

class DishCategoryListScreen extends StatelessWidget {
  DishCategoryListScreen({Key? key}) : super(key: key);

  final _controller = Get.find<NutritionController>();

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
            'Món ăn'.tr,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        actions: [
          // Refresh button
          Obx(() => _controller.isRefreshing.value
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _controller.refreshMealData(),
                  tooltip: 'Cập nhật dữ liệu',
                )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.refreshMealData(),
        child: Obx(() => _controller.mealCategories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có dữ liệu món ăn',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _controller.refreshMealData(),
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                itemBuilder: (_, index) {
                  final mealCate = _controller.mealCategories[index];
                  // Kiểm tra asset có hợp lệ không (phải có đuôi file hoặc là URL)
                  final isValidAsset = mealCate.asset.isNotEmpty && 
                      (mealCate.asset.contains('.') || mealCate.asset.contains('http'));
                  final assetPath = isValidAsset 
                      ? (mealCate.asset.contains('http') ? mealCate.asset : '${PNGAssetString.path}/${mealCate.asset}')
                      : '';
                  return CustomTile(
                    type: 1,
                    asset: assetPath,
                    onPressed: () {
                      _controller.loadContent(mealCate);
                    },
                    title: mealCate.name,
                    description: '${mealCate.countLeaf()} món ăn',
                  );
                },
                separatorBuilder: (_, index) {
                  return const Divider(
                    indent: 24,
                  );
                },
                itemCount: _controller.mealCategories.length,
              )),
      ),
    );
  }
}
