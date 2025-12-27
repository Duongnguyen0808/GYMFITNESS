import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/collection_setting.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/data/models/nutrition.dart';
import 'package:vipt/app/data/models/plan_exercise.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/global_widgets/custom_confirmation_dialog.dart';
import 'package:vipt/app/global_widgets/loading_widget.dart';
import 'package:vipt/app/modules/nutrition/nutrition_controller.dart';
import 'package:vipt/app/modules/workout_collection/widgets/exercise_in_collection_tile.dart';
import 'package:vipt/app/modules/workout_collection/workout_collection_controller.dart';
import 'package:vipt/app/modules/workout_plan/screens/all_plan_exercise_screen.dart';
import 'package:vipt/app/modules/workout_plan/screens/all_plan_nutrition.screen.dart';
import 'package:vipt/app/routes/pages.dart';

import '../workout_plan_controller.dart';

class PlanTabHolder extends StatefulWidget {
  const PlanTabHolder({Key? key}) : super(key: key);

  @override
  State<PlanTabHolder> createState() => _PlanTabHolderState();
}

class _PlanTabHolderState extends State<PlanTabHolder>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  final _controller = Get.find<WorkoutPlanController>();

  List<WorkoutCollection> workouts = [];
  List<MealNutrition> meals = [];
  List<WorkoutCollection> allWorkouts = [];
  List<MealNutrition> allMeals = [];

  Timer? _reloadWorkoutsTimer;
  Timer? _reloadMealsTimer;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();

    // Lắng nghe thay đổi từ DataService để tự động reload
    _setupDataServiceListeners();

    // Load dữ liệu ban đầu
    _loadInitialData();

    // Đảm bảo loadDailyGoalCalories được gọi lại nếu chưa có workout plan
    ever(_controller.isLoading, (isLoading) {
      if (isLoading == false && mounted) {
        // Kiểm tra lại workout plan sau khi loading xong
        if (_controller.currentWorkoutPlan.value == null) {
          _controller.loadDailyGoalCalories();
        }
        // Reload dữ liệu sau khi controller.onInit() hoàn thành
        // Delay một chút để đảm bảo widget đã mount
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _reloadData();
          }
        });
      }
    });

    // Lắng nghe thay đổi planExerciseCollection với debounce để tránh reload quá nhiều
    ever(_controller.planExerciseCollection, (_) {
      // final collections = _controller.planExerciseCollection;
      _reloadWorkoutsTimer?.cancel();
      _reloadWorkoutsTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _reloadWorkouts();
        }
      });
    });

    // Lắng nghe thay đổi planMealCollection với debounce để tránh reload quá nhiều
    ever(_controller.planMealCollection, (_) {
      // final collections = _controller.planMealCollection;
      _reloadMealsTimer?.cancel();
      _reloadMealsTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _reloadMeals();
        }
      });
    });

    // Fallback: Reload sau 2 giây nếu chưa có dữ liệu
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && workouts.isEmpty && meals.isEmpty) {
        _reloadData();
      }
    });
  }

  void _loadInitialData() {
    workouts = _controller.loadWorkoutCollectionToShow(DateTime.now());
    allWorkouts = _controller.loadAllWorkoutCollection();

    _controller.loadMealListToShow(DateTime.now()).then((value) {
      if (mounted) {
        setState(() {
          meals = value;
        });
      }
    });
  }

  void _reloadData() {
    _reloadWorkouts();
    _reloadMeals();
  }

  void _reloadWorkouts() {
    if (!mounted) return;
    setState(() {
      workouts = _controller.loadWorkoutCollectionToShow(DateTime.now());
      allWorkouts = _controller.loadAllWorkoutCollection();
    });
  }

  void _reloadMeals() {
    if (!mounted) return;
    _controller.loadMealListToShow(DateTime.now()).then((value) {
      if (mounted) {
        setState(() {
          meals = value;
        });
      }
    });
    _controller.loadAllMealList().then((value) {
      if (mounted) {
        setState(() {
          allMeals = value;
        });
      }
    });
  }

  /// Thiết lập listeners để lắng nghe thay đổi từ DataService
  void _setupDataServiceListeners() {
    // Lắng nghe thay đổi mealList từ DataService
    ever(DataService.instance.mealListRx, (_) {
      _reloadMealsTimer?.cancel();
      _reloadMealsTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _reloadMeals();
        }
      });
    });

    // Lắng nghe thay đổi workoutList từ DataService
    ever(DataService.instance.workoutListRx, (_) {
      _reloadWorkoutsTimer?.cancel();
      _reloadWorkoutsTimer = Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _reloadWorkouts();
        }
      });
    });

    // Log đã tắt để tăng tốc độ
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TabBar(
            controller: _tabController,
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            onTap: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            labelStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
            unselectedLabelStyle:
                Theme.of(context).textTheme.titleSmall!.copyWith(
                      fontSize: 14,
                    ),
            tabs: const [
              Tab(
                text: 'Luyện tập',
              ),
              Tab(
                text: 'Ăn uống',
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Builder(builder: (_) {
          if (_selectedTabIndex == 0) {
            return Column(
              children: [
                ..._buildCollectionList(
                  workoutCollectionList: workouts,
                  elementOnPress: (col) async {
                    await _handleSelectExercise(col);
                  },
                ),
                Obx(() {
                  // Hiển thị nút nếu có dữ liệu workout (có thể từ default plan hoặc user plan)
                  if (allWorkouts.isNotEmpty ||
                      _controller.planExerciseCollection.isNotEmpty) {
                    // Lấy startDate từ workout plan nếu có, nếu không thì dùng ngày hiện tại
                    DateTime startDate =
                        _controller.currentWorkoutPlan.value?.startDate ??
                            DateTime.now();

                    return SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        child: Text(
                          'Xem tất cả các ngày',
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontSize: 16,
                                    color: AppColor.primaryColor,
                                  ),
                        ),
                        onPressed: () {
                          showCupertinoModalPopup(
                            context: context,
                            builder: (BuildContext context) {
                              return AllPlanExerciseScreen(
                                startDate: startDate,
                                workoutCollectionList: allWorkouts,
                                elementOnPress: (col) async {
                                  await _handleSelectExercise(col);
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          } else {
            return Obx(
              () => _controller.isTodayMealListLoading.value
                  ? const Padding(
                      padding: EdgeInsets.all(24.0), child: LoadingWidget())
                  : Column(
                      children: [
                        ..._buildNutritionList(
                          nutritionList: meals,
                          elementOnPress: (nutri) async {
                            await handleSelectMeal(nutri);
                          },
                        ),
                        Obx(() {
                          // Hiển thị nút nếu có dữ liệu meal (có thể từ default plan hoặc user plan)
                          if (allMeals.isNotEmpty ||
                              _controller.planMealCollection.isNotEmpty) {
                            // Lấy startDate từ workout plan nếu có, nếu không thì dùng ngày hiện tại
                            DateTime startDate = _controller
                                    .currentWorkoutPlan.value?.startDate ??
                                DateTime.now();

                            return SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                child: Text(
                                  'Xem tất cả các ngày',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
                                      .copyWith(
                                        fontSize: 16,
                                        color: AppColor.primaryColor,
                                      ),
                                ),
                                onPressed: () {
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AllPlanNutritionScreen(
                                        isLoading: false,
                                        nutritionList: allMeals,
                                        startDate: startDate,
                                        elementOnPress: (nutri) async {
                                          await handleSelectMeal(nutri);
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
            );
          }
        }),
      ],
    );
  }

  _handleSelectExercise(WorkoutCollection col) async {
    final _collectionController = Get.put(WorkoutCollectionController());
    _collectionController.useDefaulColSetting = false;

    // Đợi getCollectionSetting vì nó giờ là async
    CollectionSetting? colSetting =
        await _controller.getCollectionSetting(col.id ?? '');

    if (colSetting != null) {
      _collectionController.collectionSetting.value =
          CollectionSetting.fromCollectionSetting(colSetting);

      // Đảm bảo planExercise đã được load cho collection này
      // Nếu generatorIDs rỗng, load lại planExercise
      if (col.generatorIDs.isEmpty && col.id != null && col.id!.isNotEmpty) {
        await _controller.loadPlanExerciseList(col.id!);

        // Tạo lại WorkoutCollection với generatorIDs đã được load
        List<PlanExercise> exerciseList = _controller.planExercise
            .where((p0) => p0.listID == col.id)
            .toList();
        col = WorkoutCollection(
          col.id,
          title: col.title,
          description: col.description,
          asset: col.asset,
          generatorIDs: exerciseList
              .map((e) => e.exerciseID)
              .where((id) => id.isNotEmpty)
              .toList(),
          categoryIDs: col.categoryIDs,
        );
      }

      // Đợi load workout list xong trước khi navigate
      await _collectionController.onSelectUserCollection(col);
      await Get.toNamed(Routes.myWorkoutCollectionDetail);
      await Get.delete<WorkoutCollectionController>();
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomConfirmationDialog(
            icon: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.error_rounded,
                  color: AppColor.errorColor, size: 48),
            ),
            label: 'Đã xảy ra lỗi',
            content: 'Không tìm thấy cài đặt bộ luyện tập',
            showOkButton: false,
            labelCancel: 'Đóng',
            onCancel: () {
              Navigator.of(context).pop();
            },
            buttonsAlignment: MainAxisAlignment.center,
            buttonFactorOnMaxWidth: double.infinity,
          );
        },
      );
    }
  }

  handleSelectMeal(MealNutrition nutrition) async {
    Get.put(NutritionController());
    await Get.toNamed(Routes.dishDetail, arguments: nutrition);
    await Get.delete<NutritionController>();
  }

  _buildCollectionList(
      {required List<WorkoutCollection> workoutCollectionList,
      required Function(WorkoutCollection) elementOnPress}) {
    int collectionPerDay = 4;
    List<Widget> results = [];

    int count = workoutCollectionList.length;
    for (int i = 0; i < count; i++) {
      WorkoutCollection collection = workoutCollectionList[i];
      String cateList = DataService.instance.collectionCateList
          .where((item) => collection.categoryIDs.contains(item.id))
          .map((e) => e.name)
          .toString()
          .replaceAll(RegExp(r'\(|\)'), '');

      Widget collectionToWidget = Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ExerciseInCollectionTile(
            asset: collection.asset == ''
                ? JPGAssetString.userWorkoutCollection
                : collection.asset,
            title: collection.title,
            description: cateList,
            onPressed: () {
              elementOnPress(collection);
            }),
      );

      if (i % collectionPerDay == 0) {
        Widget dayIndicator = Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: AppColor.textFieldUnderlineColor,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const SizedBox(
                  //   height: 24,
                  // ),
                  Text(
                    'NGÀY ${i ~/ collectionPerDay + 1}',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColor.textColor.withOpacity(
                            AppColor.subTextOpacity,
                          ),
                        ),
                  ),
                  // const SizedBox(
                  //   height: 4,
                  // ),
                ],
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: AppColor.textFieldUnderlineColor,
                ),
              ),
            ],
          ),
        );

        results.add(dayIndicator);
      }

      results.add(collectionToWidget);
    }

    return results;
  }

  _buildNutritionList(
      {required List<MealNutrition> nutritionList,
      required Function(MealNutrition) elementOnPress}) {
    int collectionPerDay = 3;
    List<Widget> results = [];

    int count = nutritionList.length;
    for (int i = 0; i < count; i++) {
      Nutrition nutrition = nutritionList[i];

      Widget collectionToWidget = Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ExerciseInCollectionTile(
            asset: (nutrition as MealNutrition).meal.asset == ''
                ? JPGAssetString.meal
                : nutrition.meal.asset,
            title: nutrition.getName(),
            description: nutrition.calories.toStringAsFixed(0) + ' kcal',
            onPressed: () {
              elementOnPress(nutrition);
            }),
      );

      if (i % collectionPerDay == 0) {
        Widget dayIndicator = Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: AppColor.textFieldUnderlineColor,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // const SizedBox(
                  //   height: 24,
                  // ),
                  Text(
                    'NGÀY ${i ~/ collectionPerDay + 1}',
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColor.textColor.withOpacity(
                            AppColor.subTextOpacity,
                          ),
                        ),
                  ),
                  // const SizedBox(
                  //   height: 4,
                  // ),
                ],
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Divider(
                  thickness: 1,
                  color: AppColor.textFieldUnderlineColor,
                ),
              ),
            ],
          ),
        );

        results.add(dayIndicator);
      }

      results.add(collectionToWidget);
    }

    return results;
  }

  @override
  void dispose() {
    _reloadWorkoutsTimer?.cancel();
    _reloadMealsTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }
}
