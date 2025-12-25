import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/global_widgets/app_bar_icon_button.dart';
import 'package:vipt/app/modules/profile/profile_controller.dart';
import 'package:vipt/app/modules/profile/widgets/progress_image_widget.dart';
import 'package:vipt/app/modules/profile/widgets/weekly_exercise_widget.dart';
import 'package:vipt/app/modules/profile/widgets/weekly_nutrition_widget.dart';
import 'package:vipt/app/modules/profile/widgets/weekly_water_widget.dart';
import 'package:vipt/app/modules/profile/widgets/weight_tracking_widget.dart';
import 'package:vipt/app/routes/pages.dart';

// Widget để lazy load với staggered delay - chỉ render khi visible
class _LazyLoadWidget extends StatefulWidget {
  final Widget child;
  final int delayMs; // Delay riêng cho từng widget
  const _LazyLoadWidget({required this.child, this.delayMs = 100});

  @override
  State<_LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<_LazyLoadWidget> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Staggered delay để không load tất cả cùng lúc
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        setState(() => _isVisible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColor.textColor.withOpacity(0.3),
          ),
        ),
      );
    }
    return widget.child;
  }
}

class ProfileScreen extends StatelessWidget {
  ProfileScreen({Key? key}) : super(key: key);

  final _controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    double bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        kBottomNavigationBarHeight;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          AppBarIconButton(
            iconData: Icons.settings_rounded,
            onPressed: () {
              Get.toNamed(Routes.setting);
            },
            hero: 'settingButton',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover, // Dùng cover thay vì fitHeight để tối ưu hơn
            image: AssetImage(JPGAssetString.userWorkoutCollection),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  height: bodyHeight * 0.05,
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: bodyHeight * 0.86),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                          child: Text(
                            'Quá trình của bạn',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .copyWith(
                                  color: AppColor.textColor,
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: AppColor.textFieldUnderlineColor,
                          ),
                        ),
                        _LazyLoadWidget(
                          delayMs: 150,
                          child: WeeklyExerciseWidget(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: AppColor.textFieldUnderlineColor,
                          ),
                        ),
                        _LazyLoadWidget(
                          delayMs: 250,
                          child: WeeklyNutritionWidget(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: AppColor.textFieldUnderlineColor,
                          ),
                        ),
                        _LazyLoadWidget(
                          delayMs: 350,
                          child: WeeklyWaterWidget(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: AppColor.textFieldUnderlineColor,
                          ),
                        ),
                        _LazyLoadWidget(
                          delayMs: 450,
                          child: Obx(
                            () => WeightTrackingWidget(
                              weighTracks: _controller.weightTrackList,
                              handleChangeTimeRange:
                                  _controller.changeWeighDateRange,
                              timeRange: _controller.weightDateRange.value,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(
                            color: AppColor.textFieldUnderlineColor,
                          ),
                        ),
                        _LazyLoadWidget(
                          delayMs: 650,
                          child: ProgressImageWidget(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
