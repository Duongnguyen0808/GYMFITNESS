import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:path/path.dart' as p;

class CustomTile extends StatelessWidget {
  final String asset;
  final String title;
  final String description;
  final Function() onPressed;
  final int type;
  const CustomTile(
      {Key? key,
      required this.asset,
      required this.title,
      this.description = '',
      required this.onPressed,
      this.type = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double assetWidth = _getAssetWidth(type);
    double assetHeight = _getAssetHeight(type);
    double gapWidthFactor = _getGapWidthFactor(type);
    // double textFieldWidthFactor = _getTextFieldWidthFactor(type);
    TextStyle? titleStyle = _getTitleStyle(context, type);

    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 8,
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  crossAxisAlignment: description != ''
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.center,
                  children: [
                    // ASSET
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: assetHeight,
                        width: assetWidth,
                        decoration: BoxDecoration(
                          color: type != 3
                              ? AppColor.textFieldFill
                                  .withOpacity(AppColor.subTextOpacity)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildAsset(asset),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth * gapWidthFactor,
                    ),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TITLE
                          Text(
                            title,
                            style: titleStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),

                          if (description != '')
                            const SizedBox(
                              height: 2,
                            ),
                          // DESCRIPTION
                          if (description != '')
                            Text(
                              description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    color: AppColor.textColor
                                        .withOpacity(AppColor.subTextOpacity),
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
              ),
            ],
          );
        }),
      ),
    );
  }

  _buildAsset(String asset) {
    // Nếu asset rỗng → hiển thị hình ảnh mẫu từ assets
    if (asset.isEmpty) {
      return Image.asset(
        JPGAssetString.workout_1,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            JPGAssetString.workout_2,
            fit: BoxFit.cover,
          );
        },
      );
    }

    // Nếu là URL (http hoặc https) → load network image
    if (asset.contains('http')) {
      return CachedNetworkImage(
        imageUrl: asset,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, downloadProgress) => Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
            color: AppColor.textColor.withOpacity(AppColor.subTextOpacity),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          JPGAssetString.workout_1,
          fit: BoxFit.cover,
        ),
      );
    }

    // Nếu bắt đầu bằng 'assets/' → load local asset
    if (asset.startsWith('assets/')) {
      if (p.extension(asset) == '.svg') {
        return SvgPicture.asset(
          asset,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => Image.asset(
            JPGAssetString.workout_1,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              JPGAssetString.workout_1,
              fit: BoxFit.cover,
            );
          },
        );
      }
    }

    // Nếu chỉ là filename (không có path) → hiển thị hình ảnh mẫu
    return Image.asset(
      JPGAssetString.workout_1,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          JPGAssetString.workout_2,
          fit: BoxFit.cover,
        );
      },
    );
  }

  double _getGapWidthFactor(int level) {
    switch (level) {
      case 0:
        return 0.04;
      case 1:
        return 0.04;
      case 2:
        return 0.04;
      case 3:
        return 0.04;
      default:
        return 0.04;
    }
  }

  double _getAssetWidth(int level) {
    switch (level) {
      case 0:
        return 128;
      case 1:
        return 110;
      case 2:
        return 100;
      case 3:
        return 100;
      default:
        return 128;
    }
  }

  double _getAssetHeight(int level) {
    switch (level) {
      case 0:
        return 150;
      case 1:
        return 130;
      case 2:
        return 80;
      case 3:
        return 100;
      default:
        return 150;
    }
  }

  TextStyle? _getTitleStyle(BuildContext context, int level) {
    switch (level) {
      case 0:
        return Theme.of(context).textTheme.displaySmall;
      case 1:
        return Theme.of(context).textTheme.displaySmall;
      case 2:
        return Theme.of(context).textTheme.headlineMedium;
      case 3:
        return Theme.of(context).textTheme.headlineMedium;
      default:
        return Theme.of(context).textTheme.displaySmall;
    }
  }
}
