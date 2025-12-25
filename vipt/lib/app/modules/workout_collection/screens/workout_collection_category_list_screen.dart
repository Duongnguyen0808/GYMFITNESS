import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:get/get.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';
import 'package:vipt/app/modules/workout_collection/workout_collection_controller.dart';
import 'package:vipt/app/routes/pages.dart';
import 'package:vipt/app/data/services/data_service.dart';

class WorkoutCollectionCategoryListScreen extends StatelessWidget {
  WorkoutCollectionCategoryListScreen({Key? key}) : super(key: key);

  final _controller = Get.find<WorkoutCollectionController>();

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
            'Bộ luyện tập'.tr,
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
                  onPressed: () => _controller.refreshCollectionData(),
                  tooltip: 'Cập nhật dữ liệu',
                )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.refreshCollectionData(),
        child: Obx(() => _controller.collectionCategories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có dữ liệu bộ luyện tập',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _controller.refreshCollectionData(),
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                itemBuilder: (_, index) {
                  if (index == 0) {
                    return Obx(() => CustomTile(
                          type: 1,
                          asset: JPGAssetString.yourWorkoutCollection,
                          onPressed: () {
                            Get.toNamed(Routes.myWorkoutCollectionList);
                          },
                          title: 'Bộ luyện tập của bạn',
                          description:
                              '${DataService.instance.userCollectionListRx.length} bộ bài tập',
                        ));
                  }
                  final cate = _controller.collectionCategories[index - 1];
                  // Kiểm tra asset có hợp lệ không (phải có đuôi file hoặc là URL)
                  final isValidAsset = cate.asset.isNotEmpty && 
                      (cate.asset.contains('.') || cate.asset.contains('http'));
                  final assetPath = isValidAsset 
                      ? (cate.asset.contains('http') ? cate.asset : '${JPGAssetString.path}/${cate.asset}')
                      : '';
                  return CustomTile(
                    type: 1,
                    asset: assetPath,
                    onPressed: () {
                      _controller.loadCollectionListBaseOnCategory(cate);
                    },
                    title: cate.name.tr,
                    description:
                        '${_controller.collectionCategories[index - 1].countLeaf()} bộ bài tập',
                  );
                },
                separatorBuilder: (_, index) => const Divider(
                      indent: 24,
                    ),
                itemCount: _controller.collectionCategories.length + 1,
              )),
      ),
    );
  }
}
