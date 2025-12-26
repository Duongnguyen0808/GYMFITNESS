import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/services/api_client.dart'; // Import ApiClient để lấy serverUrl
import 'package:vipt/app/modules/recommendation_preview/recommendation_preview_controller.dart';
import 'package:vipt/app/routes/pages.dart';
import 'package:path/path.dart' as p;

class MealPreviewList extends StatelessWidget {
  final RecommendationPreviewController controller;

  const MealPreviewList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (controller.recommendedMeals.isEmpty) {
          return const SizedBox.shrink();
        }

        final mealsToShow = controller.recommendedMeals.take(6).toList();
        final hasMore = controller.recommendedMeals.length > 6;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${controller.recommendedMeals.length} bữa ăn',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (hasMore)
                      Text(
                        'Xem tất cả',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColor.primaryColor,
                            ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...mealsToShow
                  .map((meal) => _buildMealItem(context, meal))
                  .toList(),
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      '... và ${controller.recommendedMeals.length - 6} bữa ăn khác',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColor.textColor.withOpacity(0.6),
                          ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealItem(BuildContext context, Meal meal) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.toNamed(Routes.dishDetail, arguments: meal);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // ẢNH MÓN ĂN
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: _buildAsset(meal.asset), // Gọi hàm xử lý ảnh
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (meal.cookTime > 0)
                            Text(
                              '${meal.cookTime} phút',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color:
                                          AppColor.textColor.withOpacity(0.6)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  // HÀM XỬ LÝ ẢNH QUAN TRỌNG
  Widget _buildAsset(String asset) {
    // 1. Xử lý đường dẫn tương đối từ Server
    // Nếu asset bắt đầu bằng '/uploads', ta ghép thêm serverUrl vào trước
    String assetToShow = asset;
    if (assetToShow.startsWith('/uploads')) {
      assetToShow = '${ApiClient.instance.serverUrl}$assetToShow';
    }

    // 2. Nếu rỗng -> Ảnh default Nutrition
    if (assetToShow.isEmpty) {
      return Image.asset(
        PNGAssetString.nutrition_1,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Image.asset(PNGAssetString.fitness_1, fit: BoxFit.cover),
      );
    }

    // 3. Nếu là URL online (bao gồm cả link vừa ghép serverUrl)
    if (assetToShow.contains('http')) {
      return CachedNetworkImage(
        imageUrl: assetToShow,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, downloadProgress) => Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
            color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
            strokeWidth: 2, // Làm mỏng loading cho đẹp vì ảnh nhỏ
          ),
        ),
        errorWidget: (_, __, ___) =>
            Image.asset(PNGAssetString.nutrition_1, fit: BoxFit.cover),
      );
    }

    // 4. Nếu là Assets nội bộ (assets/...)
    if (assetToShow.startsWith('assets/')) {
      if (p.extension(assetToShow) == '.svg') {
        return SvgPicture.asset(
          assetToShow,
          fit: BoxFit.cover,
          placeholderBuilder: (_) =>
              Image.asset(PNGAssetString.nutrition_1, fit: BoxFit.cover),
        );
      } else {
        return Image.asset(
          assetToShow,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Image.asset(PNGAssetString.nutrition_1, fit: BoxFit.cover),
        );
      }
    }

    // 5. Các trường hợp còn lại -> Ảnh default
    return Image.asset(
      PNGAssetString.nutrition_1,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Image.asset(PNGAssetString.fitness_1, fit: BoxFit.cover),
    );
  }
}
