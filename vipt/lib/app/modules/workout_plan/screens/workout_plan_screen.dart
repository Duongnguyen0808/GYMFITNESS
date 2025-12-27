import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/modules/daily_plan/daily_plan_controller.dart';
import 'package:vipt/app/modules/daily_plan/widgets/goal_progress_indicator.dart';
import 'package:vipt/app/modules/daily_plan/widgets/input_amount_dialog.dart';
import 'package:vipt/app/modules/daily_plan/widgets/vertical_info_widget.dart';
import 'package:vipt/app/modules/home/home_controller.dart';
import 'package:vipt/app/modules/loading/screens/loading_screen.dart';
import 'package:vipt/app/modules/workout_collection/widgets/exercise_in_collection_tile.dart';
// Import MealPlanTile
import 'package:vipt/app/modules/nutrition_collection/widgets/meal_plan_tile.dart';
import 'package:vipt/app/modules/workout_plan/screens/default_plan_screen.dart';
import 'package:vipt/app/modules/workout_plan/widgets/plan_tab_holder.dart';
import 'package:vipt/app/modules/workout_plan/widgets/progress_info_widget.dart';
import 'package:vipt/app/modules/workout_plan/widgets/shortcut_button.dart';
import 'package:vipt/app/modules/workout_plan/widgets/weight_info_widget.dart';
import 'package:vipt/app/routes/pages.dart';

import '../workout_plan_controller.dart';

class WorkoutPlanScreen extends StatelessWidget {
  WorkoutPlanScreen({Key? key}) : super(key: key);

  final _controller = Get.find<WorkoutPlanController>();

  void _shortcutToTabs(int? dailyPlanTabIndex) {
    final _homeController = Get.find<HomeController>();
    final _dailyPlanController = Get.find<DailyPlanController>();

    if (dailyPlanTabIndex != null) {
      _homeController.tabController.jumpToTab(HomeController.dailyPlanTabIndex);
      _dailyPlanController.changeTab(dailyPlanTabIndex);
    } else {
      _homeController.tabController.jumpToTab(HomeController.profileTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    double bodyHeight = MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    return Obx(
      () => _controller.isLoading.value
          ? const LoadingScreen()
          : _controller.hasFinishedPlan.value
              ? const DefaultPlanScreen()
              : Scaffold(
                  backgroundColor: AppColor.exerciseBackgroundColor,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              'Lộ trình tập luyện',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: AppColor.accentTextColor),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _showSetOuttakeGoalDialog(context),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.settings_outlined,
                                size: 24,
                                color:
                                    AppColor.accentTextColor.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  body: RefreshIndicator(
                    onRefresh: () async {
                      await _controller.refreshAllData();
                    },
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ConstrainedBox(
                              constraints:
                                  BoxConstraints(minHeight: bodyHeight * 0.35),
                              child: Column(
                                children: [
                                  _buildInfo(
                                    context,
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 18),
                                    child: WeightInfoWidget(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: Obx(
                                      () {
                                        // Convert RxList to List để đảm bảo reactive update
                                        final streakList =
                                            _controller.planStreak.toList();
                                        return ProgressInfoWidget(
                                          completeDays: streakList,
                                          currentDay: _controller
                                                      .currentDayNumber.value >
                                                  0
                                              ? _controller
                                                  .currentDayNumber.value
                                                  .toString()
                                              : _controller
                                                  .currentStreakDay.value
                                                  .toString(),
                                          showAction:
                                              false, // Bỏ nút "Bắt đầu lại" - streak tự động reset
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 24,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Flexible(
                                        child: ShortcutButton(
                                          onPressed: () {
                                            _shortcutToTabs(DailyPlanController
                                                .exerciseTabIndex);
                                          },
                                          title: 'Luyện tập',
                                          icon: SvgPicture.asset(
                                            SVGAssetString.shortcutExercise,
                                            height: 24,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: ShortcutButton(
                                          onPressed: () {
                                            _shortcutToTabs(DailyPlanController
                                                .nutritionTabIndex);
                                          },
                                          title: 'Dinh dưỡng',
                                          icon: SvgPicture.asset(
                                            SVGAssetString.shortcutNutrition,
                                            height: 24,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: ShortcutButton(
                                          onPressed: () {
                                            _shortcutToTabs(DailyPlanController
                                                .waterTabIndex);
                                          },
                                          title: 'Nước uống',
                                          icon: SvgPicture.asset(
                                            SVGAssetString.shortcutWater,
                                            height: 24,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: ShortcutButton(
                                          onPressed: () {
                                            _shortcutToTabs(null);
                                          },
                                          title: 'Thống kê',
                                          icon: SvgPicture.asset(
                                            SVGAssetString.shortcutStatistics,
                                            height: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // --- 1. DANH SÁCH BÀI TẬP (ADMIN) ---
                                  const SizedBox(height: 24),
                                  Obx(() {
                                    final exerciseData =
                                        DataService.instance.collectionListRx;

                                    if (exerciseData.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          child: Text(
                                            'Danh sách bài tập',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium!
                                                .copyWith(
                                                  color:
                                                      AppColor.accentTextColor,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          child: Column(
                                            children:
                                                exerciseData.map((collection) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: ExerciseInCollectionTile(
                                                  asset: collection.asset,
                                                  title: collection.title,
                                                  description: '',
                                                  onPressed: () {
                                                    Get.toNamed(
                                                      Routes
                                                          .workoutCollectionDetail,
                                                      arguments: collection,
                                                    );
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),

                                  // --- 2. DANH SÁCH THỰC ĐƠN (ADMIN) - MỚI ---
                                  Obx(() {
                                    final mealData = DataService
                                        .instance.mealCollectionListRx;

                                    if (mealData.isEmpty)
                                      return const SizedBox.shrink();

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Padding để tách biệt với danh sách trên
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          child: Text(
                                            'Thực đơn đề xuất',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium!
                                                .copyWith(
                                                  color:
                                                      AppColor.accentTextColor,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18),
                                          child: Column(
                                            children:
                                                mealData.map((collection) {
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: MealPlanTile(
                                                  asset: collection.asset,
                                                  title: collection.title,
                                                  description: collection
                                                          .description
                                                          .isNotEmpty
                                                      ? collection.description
                                                      : '',
                                                  onPressed: () {
                                                    Get.toNamed(
                                                        Routes.mealPlanDetail,
                                                        arguments: collection);
                                                  },
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    );
                                  }),
                                  // --------------------------------------------------
                                ],
                              ),
                            ),
                            GetBuilder<WorkoutPlanController>(builder: (_) {
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                    minHeight: bodyHeight * 0.65),
                                child: Container(
                                  width: double.maxFinite,
                                  padding:
                                      const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: const SingleChildScrollView(
                                    physics: NeverScrollableScrollPhysics(),
                                    child: PlanTabHolder(),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  _buildInfo(context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Flexible(
              flex: 2,
              child: VerticalInfoWidget(
                title: _controller.intakeCalories.value.toString(),
                subtitle: 'hấp thụ',
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 3,
              child: Obx(
                () {
                  final leftValueForCircle = _controller.outtakeCalories.value -
                      _controller.intakeCalories.value;
                  // Hiển thị mục tiêu từ controller (đã tính từ thông tin user)
                  final goalValue =
                      _controller.dailyOuttakeGoalCalories.value > 0
                          ? _controller.dailyOuttakeGoalCalories.value
                          : null; // Không hardcode, để null nếu chưa có
                  return GoalProgressIndicator(
                    radius: screenWidth * 0.22,
                    value: leftValueForCircle,
                    unitString: 'calories',
                    goalValue: goalValue,
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              flex: 2,
              child: _buildOuttakeCaloriesWidget(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOuttakeCaloriesWidget(BuildContext context) {
    return Obx(
      () {
        final outtakeValue = _controller.outtakeCalories.value;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              outtakeValue.toString(),
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColor.accentTextColor,
                  ),
            ),
            Text(
              'tiêu hao',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColor.accentTextColor,
                  ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSetOuttakeGoalDialog(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return InputAmountDialog(
          title: 'Mục tiêu calories tiêu hao',
          unit: 'kcal',
          value: _controller.dailyOuttakeGoalCalories.value > 0
              ? _controller.dailyOuttakeGoalCalories.value
              : 500,
          min: 0,
          max: 5000,
          confirmButtonColor: AppColor.exerciseBackgroundColor,
          confirmButtonText: 'Xác nhận',
          sliderActiveColor: AppColor.exerciseBackgroundColor,
          sliderInactiveColor: AppColor.exerciseBackgroundColor.withOpacity(
            AppColor.subTextOpacity,
          ),
        );
      },
    );

    if (result != null && result >= 0) {
      await _controller.saveOuttakeGoalCalories(result);
      // Đảm bảo UI được update - GetX sẽ tự động update Obx widgets
      // Nhưng có thể cần một chút delay để GetX xử lý
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
