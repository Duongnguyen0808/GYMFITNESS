import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/asset_strings.dart';

class MyNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const MyNetworkImage({
    Key? key,
    required this.url,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu URL rỗng, hiển thị hình ảnh mẫu
    if (url.isEmpty) {
      return Image.asset(
        JPGAssetString.workout_1,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            JPGAssetString.workout_2,
            fit: fit,
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      progressIndicatorBuilder: (context, url, loadingProgress) {
        return Center(
          child: CircularProgressIndicator(
            color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
            value: loadingProgress.progress,
          ),
        );
      },
      errorWidget: (context, url, error) => Image.asset(
        JPGAssetString.workout_1,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            JPGAssetString.workout_2,
            fit: fit,
          );
        },
      ),
    );
  }
}
