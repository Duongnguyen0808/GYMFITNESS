import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/modules/nutrition_collection/nutrition_collection_controller.dart';
import 'package:vipt/app/modules/nutrition_collection/widgets/meal_plan_tile.dart';
import 'package:vipt/app/routes/pages.dart';

class MealPlanListScreen extends StatelessWidget {
  MealPlanListScreen({Key? key}) : super(key: key);

  final _controller = Get.find<NutritionCollectionController>();

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
              'Kế hoạch dinh dưỡng'.tr,
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
                    onPressed: () => _controller.refreshMealCollectionData(),
                    tooltip: 'Cập nhật dữ liệu',
                  )),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => _controller.refreshMealCollectionData(),
          child: Obx(() => _controller.mealCollectionList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có kế hoạch dinh dưỡng',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => _controller.refreshMealCollectionData(),
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  itemBuilder: (context, index) {
                    final mealCollection = _controller.mealCollectionList[index];
                    return MealPlanTile(
                      onPressed: () {
                        Get.toNamed(Routes.mealPlanDetail,
                            arguments: mealCollection);
                      },
                      asset: mealCollection.asset,
                      title: mealCollection.title,
                      description:
                          '${mealCollection.dateToMealID.length} ngày'.tr,
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                        indent: 24,
                      ),
                  itemCount: _controller.mealCollectionList.length,
                )),
        ));
  }
}
