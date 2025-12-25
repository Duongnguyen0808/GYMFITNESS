import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';
import 'package:vipt/app/modules/workout/workout_controller.dart';

class CategoryListScreen extends StatelessWidget {
  CategoryListScreen({Key? key}) : super(key: key);

  final _controller = Get.find<WorkoutController>();

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
            'Bài tập'.tr,
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
                  onPressed: () => _controller.refreshWorkoutData(),
                  tooltip: 'Cập nhật dữ liệu',
                )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.refreshWorkoutData(),
        child: Obx(() => _controller.workoutCategories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có dữ liệu bài tập',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _controller.refreshWorkoutData(),
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                itemBuilder: (_, index) {
                  final cate = _controller.workoutCategories[index];
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
                      _controller.loadContent(cate);
                    },
                    title: cate.name,
                    description:
                        '${_controller.workoutCategories[index].countLeaf()} bài tập',
                  );
                },
                separatorBuilder: (_, index) {
                  return const Divider(
                    indent: 24,
                  );
                },
                itemCount: _controller.workoutCategories.length,
              )),
      ),
    );
  }
}
