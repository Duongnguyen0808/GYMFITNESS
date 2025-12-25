import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/collection_setting.dart';
import 'package:vipt/app/data/models/exercise_tracker.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/data/models/meal_nutrition_tracker.dart';
import 'package:vipt/app/data/models/plan_exercise.dart';
import 'package:vipt/app/data/models/plan_exercise_collection_setting.dart';
import 'package:vipt/app/data/models/plan_meal.dart';
import 'package:vipt/app/data/models/plan_meal_collection.dart';
import 'package:vipt/app/data/models/streak.dart';
import 'package:vipt/app/data/models/weight_tracker.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/models/workout_plan.dart';
import 'package:vipt/app/data/models/plan_exercise_collection.dart';
import 'package:vipt/app/data/others/tab_refesh_controller.dart';
import 'package:vipt/app/data/providers/exercise_nutrition_route_provider.dart';
import 'package:vipt/app/data/providers/exercise_track_provider.dart';
import 'package:vipt/app/data/providers/meal_nutrition_track_provider.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/providers/plan_exercise_collection_setting_provider_api.dart';
import 'package:vipt/app/data/providers/plan_exercise_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_provider_api.dart';
import 'package:vipt/app/data/providers/streak_provider.dart';
import 'package:vipt/app/data/providers/user_provider_api.dart';
import 'package:vipt/app/data/providers/weight_tracker_provider.dart';
import 'package:vipt/app/data/providers/plan_exercise_collection_provider_api.dart';
import 'package:vipt/app/data/providers/workout_plan_provider.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/enums/app_enums.dart';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/global_widgets/custom_confirmation_dialog.dart';
import 'package:vipt/app/routes/pages.dart';

class WorkoutPlanController extends GetxController {
  static const num defaultWeightValue = 0;
  static const WeightUnit defaultWeightUnit = WeightUnit.kg;
  static const int defaultCaloriesValue = 0;

  // --------------- LOG WEIGHT --------------------------------

  final _weighTrackProvider = WeightTrackerProvider();
  final _userProvider = UserProvider();
  Rx<num> currentWeight = defaultWeightValue.obs;
  Rx<num> goalWeight = defaultWeightValue.obs;
  WeightUnit weightUnit = defaultWeightUnit;

  String get unit => weightUnit == WeightUnit.kg ? 'kg' : 'lbs';

  Future<void> loadWeightValues() async {
    final _userInfo = DataService.currentUser;
    if (_userInfo == null) {
      return;
    }

    currentWeight.value = _userInfo.currentWeight;
    goalWeight.value = _userInfo.goalWeight;
    weightUnit = _userInfo.weightUnit;
  }

  Future<void> logWeight(String newWeightStr) async {
    int? newWeight = int.tryParse(newWeightStr);
    if (newWeight == null) {
      await showDialog(
        context: Get.context!,
        builder: (BuildContext context) {
          return CustomConfirmationDialog(
            icon: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.error_rounded,
                  color: AppColor.errorColor, size: 48),
            ),
            label: 'Đã xảy ra lỗi',
            content: 'Giá trị cân nặng không đúng định dạng',
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
      return;
    }

    currentWeight.value = newWeight;

    await _weighTrackProvider
        .add(WeightTracker(date: DateTime.now(), weight: newWeight));

    final _userInfo = DataService.currentUser;
    if (_userInfo != null) {
      _userInfo.currentWeight = newWeight;
      await _userProvider.update(_userInfo.id ?? '', _userInfo);
    }

    _markRelevantTabToUpdate();
  }

  // --------------- WORKOUT + MEAL PLAN --------------------------------
  final _nutriTrackProvider = MealNutritionTrackProvider();
  final _exerciseTrackProvider = ExerciseTrackProvider();
  final _workoutPlanProvider = WorkoutPlanProvider();
  final _wkExerciseCollectionProvider = PlanExerciseCollectionProvider();
  final _wkExerciseProvider = PlanExerciseProvider();
  final _colSettingProvider = PlanExerciseCollectionSettingProvider();
  final _wkMealCollectionProvider = PlanMealCollectionProvider();
  final _wkMealProvider = PlanMealProvider();

  RxBool isLoading = false.obs;

  RxInt intakeCalories = defaultCaloriesValue.obs;
  RxInt outtakeCalories = defaultCaloriesValue.obs;
  RxInt get dailyDiffCalories =>
      (intakeCalories.value - outtakeCalories.value).obs;
  RxInt dailyGoalCalories = defaultCaloriesValue.obs;
  
  // Mục tiêu calories tiêu hao hàng ngày
  RxInt dailyOuttakeGoalCalories = 0.obs;
  static const String outtakeGoalCaloriesKey = 'dailyOuttakeGoalCalories';

  // Chuyển thành RxList để UI tự động rebuild khi có thay đổi
  final RxList<PlanExerciseCollection> planExerciseCollection =
      <PlanExerciseCollection>[].obs;
  List<PlanExercise> planExercise = <PlanExercise>[];
  List<PlanExerciseCollectionSetting> collectionSetting =
      <PlanExerciseCollectionSetting>[];

  final RxList<PlanMealCollection> planMealCollection =
      <PlanMealCollection>[].obs;
  List<PlanMeal> planMeal = [];

  final Rx<WorkoutPlan?> currentWorkoutPlan = Rx<WorkoutPlan?>(null);

  RxBool isAllMealListLoading = false.obs;
  RxBool isTodayMealListLoading = false.obs;

  // Stream subscriptions cho real-time updates
  StreamSubscription<List<PlanExerciseCollection>>?
      _exerciseCollectionSubscription;
  StreamSubscription<List<PlanMealCollection>>? _mealCollectionSubscription;
  
  // Flag để tránh reload vòng lặp
  bool _isReloadingExerciseCollections = false;
  bool _isReloadingMealCollections = false;
  Timer? _reloadExerciseDebounceTimer;
  Timer? _reloadMealDebounceTimer;
  
  // Timer cho calories listeners
  Timer? _caloriesValidationTimer;
  Worker? _outtakeCaloriesWorker;
  Worker? _intakeCaloriesWorker;

  Future<void> loadDailyGoalCalories() async {
    WorkoutPlan? list = await _workoutPlanProvider
        .fetchByUserID(DataService.currentUser!.id ?? '');
    if (list != null) {
      currentWorkoutPlan.value = list;
      dailyGoalCalories.value = list.dailyGoalCalories.toInt();
    }
  }

  Future<void> loadPlanExerciseCollectionList(int planID) async {
    try {
      // Nếu planID = 0, chỉ load default collections
      if (planID == 0) {
        List<PlanExerciseCollection> defaultCollections =
            await _wkExerciseCollectionProvider.fetchByPlanID(0);

        if (defaultCollections.isNotEmpty) {
          defaultCollections.sort((a, b) => a.date.compareTo(b.date));
          planExerciseCollection.assignAll(defaultCollections);

          // Clear lists trước khi load để tránh duplicate
          planExercise.clear();
          collectionSetting.clear();

          for (int i = 0; i < defaultCollections.length; i++) {
            await loadCollectionSetting(
                defaultCollections[i].collectionSettingID);
            if (defaultCollections[i].id != null &&
                defaultCollections[i].id!.isNotEmpty) {
              await loadPlanExerciseList(defaultCollections[i].id!);
            }
          }
        }
      } else {
        // Nếu có user plan, chỉ load user collections
        List<PlanExerciseCollection> userCollections =
            await _wkExerciseCollectionProvider.fetchByPlanID(planID);

        if (userCollections.isNotEmpty) {
          // Sắp xếp theo ngày
          userCollections.sort((a, b) => a.date.compareTo(b.date));
          
          // Chỉ load collections trong khoảng thời gian của plan (từ startDate đến endDate)
          // Hoặc chỉ load 90 ngày gần nhất để tránh load quá nhiều
          DateTime now = DateTime.now();
          DateTime filterStartDate = currentWorkoutPlan.value?.startDate ?? now.subtract(const Duration(days: 90));
          DateTime filterEndDate = currentWorkoutPlan.value?.endDate ?? now.add(const Duration(days: 90));
          
          List<PlanExerciseCollection> filteredCollections = userCollections
              .where((col) => col.date.isAfter(filterStartDate.subtract(const Duration(days: 1))) &&
                             col.date.isBefore(filterEndDate.add(const Duration(days: 1))))
              .toList();
          
          // Giới hạn tối đa 90 collections để tránh load quá nhiều
          if (filteredCollections.length > 90) {
            filteredCollections = filteredCollections.sublist(0, 90);
          }
          
          planExerciseCollection.assignAll(filteredCollections);

          // Clear lists trước khi load để tránh duplicate
          planExercise.clear();
          collectionSetting.clear();

          // Load song song thay vì tuần tự để tăng tốc độ
          List<Future<void>> loadFutures = [];
          for (int i = 0; i < filteredCollections.length; i++) {
            final collection = filteredCollections[i];
            loadFutures.add(loadCollectionSetting(collection.collectionSettingID));
            if (collection.id != null && collection.id!.isNotEmpty) {
              loadFutures.add(loadPlanExerciseList(collection.id!));
            }
          }
          
          // Chờ tất cả load xong, nhưng với timeout để tránh block quá lâu
          try {
            await Future.wait(loadFutures).timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                return <void>[];
              },
            );
          } catch (e) {
            // Ignore errors
          }
        } else {
          // Nếu user plan không có collections, fallback về default
          List<PlanExerciseCollection> defaultCollections =
              await _wkExerciseCollectionProvider.fetchByPlanID(0);

          if (defaultCollections.isNotEmpty) {
            defaultCollections.sort((a, b) => a.date.compareTo(b.date));
            planExerciseCollection.assignAll(defaultCollections);

            // Clear lists trước khi load để tránh duplicate
            planExercise.clear();
            collectionSetting.clear();

            for (int i = 0; i < defaultCollections.length; i++) {
              await loadCollectionSetting(
                  defaultCollections[i].collectionSettingID);
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                await loadPlanExerciseList(defaultCollections[i].id!);
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      // Giữ lại list rỗng để app không crash
      planExerciseCollection.clear();
    }
  }

  Future<void> loadPlanExerciseList(String listID) async {
    // Xóa các planExercise cũ với listID này để tránh duplicate
    planExercise.removeWhere((element) => element.listID == listID);

    List<PlanExercise> _list = await _wkExerciseProvider.fetchByListID(listID);
    if (_list.isNotEmpty) {
      planExercise.addAll(_list);
    }
  }

  Future<void> loadCollectionSetting(String id) async {
    // Kiểm tra xem setting đã tồn tại chưa để tránh duplicate
    final existingIndex = collectionSetting.indexWhere((element) => element.id == id);
    if (existingIndex != -1) {
      // Đã tồn tại, không cần load lại
      return;
    }
    
    var _list = await _colSettingProvider.fetch(id);
    collectionSetting.add(_list);
  }

  Future<void> loadDailyCalories() async {
    final date = DateTime.now();
    final List<MealNutritionTracker> tracks =
        await _nutriTrackProvider.fetchByDate(date);
    final List<ExerciseTracker> exerciseTracks =
        await _exerciseTrackProvider.fetchByDate(date);

    outtakeCalories.value = 0;
    exerciseTracks.map((e) {
      outtakeCalories.value += e.outtakeCalories;
    }).toList();

    intakeCalories.value = 0;
    dailyDiffCalories.value = 0;

    tracks.map((e) {
      intakeCalories.value += e.intakeCalories;
    }).toList();

    dailyDiffCalories.value = intakeCalories.value - outtakeCalories.value;
    await _validateDailyCalories();
  }

  Future<void> _validateDailyCalories() async {
    if (currentWorkoutPlan.value == null) {
      return;
    }

    // Đảm bảo có mục tiêu calories tiêu hao
    if (dailyOuttakeGoalCalories.value == 0) {
      await loadOuttakeGoalCalories();
    }

    DateTime dateKey = DateUtils.dateOnly(DateTime.now());
    final _streakProvider = StreakProvider();
    List<Streak> streakList = await _streakProvider.fetchByDate(dateKey);
    
    // Tìm streak với planID khớp
    var matchingStreaks = streakList
        .where((element) => element.planID == currentWorkoutPlan.value!.id)
        .toList();

    Streak? todayStreak;
    
    if (matchingStreaks.isEmpty) {
      // Nếu chưa có streak cho ngày hôm nay, tạo mới
      todayStreak = Streak(
        date: dateKey,
        planID: currentWorkoutPlan.value!.id ?? 0,
        value: false,
      );
      todayStreak = await _streakProvider.add(todayStreak);
    } else {
      todayStreak = matchingStreaks.first;
    }

    bool todayStreakValue = todayStreak.value;

    // Số bên trái = tiêu hao - hấp thụ
    final leftValue = outtakeCalories.value - intakeCalories.value;
    final outtakeGoal = dailyOuttakeGoalCalories.value;
    
    // Kiểm tra nếu số bên trái >= mục tiêu calories tiêu hao
    if (outtakeGoal > 0 && leftValue >= outtakeGoal) {
      // Đã đạt mục tiêu
      if (!todayStreakValue) {
        Streak newStreak = Streak(
            date: todayStreak.date, planID: todayStreak.planID, value: true);
        await _streakProvider.update(todayStreak.id ?? 0, newStreak);
        // Reload plan streak để cập nhật UI
        await loadPlanStreak();
        update(); // Trigger UI update
      }
    } else {
      // Chưa đạt mục tiêu
      if (todayStreakValue) {
        Streak newStreak = Streak(
            date: todayStreak.date, planID: todayStreak.planID, value: false);
        await _streakProvider.update(todayStreak.id ?? 0, newStreak);
        // Reload plan streak để cập nhật UI
        await loadPlanStreak();
        update(); // Trigger UI update
      }
    }
  }

  List<WorkoutCollection> loadAllWorkoutCollection() {
    var collection = planExerciseCollection.toList();

    if (collection.isNotEmpty) {
      // Nhóm collections theo ngày
      Map<DateTime, List<PlanExerciseCollection>> collectionsByDate = {};
      for (var col in collection) {
        final dateKey = DateUtils.dateOnly(col.date);
        if (!collectionsByDate.containsKey(dateKey)) {
          collectionsByDate[dateKey] = [];
        }
        collectionsByDate[dateKey]!.add(col);
      }

      // Tạo danh sách WorkoutCollection theo thứ tự ngày
      List<WorkoutCollection> result = [];
      final sortedDates = collectionsByDate.keys.toList()..sort();

      for (var date in sortedDates) {
        final dayCollections = collectionsByDate[date]!;
        for (int i = 0; i < dayCollections.length; i++) {
          final col = dayCollections[i];
          List<PlanExercise> exerciseList =
              planExercise.where((p0) => p0.listID == col.id).toList();

          result.add(WorkoutCollection(col.id ?? '',
              title: 'Bài tập thứ ${i + 1}',
              description: '',
              asset: '',
              generatorIDs: exerciseList.map((e) => e.exerciseID).toList(),
              categoryIDs: []));
        }
      }

      return result;
    }
    return <WorkoutCollection>[];
  }

  List<WorkoutCollection> loadWorkoutCollectionToShow(DateTime date) {
    var collection = planExerciseCollection
        .where((element) => DateUtils.isSameDay(element.date, date))
        .toList();

    if (collection.isNotEmpty) {
      // Loại bỏ duplicate collections (cùng ID)
      final seenIds = <String>{};
      final uniqueCollections = <PlanExerciseCollection>[];
      for (var col in collection) {
        if (col.id != null && col.id!.isNotEmpty && !seenIds.contains(col.id)) {
          seenIds.add(col.id!);
          uniqueCollections.add(col);
        } else if (col.id == null || col.id!.isEmpty) {
          // Giữ lại collections không có ID (có thể là default)
          uniqueCollections.add(col);
        }
      }
      
      return uniqueCollections.asMap().entries.map((entry) {
        final index = entry.key;
        final col = entry.value;
        List<PlanExercise> exerciseList =
            planExercise.where((p0) => p0.listID == col.id).toList();

        return WorkoutCollection(col.id ?? '',
            title: 'Bài tập thứ ${index + 1}',
            description: '',
            asset: '',
            generatorIDs: exerciseList.map((e) => e.exerciseID).toList(),
            categoryIDs: []);
      }).toList();
    }

    return <WorkoutCollection>[];
  }

  Future<CollectionSetting?> getCollectionSetting(
      String workoutCollectionID) async {
    PlanExerciseCollection? selected = planExerciseCollection
        .firstWhereOrNull((p0) => p0.id == workoutCollectionID);

    if (selected == null) {
      return null;
    }

    // Tìm trong list hiện tại
    PlanExerciseCollectionSetting? setting = collectionSetting.firstWhereOrNull(
        (element) => element.id == selected.collectionSettingID);

    if (setting != null) {
      return setting;
    }

    // Nếu không tìm thấy, thử load lại từ Firestore
    try {
      await loadCollectionSetting(selected.collectionSettingID);
      setting = collectionSetting.firstWhereOrNull(
          (element) => element.id == selected.collectionSettingID);

      if (setting != null) {
        return setting;
      }
    } catch (e) {
      // Ignore errors
    }

    return null;
  }

  Future<void> loadWorkoutPlanMealList(int planID) async {
    try {
      // Nếu planID = 0, chỉ load default collections
      if (planID == 0) {
        List<PlanMealCollection> defaultCollections =
            await _wkMealCollectionProvider.fetchByPlanID(0);

        if (defaultCollections.isNotEmpty) {
          defaultCollections.sort((a, b) => a.date.compareTo(b.date));
          planMealCollection.assignAll(defaultCollections);

          planMeal.clear();

          for (int i = 0; i < defaultCollections.length; i++) {
            if (defaultCollections[i].id != null &&
                defaultCollections[i].id!.isNotEmpty) {
              await loadPlanMealList(defaultCollections[i].id!);
            }
          }
          update();
        }
      } else {
        // Nếu có user plan, chỉ load user collections
        List<PlanMealCollection> userCollections =
            await _wkMealCollectionProvider.fetchByPlanID(planID);

        if (userCollections.isNotEmpty) {
          // Sắp xếp theo ngày
          userCollections.sort((a, b) => a.date.compareTo(b.date));
          
          // Chỉ load collections trong khoảng thời gian hợp lý (30 ngày trước đến 60 ngày sau)
          DateTime now = DateTime.now();
          DateTime filterStartDate = now.subtract(const Duration(days: 30));
          DateTime filterEndDate = now.add(const Duration(days: 60));
          
          List<PlanMealCollection> filteredCollections = userCollections
              .where((col) => col.date.isAfter(filterStartDate.subtract(const Duration(days: 1))) &&
                             col.date.isBefore(filterEndDate.add(const Duration(days: 1))))
              .toList();
          
          // Giới hạn tối đa 90 collections để tránh load quá nhiều
          if (filteredCollections.length > 90) {
            filteredCollections = filteredCollections.sublist(0, 90);
          }
          
          planMealCollection.assignAll(filteredCollections);

          planMeal.clear();

          // Load song song để tăng tốc độ
          List<Future<void>> loadFutures = [];
          for (int i = 0; i < filteredCollections.length; i++) {
            if (filteredCollections[i].id != null &&
                filteredCollections[i].id!.isNotEmpty) {
              loadFutures.add(loadPlanMealList(filteredCollections[i].id!));
            }
          }
          
          // Chờ tất cả load xong, nhưng với timeout để tránh block quá lâu
          try {
            await Future.wait(loadFutures).timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                return <void>[];
              },
            );
          } catch (e) {
            // Ignore errors
          }
          
          update();
        } else {
          // Nếu user plan không có collections, fallback về default
          List<PlanMealCollection> defaultCollections =
              await _wkMealCollectionProvider.fetchByPlanID(0);

          if (defaultCollections.isNotEmpty) {
            defaultCollections.sort((a, b) => a.date.compareTo(b.date));
            planMealCollection.assignAll(defaultCollections);

            planMeal.clear();

            for (int i = 0; i < defaultCollections.length; i++) {
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                await loadPlanMealList(defaultCollections[i].id!);
              }
            }
            update();
          }
        }
      }
    } catch (e, stackTrace) {
      // Giữ lại list rỗng để app không crash
      planMealCollection.clear();
    }
  }

  Future<void> loadPlanMealList(String listID) async {
    List<PlanMeal> _list = await _wkMealProvider.fetchByListID(listID);
    if (_list.isNotEmpty) {
      planMeal.addAll(_list);
    }
  }

  Future<List<MealNutrition>> loadMealListToShow(DateTime date) async {
    isTodayMealListLoading.value = true;
    final firebaseMealProvider = MealProvider();
    var collection = planMealCollection
        .where((element) => DateUtils.isSameDay(element.date, date));
    if (collection.isEmpty) {
      isTodayMealListLoading.value = false;
      return [];
    } else {
      List<PlanMeal> _list = planMeal
          .where((element) => element.listID == (collection.first.id ?? ''))
          .toList();
      List<MealNutrition> mealList = [];
      for (var element in _list) {
        var m = await firebaseMealProvider.fetch(element.mealID);
        MealNutrition mn = MealNutrition(meal: m);
        await mn.getIngredients();
        mealList.add(mn);
      }

      isTodayMealListLoading.value = false;
      return mealList;
    }
  }

  Future<List<MealNutrition>> loadAllMealList() async {
    try {
      isAllMealListLoading.value = true;
      final firebaseMealProvider = MealProvider();

      if (planMealCollection.isEmpty && currentWorkoutPlan.value != null) {
        await loadWorkoutPlanMealList(currentWorkoutPlan.value!.id ?? 0);
      }

      var collection = planMealCollection.toList();

      if (collection.isEmpty) {
        isAllMealListLoading.value = false;
        return [];
      } else {
        List<MealNutrition> mealList = [];

        for (var mealCollection in collection) {
          List<PlanMeal> _list = planMeal
              .where((element) => element.listID == (mealCollection.id ?? ''))
              .toList();

          List<Future<MealNutrition?>> mealFutures = _list.map((element) async {
            try {
              var m = await firebaseMealProvider.fetch(element.mealID);
              MealNutrition mn = MealNutrition(meal: m);
              await mn.getIngredients();
              return mn;
            } catch (e) {
              if (e.toString().contains('permission-denied')) {
                return null;
              }
              return null;
            }
          }).toList();

          try {
            List<MealNutrition?> collectionMeals =
                await Future.wait(mealFutures);
            mealList.addAll(collectionMeals.whereType<MealNutrition>());
          } catch (e) {}
        }

        isAllMealListLoading.value = false;
        return mealList;
      }
    } catch (e) {
      isAllMealListLoading.value = false;
      return [];
    }
  }

  // --------------- STREAK --------------------------------
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  RxList<bool> planStreak = <bool>[].obs;
  RxInt currentStreakDay = 0.obs;
  static const String planStatus = 'planStatus';

  final _routeProvider = ExerciseNutritionRouteProvider();

  Future<void> loadPlanStreak() async {
    planStreak.clear();

    if (currentWorkoutPlan.value == null) {
      // Nếu không có workout plan, set về 0 và clear streak
      currentStreakDay.value = 0;
      planStreak.clear();
      return;
    }

    // Validate tất cả các ngày từ ngày bắt đầu đến hiện tại trước khi load
    await _validateAllStreaks();

    Map<int, List<bool>> list = await _routeProvider.loadStreakList();
    if (list.isNotEmpty) {
      currentStreakDay.value = list.keys.first;
      planStreak.assignAll(list.values.first); // Dùng assignAll thay vì addAll để trigger reactive update
    } else {
      // Nếu không có streak data, set về 0
      currentStreakDay.value = 0;
      planStreak.clear();
      return;
    }
    if (DateTime.now().isAfter(currentWorkoutPlan.value!.endDate)) {
      hasFinishedPlan.value = true;
      final _prefs = await prefs;
      _prefs.setBool(planStatus, true);

      await loadDataForFinishScreen();
      await Get.toNamed(Routes.finishPlanScreen);
    }
  }

  /// Validate tất cả các ngày từ ngày bắt đầu đến hiện tại để đảm bảo flame của các ngày đã đạt mục tiêu đều sáng
  Future<void> _validateAllStreaks() async {
    if (currentWorkoutPlan.value == null) {
      return;
    }

    // Đảm bảo có mục tiêu calories tiêu hao
    if (dailyOuttakeGoalCalories.value == 0) {
      await loadOuttakeGoalCalories();
    }

    final plan = currentWorkoutPlan.value!;
    final startDate = DateUtils.dateOnly(plan.startDate);
    final today = DateUtils.dateOnly(DateTime.now());
    final endDate = DateUtils.dateOnly(plan.endDate);
    
    // Chỉ validate từ ngày bắt đầu đến ngày hôm nay (hoặc ngày kết thúc nếu sớm hơn)
    final validateEndDate = today.isBefore(endDate) ? today : endDate;
    
    final _streakProvider = StreakProvider();
    final planID = plan.id ?? 0;
    final outtakeGoal = dailyOuttakeGoalCalories.value;
    
    if (outtakeGoal == 0) {
      return;
    }
    
    int updatedCount = 0;
    int currentDay = 0;
    
    while (!startDate.add(Duration(days: currentDay)).isAfter(validateEndDate)) {
      final checkDate = DateUtils.dateOnly(startDate.add(Duration(days: currentDay)));
      
      // Lấy streak cho ngày này
      List<Streak> streakList = await _streakProvider.fetchByDate(checkDate);
      var matchingStreaks = streakList
          .where((element) => element.planID == planID)
          .toList();
      
      Streak? dayStreak;
      bool isNewStreak = false;
      
      if (matchingStreaks.isEmpty) {
        // Tạo streak mới nếu chưa có
        dayStreak = Streak(
          date: checkDate,
          planID: planID,
          value: false,
        );
        dayStreak = await _streakProvider.add(dayStreak);
        isNewStreak = true;
      } else {
        dayStreak = matchingStreaks.first;
      }
      
      // Tính calories cho ngày này
      final List<MealNutritionTracker> tracks =
          await _nutriTrackProvider.fetchByDate(checkDate);
      final List<ExerciseTracker> exerciseTracks =
          await _exerciseTrackProvider.fetchByDate(checkDate);
      
      int intake = 0;
      int outtake = 0;
      
      tracks.forEach((e) {
        intake += e.intakeCalories;
      });
      
      exerciseTracks.forEach((e) {
        outtake += e.outtakeCalories;
      });
      
      final leftValue = outtake - intake;
      final shouldBeCompleted = leftValue >= outtakeGoal;
      
      // Cập nhật streak nếu cần
      if (dayStreak.value != shouldBeCompleted) {
        Streak newStreak = Streak(
          date: dayStreak.date,
          planID: dayStreak.planID,
          value: shouldBeCompleted,
        );
        await _streakProvider.update(dayStreak.id ?? 0, newStreak);
        updatedCount++;
      } else if (isNewStreak && shouldBeCompleted) {
        // Nếu streak mới tạo và đạt mục tiêu, cập nhật luôn
        Streak newStreak = Streak(
          date: dayStreak.date,
          planID: dayStreak.planID,
          value: true,
        );
        await _streakProvider.update(dayStreak.id ?? 0, newStreak);
        updatedCount++;
      }
      
      currentDay++;
    }
  }

  Future<void> loadPlanStatus() async {
    final _prefs = await prefs;
    hasFinishedPlan.value = _prefs.getBool(planStatus) ?? false;
  }

  // Load mục tiêu calories tiêu hao từ SharedPreferences
  // Nếu chưa có, tự động set mục tiêu mặc định
  Future<void> loadOuttakeGoalCalories() async {
    final _prefs = await prefs;
    final savedGoal = _prefs.getInt(outtakeGoalCaloriesKey);
    
    if (savedGoal != null && savedGoal > 0) {
      dailyOuttakeGoalCalories.value = savedGoal;
    } else {
      // Tự động set mục tiêu mặc định nếu chưa có
      final defaultGoal = AppValue.intensityWeight.toInt();
      await _prefs.setInt(outtakeGoalCaloriesKey, defaultGoal);
      dailyOuttakeGoalCalories.value = defaultGoal;
    }
  }

  // Lưu mục tiêu calories tiêu hao vào SharedPreferences
  Future<void> saveOuttakeGoalCalories(int goal) async {
    try {
      final _prefs = await prefs;
      await _prefs.setInt(outtakeGoalCaloriesKey, goal);
      // Cập nhật giá trị reactive - GetX sẽ tự động update tất cả Obx widgets đang listen
      dailyOuttakeGoalCalories.value = goal;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> showNotFoundStreakDataDialog() async {
    await showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return CustomConfirmationDialog(
          icon: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child:
                Icon(Icons.error_rounded, color: AppColor.errorColor, size: 48),
          ),
          label: 'Đã xảy ra lỗi',
          content: 'Không tìm thấy danh sách streak',
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

  Future<void> resetStreakList() async {
    try {
      isLoading.value = true;
      
      // Reset ngày về 0 trước khi reset route
      currentStreakDay.value = 0;
      planStreak.clear();
      
      // Reset route (xóa và tạo lại workout plan)
      await _routeProvider.resetRoute();
      
      // Đợi một chút để đảm bảo database đã commit streak
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Reload lại tất cả dữ liệu sau khi reset
      await loadPlanStatus();
      await loadDailyGoalCalories(); // Reload workout plan và update currentWorkoutPlan
      await loadOuttakeGoalCalories(); // Reload mục tiêu calories tiêu hao
      
      if (currentWorkoutPlan.value != null) {
        await loadDailyCalories();
        await loadPlanExerciseCollectionList(currentWorkoutPlan.value!.id ?? 0);
        await loadWorkoutPlanMealList(currentWorkoutPlan.value!.id ?? 0);
        await loadPlanStreak();
      } else {
        await loadDailyCalories();
        await loadPlanExerciseCollectionList(0);
        await loadWorkoutPlanMealList(0);
        // Nếu không có plan, set ngày về 0
        currentStreakDay.value = 0;
        planStreak.clear();
      }
      
      // Setup lại real-time listeners
      _setupRealtimeListeners();
      _setupCaloriesListeners();
      
      // Trigger UI update
      update();
      
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      rethrow;
    }
  }

  // --------------- FINISH WORKOUT PLAN--------------------------------
  static final DateTimeRange defaultWeightDateRange =
      DateTimeRange(start: DateTime.now(), end: DateTime.now());
  Rx<DateTimeRange> weightDateRange = defaultWeightDateRange.obs;
  RxList<WeightTracker> allWeightTracks = <WeightTracker>[].obs;
  final _weightProvider = WeightTrackerProvider();

  RxBool hasFinishedPlan = false.obs;

  Map<DateTime, double> get weightTrackList {
    allWeightTracks.sort((x, y) {
      return x.date.compareTo(y.date);
    });

    return allWeightTracks.length == 1 ? fakeMap() : convertToMap();
  }

  Map<DateTime, double> convertToMap() {
    return {for (var e in allWeightTracks) e.date: e.weight.toDouble()};
  }

  Map<DateTime, double> fakeMap() {
    var map = convertToMap();

    map.addAll(
        {allWeightTracks.first.date.subtract(const Duration(days: 1)): 0});

    return map;
  }

  Future<void> loadWeightTracks() async {
    if (currentWorkoutPlan.value == null) {
      return;
    }

    weightDateRange.value = DateTimeRange(
        start: currentWorkoutPlan.value!.startDate,
        end: currentWorkoutPlan.value!.endDate);
    allWeightTracks.clear();
    int duration = weightDateRange.value.duration.inDays + 1;
    for (int i = 0; i < duration; i++) {
      DateTime fetchDate = weightDateRange.value.start.add(Duration(days: i));
      var weighTracks = await _weightProvider.fetchByDate(fetchDate);
      weighTracks.sort((x, y) => x.weight - y.weight);
      if (weighTracks.isNotEmpty) {
        allWeightTracks.add(weighTracks.last);
      }
    }
  }

  Future<void> changeWeighDateRange(
      DateTime startDate, DateTime endDate) async {
    if (startDate.day == endDate.day &&
        startDate.month == endDate.month &&
        startDate.year == endDate.year) {
      startDate = startDate.subtract(const Duration(days: 1));
    }
    weightDateRange.value = DateTimeRange(start: startDate, end: endDate);
    await loadWeightTracks();
  }

  Future<void> loadDataForFinishScreen() async {
    await loadWeightTracks();
  }

  bool _hasInitialized = false;

  @override
  void onInit() async {
    super.onInit();
    
    // Tránh gọi onInit() nhiều lần
    if (_hasInitialized) {
      return;
    }
    
    _hasInitialized = true;
    isLoading.value = true;
    
    try {
      await loadPlanStatus();
      await loadWeightValues();
      await loadDailyGoalCalories();
      
      // Tự động tạo workout plan nếu user đã có dữ liệu nhưng chưa có plan
      if (currentWorkoutPlan.value == null) {
        await _autoCreateWorkoutPlanIfNeeded();
        // Load lại sau khi tạo plan (nếu có)
        if (currentWorkoutPlan.value != null) {
          await loadDailyGoalCalories();
        }
      }
      
      await loadOuttakeGoalCalories();

      if (currentWorkoutPlan.value != null) {
        // Load song song các dữ liệu không phụ thuộc nhau để tăng tốc độ
        try {
          await Future.wait([
            loadDailyCalories(),
            loadPlanExerciseCollectionList(currentWorkoutPlan.value!.id ?? 0),
            loadWorkoutPlanMealList(currentWorkoutPlan.value!.id ?? 0),
          ]).timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              return <void>[];
            },
          );
        } catch (e) {
          // Ignore errors
        }
        
        await loadPlanStreak();
      } else {
        await loadDailyCalories();
        
        // Load default collections ngay cả khi không có user plan
        await loadPlanExerciseCollectionList(0);
        await loadWorkoutPlanMealList(0);
      }

      isLoading.value = false;

      // Bắt đầu lắng nghe real-time changes từ Firestore
      _setupRealtimeListeners();
      
      // Lắng nghe thay đổi calories để tự động validate
      _setupCaloriesListeners();
      
      // Nếu không có workout plan, thử load lại sau một chút (có thể đang được tạo async)
      if (currentWorkoutPlan.value == null) {
        Future.delayed(const Duration(seconds: 2), () async {
          await loadDailyGoalCalories();
          if (currentWorkoutPlan.value != null) {
            await loadPlanExerciseCollectionList(currentWorkoutPlan.value!.id ?? 0);
            await loadWorkoutPlanMealList(currentWorkoutPlan.value!.id ?? 0);
            await loadPlanStreak();
            update();
          }
        });
      }
    } catch (e, stackTrace) {
      isLoading.value = false;
    }
  }
  
  /// Thiết lập listeners để tự động validate khi calories thay đổi
  void _setupCaloriesListeners() {
    // Hủy workers cũ nếu có
    _outtakeCaloriesWorker?.dispose();
    _intakeCaloriesWorker?.dispose();
    
    // Validate khi outtakeCalories hoặc intakeCalories thay đổi
    // Dùng ever với debounce thủ công để đảm bảo luôn hoạt động
    _outtakeCaloriesWorker = ever(outtakeCalories, (_) {
      _caloriesValidationTimer?.cancel();
      _caloriesValidationTimer = Timer(const Duration(milliseconds: 500), () {
        _validateDailyCalories();
      });
    });
    
    _intakeCaloriesWorker = ever(intakeCalories, (_) {
      _caloriesValidationTimer?.cancel();
      _caloriesValidationTimer = Timer(const Duration(milliseconds: 500), () {
        _validateDailyCalories();
      });
    });
    
    // Validate ngay sau khi setup listeners để kiểm tra trạng thái hiện tại
    Future.delayed(const Duration(milliseconds: 600), () {
      _validateDailyCalories();
    });
  }

  /// Thiết lập listeners để lắng nghe thay đổi real-time từ Firestore
  void _setupRealtimeListeners() {
    // Cancel old subscriptions nếu có
    _exerciseCollectionSubscription?.cancel();
    _mealCollectionSubscription?.cancel();

    int planID = currentWorkoutPlan.value?.id ?? 0;

    // Lắng nghe thay đổi plan exercise collections
    _exerciseCollectionSubscription =
        _wkExerciseCollectionProvider.streamByPlanID(planID).listen(
      (collections) {
        // Debounce để tránh reload quá nhiều lần
        _reloadExerciseDebounceTimer?.cancel();
        _reloadExerciseDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isReloadingExerciseCollections) {
            _reloadExerciseCollections();
          }
        });
      },
      onError: (error) {
        // Ignore errors
      },
    );

    // Lắng nghe thay đổi plan meal collections
    _mealCollectionSubscription =
        _wkMealCollectionProvider.streamByPlanID(planID).listen(
      (collections) {
        // Debounce để tránh reload quá nhiều lần
        _reloadMealDebounceTimer?.cancel();
        _reloadMealDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isReloadingMealCollections) {
            _reloadMealCollections();
          }
        });
      },
      onError: (error) {
        // Ignore errors
      },
    );

    // Cũng lắng nghe default plan (planID = 0) để cập nhật khi admin thay đổi
    // Luôn luôn lắng nghe để reload khi có bài tập mới được tạo
    _wkExerciseCollectionProvider.streamByPlanID(0).listen(
      (collections) {
        // Luôn luôn reload khi có thay đổi từ default plan (planID = 0)
        // vì các bài tập mới được tạo ở đây
        _reloadExerciseDebounceTimer?.cancel();
        _reloadExerciseDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isReloadingExerciseCollections) {
            _reloadExerciseCollections();
          }
        });
      },
      onError: (error) {
        // Ignore errors
      },
    );

    _wkMealCollectionProvider.streamByPlanID(0).listen(
      (collections) {
        // Luôn luôn reload khi có thay đổi từ default meal plan (planID = 0)
        _reloadMealDebounceTimer?.cancel();
        _reloadMealDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          if (!_isReloadingMealCollections) {
            _reloadMealCollections();
          }
        });
      },
      onError: (error) {
        // Ignore errors
      },
    );
  }

  /// Reload exercise collections khi có thay đổi từ Firestore
  Future<void> _reloadExerciseCollections() async {
    if (_isReloadingExerciseCollections) {
      return;
    }
    
    _isReloadingExerciseCollections = true;
    try {
      int planID = currentWorkoutPlan.value?.id ?? 0;
      await loadPlanExerciseCollectionList(planID);
      // Trigger UI update
      update();
    } finally {
      _isReloadingExerciseCollections = false;
    }
  }

  /// Reload meal collections khi có thay đổi từ Firestore
  Future<void> _reloadMealCollections() async {
    if (_isReloadingMealCollections) {
      return;
    }
    
    _isReloadingMealCollections = true;
    try {
      int planID = currentWorkoutPlan.value?.id ?? 0;
      await loadWorkoutPlanMealList(planID);
      // Trigger UI update
      update();
    } finally {
      _isReloadingMealCollections = false;
    }
  }

  @override
  void onClose() {
    // Cancel tất cả subscriptions và timers khi controller bị dispose
    _exerciseCollectionSubscription?.cancel();
    _mealCollectionSubscription?.cancel();
    _reloadExerciseDebounceTimer?.cancel();
    _reloadMealDebounceTimer?.cancel();
    _caloriesValidationTimer?.cancel();
    _outtakeCaloriesWorker?.dispose();
    _intakeCaloriesWorker?.dispose();
    super.onClose();
  }

  void _markRelevantTabToUpdate() {
    if (!RefeshTabController.instance.isProfileTabNeedToUpdate) {
      RefeshTabController.instance.toggleProfileTabUpdate();
    }
  }
  
  /// Tự động tạo workout plan nếu user đã có dữ liệu nhưng chưa có plan
  Future<void> _autoCreateWorkoutPlanIfNeeded() async {
    try {
      // Kiểm tra xem user đã có dữ liệu chưa
      if (DataService.currentUser == null) {
        return;
      }
      
      final user = DataService.currentUser!;
      
      // Kiểm tra xem user đã có đủ thông tin để tạo workout plan chưa
      if (user.currentWeight == 0 || user.goalWeight == 0 || user.currentHeight == 0) {
        return;
      }
      
      // Kiểm tra lại xem có workout plan chưa (có thể đã được tạo trong lúc này)
      final existingPlan = await _workoutPlanProvider.fetchByUserID(user.id ?? '');
      if (existingPlan != null) {
        currentWorkoutPlan.value = existingPlan;
        return;
      }
      
      // Đảm bảo dữ liệu cần thiết đã được load
      await DataService.instance.loadWorkoutList();
      await DataService.instance.loadMealList();
      await DataService.instance.loadMealCategoryList();
      
      // Tạo workout plan
      await _routeProvider.createRoute(user);
      
      // Load lại workout plan vừa tạo
      final newPlan = await _workoutPlanProvider.fetchByUserID(user.id ?? '');
      if (newPlan != null) {
        currentWorkoutPlan.value = newPlan;
        dailyGoalCalories.value = newPlan.dailyGoalCalories.toInt();
      }
    } catch (e, stackTrace) {
      // Không throw error để app vẫn tiếp tục hoạt động
    }
  }
}
