import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:path/path.dart' as p;

class ExerciseInCollectionTile extends StatelessWidget {
  final String asset;
  final String title;
  final String description;
  final Function() onPressed;
  const ExerciseInCollectionTile({
    Key? key,
    required this.asset,
    required this.title,
    this.description = '',
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(
        Radius.circular(8),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(
          Radius.circular(8),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // ASSET
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.18,
                          maxHeight: constraints.maxWidth * 0.18,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: _buildAsset(asset),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth * 0.05,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TITLE
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildAsset(String asset) {
    // Nếu asset rỗng → hiển thị hình ảnh mẫu từ assets
    if (asset.isEmpty) {
      return Image.asset(
        PNGAssetString.workout_1,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            PNGAssetString.fitness_1,
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
          PNGAssetString.workout_1,
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
            PNGAssetString.workout_1,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              PNGAssetString.workout_1,
              fit: BoxFit.cover,
            );
          },
        );
      }
    }
    
    // Nếu chỉ là filename (không có path) → hiển thị hình ảnh mẫu
    return Image.asset(
      PNGAssetString.workout_1,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          PNGAssetString.fitness_1,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
