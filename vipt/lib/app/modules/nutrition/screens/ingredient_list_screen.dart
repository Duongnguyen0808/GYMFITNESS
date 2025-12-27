import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/modules/nutrition/ingredient_controller.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';
import 'package:vipt/app/routes/pages.dart';

class IngredientListScreen extends StatelessWidget {
  IngredientListScreen({Key? key}) : super(key: key);

  final _controller = Get.put(IngredientController());

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
            'Nguyên liệu'.tr,
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
                  onPressed: () => _controller.refreshIngredients(),
                  tooltip: 'Cập nhật dữ liệu',
                )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.refreshIngredients(),
        child: Obx(() => _controller.isLoading.value
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
                ),
              )
            : _controller.ingredients.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có nguyên liệu',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _controller.refreshIngredients(),
                          child: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    itemBuilder: (_, index) {
                      final ingredient = _controller.ingredients[index];
                      // Kiểm tra imageUrl có hợp lệ không (phải có đuôi file hoặc là URL)
                      final isValidImageUrl = ingredient.imageUrl != null &&
                          ingredient.imageUrl!.isNotEmpty &&
                          (ingredient.imageUrl!.contains('.') ||
                              ingredient.imageUrl!.contains('http'));
                      return CustomTile(
                        type: 3,
                        asset: isValidImageUrl ? ingredient.imageUrl! : '',
                        onPressed: () {
                          Get.toNamed(Routes.ingredientDetail, arguments: ingredient);
                        },
                        title: ingredient.name,
                        description: '', // Bỏ thông tin dinh dưỡng khỏi description
                      );
                    },
                    separatorBuilder: (_, index) {
                      return const Divider(
                        indent: 24,
                      );
                    },
                    itemCount: _controller.ingredients.length,
                  )),
      ),
    );
  }
}

