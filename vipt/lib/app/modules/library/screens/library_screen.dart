import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/modules/library/library_controller.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';

class LibraryScreen extends StatelessWidget {
  LibraryScreen({Key? key}) : super(key: key);

  final _controller = Get.find<LibraryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        title: Hero(
          tag: 'titleAppBar',
          child: Text(
            'Thư viện'.tr,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        actions: [
          // Refresh all data button
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
                  onPressed: () => _controller.refreshAllData(),
                  tooltip: 'Cập nhật tất cả dữ liệu',
                )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _controller.refreshAllData(),
        child: Obx(() {
          if (_controller.sections.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có phần nào trong thư viện',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _controller.refreshAllData(),
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            children: [
              ..._controller.sections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return Column(
                  children: [
                    CustomTile(
                      asset: section.asset.isNotEmpty
                          ? section.asset
                          : JPGAssetString.workout_1, // Fallback image
                      onPressed: () {
                        try {
                          Get.toNamed(section.route);
                        } catch (e) {
                          Get.snackbar(
                            'Lỗi',
                            'Không thể mở màn hình: ${section.route}',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      },
                      title: section.title,
                      description: section.description,
                    ),
                    if (index < _controller.sections.length - 1)
                      const Divider(
                        indent: 24,
                      ),
                  ],
                );
              }).toList(),
            ],
          );
        }),
      ),
    );
  }
}
