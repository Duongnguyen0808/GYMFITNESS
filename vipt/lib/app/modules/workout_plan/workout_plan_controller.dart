import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipt/app/core/utilities/utils.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/collection_setting.dart';
import 'package:vipt/app/data/models/exercise_tracker.dart';
import 'package:vipt/app/data/models/meal.dart';
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
import 'package:vipt/app/data/services/api_client.dart';

// Tắt log để tăng tốc độ - chỉ bật khi cần debug
const bool _enableLogging = false;
void _log(String message) {
  if (_enableLogging && kDebugMode) {
    print(message);
  }
}

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

  RxInt dailyOuttakeGoalCalories = 0.obs; // Sẽ được tính từ thông tin user
  static const String outtakeGoalCaloriesKey =
      'dailyOuttakeGoalCalories_v2'; // Đổi key để reset

  final RxList<PlanExerciseCollection> planExerciseCollection =
      <PlanExerciseCollection>[].obs;
  List<PlanExercise> planExercise = <PlanExercise>[];
  List<PlanExerciseCollectionSetting> collectionSetting =
      <PlanExerciseCollectionSetting>[];

  final RxList<PlanMealCollection> planMealCollection =
      <PlanMealCollection>[].obs;
  List<PlanMeal> planMeal = [];

  // Thêm cache để tránh load đi load lại API ingredients
  final Map<String, MealNutrition> _cachedMealNutritions = {};

  final Rx<WorkoutPlan?> currentWorkoutPlan = Rx<WorkoutPlan?>(null);

  RxBool isAllMealListLoading = false.obs;
  RxBool isTodayMealListLoading = false.obs;
  RxBool isRefreshing = false.obs;

  StreamSubscription<List<PlanExerciseCollection>>?
      _exerciseCollectionSubscription;
  StreamSubscription<List<PlanMealCollection>>? _mealCollectionSubscription;

  Worker? _mealListWorker;
  Worker? _workoutListWorker;
  Worker? _planExerciseCollectionWorker;
  Worker? _planMealCollectionWorker;

  bool _isReloadingExerciseCollections = false;
  bool _isReloadingMealCollections = false;
  Timer? _reloadExerciseDebounceTimer;
  Timer? _reloadMealDebounceTimer;

  Timer? _caloriesValidationTimer;
  Worker? _outtakeCaloriesWorker;
  Worker? _intakeCaloriesWorker;

  Timer? _dateCheckTimer;
  DateTime? _lastCheckedDate;

  Future<void> loadDailyGoalCalories() async {
    WorkoutPlan? list = await _workoutPlanProvider
        .fetchByUserID(DataService.currentUser!.id ?? '');
    if (list != null) {
      currentWorkoutPlan.value = list;
      dailyGoalCalories.value = list.dailyGoalCalories.toInt();
    }
  }

  // ... [Giữ nguyên code loadPlanExerciseCollectionList, loadPlanExerciseList, loadCollectionSetting, loadDailyCalories, checkAndReset, validateDailyCalories, loadAllWorkoutCollection, loadWorkoutCollectionToShow, getCollectionSetting] ...
  // Để tiết kiệm không gian, tôi chỉ liệt kê phần thay đổi quan trọng bên dưới. Các hàm trên bạn giữ nguyên.

  // (Paste lại các hàm trên nếu bạn copy-paste toàn bộ file, hoặc chỉ thay đổi từ phần loadWorkoutPlanMealList trở xuống)
  // Tuy nhiên, để đảm bảo tính toàn vẹn, tôi sẽ include các hàm trên ở dạng rút gọn (giữ nguyên logic cũ của bạn ở các hàm exercise, chỉ sửa phần meal).

  Future<void> loadPlanExerciseCollectionList(int planID,
      {bool lightLoad = false}) async {
    _log(
        '📦 loadPlanExerciseCollectionList: planID=$planID, lightLoad=$lightLoad');
    try {
      DateTime now = DateTime.now();
      DateTime filterStartDate = now.subtract(const Duration(days: 30));
      DateTime filterEndDate = now.add(const Duration(days: 30));

      final response = await ApiClient.instance.get(
        '/plan-exercises/collections',
        queryParams: {'planID': planID.toString()},
      );

      final List<dynamic> collectionsData = response['data'] ?? [];
      _log('📦 API trả về ${collectionsData.length} collections');

      collectionSetting.clear();
      List<PlanExerciseCollection> allCollections = [];

      for (var json in collectionsData) {
        var col =
            PlanExerciseCollection.fromMap(json['_id'] ?? json['id'], json);
        allCollections.add(col);

        if (json['setting'] != null) {
          try {
            var settingJson = json['setting'];
            var setting = PlanExerciseCollectionSetting.fromMap(
                settingJson['_id'] ?? settingJson['id'], settingJson);

            if (!collectionSetting.any((s) => s.id == setting.id)) {
              collectionSetting.add(setting);
            }
          } catch (e) {
            _log('⚠️ Lỗi parse setting: $e');
          }
        }
      }

      _log(
          '📦 Đã parse ${allCollections.length} collections, ${collectionSetting.length} settings');

      if (allCollections.isEmpty && planID != 0) {
        _log('📦 Không có collections cho planID=$planID, thử load planID=0');
        await loadPlanExerciseCollectionList(0, lightLoad: lightLoad);
        return;
      }

      if (allCollections.isNotEmpty) {
        List<PlanExerciseCollection> filteredCollections = allCollections
            .where((col) =>
                col.date.isAfter(
                    filterStartDate.subtract(const Duration(days: 1))) &&
                col.date.isBefore(filterEndDate.add(const Duration(days: 1))))
            .toList();

        _log(
            '📦 Sau khi filter theo ngày: ${filteredCollections.length} collections');

        filteredCollections.sort((a, b) => a.date.compareTo(b.date));

        if (lightLoad) {
          if (filteredCollections.length > 7) {
            filteredCollections = filteredCollections.sublist(0, 7);
          }
        } else {
          if (filteredCollections.length > 60) {
            filteredCollections = filteredCollections.sublist(0, 60);
          }
        }

        planExerciseCollection.assignAll(filteredCollections);
        _log(
            '📦 planExerciseCollection.length = ${planExerciseCollection.length}');
        _log('📦 IDs: ${planExerciseCollection.map((c) => c.id).toList()}');

        planExercise.clear();

        try {
          final exerciseResponse = await ApiClient.instance.get(
            '/plan-exercises',
            queryParams: {'planID': planID.toString()},
          );

          final List<dynamic> exercisesData = exerciseResponse['data'] ?? [];

          final List<PlanExercise> allExercises = exercisesData.map((json) {
            String exerciseID;
            if (json['exerciseID'] is Map) {
              exerciseID =
                  json['exerciseID']['_id'] ?? json['exerciseID']['id'] ?? '';
            } else {
              exerciseID = json['exerciseID']?.toString() ?? '';
            }
            return PlanExercise.fromMap(json['_id'] ?? json['id'], {
              ...json,
              'exerciseID': exerciseID,
            });
          }).toList();

          planExercise.addAll(allExercises);
        } catch (e) {
          _log('❌ Lỗi tải bulk exercises: $e');
        }
      } else {
        planExerciseCollection.clear();
        planExercise.clear();
        collectionSetting.clear();
      }
    } catch (e) {
      _log('❌ Lỗi khi load plan exercise collections: $e');
      planExerciseCollection.clear();
    }
  }

  Future<void> loadPlanExerciseList(String listID) async {
    if (listID.isEmpty) {
      _log('⚠️ loadPlanExerciseList: listID rỗng');
      return;
    }

    planExercise.removeWhere((element) => element.listID == listID);
    try {
      List<PlanExercise> _list =
          await _wkExerciseProvider.fetchByListID(listID);
      if (_list.isNotEmpty) {
        planExercise.addAll(_list);
        _log('✅ Đã load ${_list.length} exercises cho listID: $listID');
      } else {
        _log('⚠️ Không tìm thấy exercises cho listID: $listID');
      }
    } catch (e) {
      _log('❌ Lỗi khi load exercises cho listID $listID: $e');
    }
  }

  Future<void> loadCollectionSetting(String id) async {
    if (collectionSetting.any((element) => element.id == id)) return;
    if (id.isEmpty) return;
    try {
      var setting = await _colSettingProvider.fetch(id);
      collectionSetting.add(setting);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> loadDailyCalories() async {
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);

    if (_lastCheckedDate != null && _lastCheckedDate != today) {
      _log('📅 Đã qua ngày mới, reset calories về 0');
    }

    _lastCheckedDate = today;

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

  void _checkAndResetIfNewDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastCheckedDate == null || _lastCheckedDate != today) {
      _log(
          '📅 Phát hiện ngày mới, tự động reset calories và validate lại streaks');
      loadDailyCalories().then((_) {
        loadPlanStreak();
      });
    }
  }

  Future<void> _validateDailyCalories() async {
    if (currentWorkoutPlan.value == null) {
      return;
    }

    if (dailyOuttakeGoalCalories.value == 0) {
      await loadOuttakeGoalCalories();
    }

    DateTime dateKey = DateUtils.dateOnly(DateTime.now());
    final _streakProvider = StreakProvider();
    List<Streak> streakList = await _streakProvider.fetchByDate(dateKey);

    var matchingStreaks = streakList
        .where((element) => element.planID == currentWorkoutPlan.value!.id)
        .toList();

    Streak? todayStreak;

    if (matchingStreaks.isEmpty) {
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

    // Logic mới: Cứ có tập luyện (outtakeCalories > 0) là được tính streak
    // Không cần đạt mục tiêu, chỉ cần có bài tập
    final hasExercisedToday = outtakeCalories.value > 0;

    if (hasExercisedToday) {
      // Đã tập hôm nay -> streak = true
      if (!todayStreakValue) {
        Streak newStreak = Streak(
            date: todayStreak.date, planID: todayStreak.planID, value: true);
        await _streakProvider.update(todayStreak.id ?? 0, newStreak);
        _log('🔥 Streak hôm nay = TRUE (đã tập ${outtakeCalories.value} calo)');
        await loadPlanStreak();
        update();
      }
    } else {
      // Chưa tập hôm nay -> streak = false
      if (todayStreakValue) {
        Streak newStreak = Streak(
            date: todayStreak.date, planID: todayStreak.planID, value: false);
        await _streakProvider.update(todayStreak.id ?? 0, newStreak);
        _log('⚪ Streak hôm nay = FALSE (chưa tập)');
        await loadPlanStreak();
        update();
      }
    }
  }

  List<WorkoutCollection> loadAllWorkoutCollection() {
    var collection = planExerciseCollection.toList();

    if (collection.isNotEmpty) {
      Map<DateTime, List<PlanExerciseCollection>> collectionsByDate = {};
      for (var col in collection) {
        final dateKey = DateUtils.dateOnly(col.date);
        if (!collectionsByDate.containsKey(dateKey)) {
          collectionsByDate[dateKey] = [];
        }
        collectionsByDate[dateKey]!.add(col);
      }

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
      final seenIds = <String>{};
      final uniqueCollections = <PlanExerciseCollection>[];
      for (var col in collection) {
        if (col.id != null && col.id!.isNotEmpty && !seenIds.contains(col.id)) {
          seenIds.add(col.id!);
          uniqueCollections.add(col);
        } else if (col.id == null || col.id!.isEmpty) {
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
    _log('🔍 getCollectionSetting: workoutCollectionID = $workoutCollectionID');
    _log('🔍 planExerciseCollection.length = ${planExerciseCollection.length}');

    PlanExerciseCollection? selected = planExerciseCollection
        .firstWhereOrNull((p0) => p0.id == workoutCollectionID);

    _log('🔍 selected = $selected');

    if (selected == null) {
      _log('❌ Không tìm thấy collection với ID: $workoutCollectionID');
      // Log tất cả collection IDs để debug
      _log(
          '🔍 Các collection IDs hiện có: ${planExerciseCollection.map((c) => c.id).toList()}');
      return null;
    }

    _log('🔍 selected.collectionSettingID = ${selected.collectionSettingID}');
    _log('🔍 collectionSetting.length = ${collectionSetting.length}');

    PlanExerciseCollectionSetting? setting = collectionSetting.firstWhereOrNull(
        (element) => element.id == selected.collectionSettingID);

    if (setting != null) {
      _log('✅ Tìm thấy setting trong cache');
      return setting;
    }

    try {
      _log('🔍 Đang load setting từ API...');
      await loadCollectionSetting(selected.collectionSettingID);
      setting = collectionSetting.firstWhereOrNull(
          (element) => element.id == selected.collectionSettingID);

      if (setting != null) {
        _log('✅ Đã load setting từ API');
        return setting;
      }
    } catch (e) {
      _log('❌ Lỗi load setting: $e');
    }

    _log('❌ Không tìm thấy setting');
    return null;
  }

  // --- SỬA ĐỔI QUAN TRỌNG: Tối ưu Load Plan Meal để tránh mất dữ liệu ---
  Future<void> loadWorkoutPlanMealList(int planID,
      {bool lightLoad = false}) async {
    try {
      if (planID == 0) {
        List<PlanMealCollection> defaultCollections =
            await _wkMealCollectionProvider.fetchByPlanID(0);

        if (defaultCollections.isNotEmpty) {
          defaultCollections.sort((a, b) => a.date.compareTo(b.date));

          if (lightLoad && defaultCollections.length > 7) {
            defaultCollections = defaultCollections.sublist(0, 7);
          }

          planMealCollection.assignAll(defaultCollections);

          // FIX: Sử dụng danh sách tạm để tránh UI bị trắng xóa
          List<PlanMeal> tempPlanMeals = [];

          if (lightLoad) {
            for (int i = 0; i < defaultCollections.length; i++) {
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                // Load dữ liệu vào list tạm
                List<PlanMeal> meals = await _wkMealProvider
                    .fetchByListID(defaultCollections[i].id!);
                tempPlanMeals.addAll(meals);
              }
            }
          } else {
            for (int i = 0; i < defaultCollections.length; i++) {
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                List<PlanMeal> meals = await _wkMealProvider
                    .fetchByListID(defaultCollections[i].id!);
                tempPlanMeals.addAll(meals);
              }
            }
          }
          // Sau khi load xong mới gán vào biến chính
          planMeal = tempPlanMeals;
          update();
        }
      } else {
        List<PlanMealCollection> userCollections =
            await _wkMealCollectionProvider.fetchByPlanID(planID);

        if (userCollections.isNotEmpty) {
          userCollections.sort((a, b) => a.date.compareTo(b.date));

          DateTime now = DateTime.now();
          DateTime filterStartDate = now.subtract(const Duration(days: 30));
          DateTime filterEndDate = now.add(const Duration(days: 60));

          List<PlanMealCollection> filteredCollections = userCollections
              .where((col) =>
                  col.date.isAfter(
                      filterStartDate.subtract(const Duration(days: 1))) &&
                  col.date.isBefore(filterEndDate.add(const Duration(days: 1))))
              .toList();

          if (lightLoad) {
            if (filteredCollections.length > 7) {
              filteredCollections = filteredCollections.sublist(0, 7);
            }
          } else {
            if (filteredCollections.length > 90) {
              filteredCollections = filteredCollections.sublist(0, 90);
            }
          }

          planMealCollection.assignAll(filteredCollections);

          // FIX: Sử dụng danh sách tạm
          List<PlanMeal> tempPlanMeals = [];

          if (lightLoad) {
            const int batchSize = 3;
            for (int batchStart = 0;
                batchStart < filteredCollections.length;
                batchStart += batchSize) {
              int batchEnd =
                  (batchStart + batchSize < filteredCollections.length)
                      ? batchStart + batchSize
                      : filteredCollections.length;

              List<Future<List<PlanMeal>>> batchFutures = [];
              for (int i = batchStart; i < batchEnd; i++) {
                if (filteredCollections[i].id != null &&
                    filteredCollections[i].id!.isNotEmpty) {
                  batchFutures.add(_wkMealProvider
                      .fetchByListID(filteredCollections[i].id!));
                }
              }

              try {
                // Đợi load batch
                List<List<PlanMeal>> results =
                    await Future.wait(batchFutures).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    _log(
                        '⚠️ Timeout khi load meal batch ${batchStart}-${batchEnd}');
                    return [];
                  },
                );
                for (var list in results) {
                  tempPlanMeals.addAll(list);
                }
              } catch (e) {
                _log('⚠️ Lỗi khi load meal batch: $e');
              }
            }
          } else {
            List<Future<List<PlanMeal>>> loadFutures = [];
            for (int i = 0; i < filteredCollections.length; i++) {
              if (filteredCollections[i].id != null &&
                  filteredCollections[i].id!.isNotEmpty) {
                loadFutures.add(
                    _wkMealProvider.fetchByListID(filteredCollections[i].id!));
              }
            }

            try {
              List<List<PlanMeal>> results =
                  await Future.wait(loadFutures).timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  return [];
                },
              );
              for (var list in results) {
                tempPlanMeals.addAll(list);
              }
            } catch (e) {
              // Ignore errors
            }
          }

          // Cập nhật một lần duy nhất sau khi load xong (hoặc gần xong)
          planMeal = tempPlanMeals;
          update();
        } else {
          // Fallback to default
          List<PlanMealCollection> defaultCollections =
              await _wkMealCollectionProvider.fetchByPlanID(0);

          if (defaultCollections.isNotEmpty) {
            defaultCollections.sort((a, b) => a.date.compareTo(b.date));
            planMealCollection.assignAll(defaultCollections);

            List<PlanMeal> tempPlanMeals = [];
            for (int i = 0; i < defaultCollections.length; i++) {
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                List<PlanMeal> meals = await _wkMealProvider
                    .fetchByListID(defaultCollections[i].id!);
                tempPlanMeals.addAll(meals);
              }
            }
            planMeal = tempPlanMeals;
            update();
          }
        }
      }
    } catch (e) {
      planMealCollection.clear();
    }
  }

  // Hàm loadPlanMealList cũ vẫn giữ để tương thích nếu có nơi khác dùng,
  // nhưng logic chính trong loadWorkoutPlanMealList đã được nhúng trực tiếp để tối ưu.
  Future<void> loadPlanMealList(String listID) async {
    List<PlanMeal> _list = await _wkMealProvider.fetchByListID(listID);
    if (_list.isNotEmpty) {
      planMeal.addAll(_list);
    }
  }

  // --- SỬA ĐỔI QUAN TRỌNG: Tối ưu Load Meal List để tránh Spam API ---
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
        String mealId = element.mealID;

        // CHECK CACHE TRƯỚC
        if (_cachedMealNutritions.containsKey(mealId)) {
          mealList.add(_cachedMealNutritions[mealId]!);
          continue; // Bỏ qua loop hiện tại, đi tiếp
        }

        // NẾU CHƯA CÓ TRONG CACHE, KIỂM TRA DATASERVICE (RAM)
        try {
          // Tìm trong list đã load sẵn của app
          Meal? existingMeal = DataService.instance.mealList.firstWhereOrNull(
            (m) => m.id == mealId,
          );

          if (existingMeal != null) {
            // Nếu có trong RAM, dùng luôn, chỉ fetch ingredients
            MealNutrition mn = MealNutrition(meal: existingMeal);
            await mn.getIngredients();

            // Lưu vào cache
            _cachedMealNutritions[mealId] = mn;
            mealList.add(mn);
          } else {
            // Nếu không có trong RAM, mới gọi API Fetch Meal
            var m = await firebaseMealProvider.fetch(mealId);
            MealNutrition mn = MealNutrition(meal: m);
            await mn.getIngredients();

            // Lưu vào cache
            _cachedMealNutritions[mealId] = mn;
            mealList.add(mn);
          }
        } catch (e) {
          _log('⚠️ Lỗi load meal detail $mealId: $e');
        }
      }

      isTodayMealListLoading.value = false;
      return mealList;
    }
  }

  // --- SỬA ĐỔI TƯƠNG TỰ CHO loadAllMealList ---
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

          for (var element in _list) {
            String mealId = element.mealID;

            // Check cache
            if (_cachedMealNutritions.containsKey(mealId)) {
              mealList.add(_cachedMealNutritions[mealId]!);
              continue;
            }

            try {
              Meal? existingMeal =
                  DataService.instance.mealList.firstWhereOrNull(
                (m) => m.id == mealId,
              );

              if (existingMeal != null) {
                MealNutrition mn = MealNutrition(meal: existingMeal);
                await mn.getIngredients();
                _cachedMealNutritions[mealId] = mn;
                mealList.add(mn);
              } else {
                var m = await firebaseMealProvider.fetch(mealId);
                MealNutrition mn = MealNutrition(meal: m);
                await mn.getIngredients();
                _cachedMealNutritions[mealId] = mn;
                mealList.add(mn);
              }
            } catch (e) {
              // Ignore or log
            }
          }
        }

        isAllMealListLoading.value = false;
        return mealList;
      }
    } catch (e) {
      isAllMealListLoading.value = false;
      return [];
    }
  }

  // --------------- STREAK (LOGIC CHÍNH XÁC 100%) --------------------------------
  Future<SharedPreferences> prefs = SharedPreferences.getInstance();
  RxList<bool> planStreak = <bool>[].obs;
  RxInt currentStreakDay = 0.obs;
  RxInt currentDayNumber = 0.obs;
  static const String planStatus = 'planStatus';
  static const String lastStreakLossNotificationDateKey =
      'lastStreakLossNotificationDate';

  final _routeProvider = ExerciseNutritionRouteProvider();

  // Hàm này tính ngày hiển thị dựa trên chuỗi liên tiếp
  // TỐI ƯU: Chỉ load streak list, không validate từng ngày khi khởi động
  Future<void> loadPlanStreak() async {
    planStreak.clear();

    if (currentWorkoutPlan.value == null) {
      currentStreakDay.value = 0;
      currentDayNumber.value = 0;
      planStreak.clear();
      return;
    }

    // Chỉ load streak list, KHÔNG validate để tránh gọi nhiều API
    // Việc validate sẽ được thực hiện khi user hoàn thành bài tập
    Map<int, List<bool>> list = await _routeProvider.loadStreakList();
    if (list.isNotEmpty) {
      planStreak.assignAll(list.values.first);

      final plan = currentWorkoutPlan.value!;
      final startDate = DateUtils.dateOnly(plan.startDate);
      final today = DateUtils.dateOnly(DateTime.now());
      int todayIndex = today.difference(startDate).inDays;

      // LOGIC TÍNH TOÁN NGÀY HIỆN TẠI (FLAME)
      int calculatedDay = 1; // Mặc định là ngày 1

      if (todayIndex >= 0 && todayIndex < planStreak.length) {
        if (planStreak[todayIndex] == true) {
          // Trường hợp 1: Hôm nay ĐÃ tập (True)
          int streakCount = 0;
          for (int i = todayIndex; i >= 0; i--) {
            if (planStreak[i])
              streakCount++;
            else
              break;
          }
          calculatedDay = streakCount;
        } else {
          // Trường hợp 2: Hôm nay CHƯA tập (False)
          int pastStreakCount = 0;
          for (int i = todayIndex - 1; i >= 0; i--) {
            if (planStreak[i])
              pastStreakCount++;
            else
              break;
          }
          calculatedDay = pastStreakCount + 1;
        }
      }

      currentDayNumber.value = calculatedDay;

      // Streak hiển thị (số ngày đã hoàn thành)
      if (todayIndex >= 0 &&
          todayIndex < planStreak.length &&
          planStreak[todayIndex]) {
        currentStreakDay.value = calculatedDay;
      } else {
        currentStreakDay.value =
            (calculatedDay - 1 > 0) ? calculatedDay - 1 : 0;
      }
    } else {
      currentStreakDay.value = 0;
      currentDayNumber.value = 1;
      planStreak.clear();
    }

    if (DateTime.now().isAfter(currentWorkoutPlan.value!.endDate)) {
      hasFinishedPlan.value = true;
      final _prefs = await prefs;
      _prefs.setBool(planStatus, true);

      await loadDataForFinishScreen();
      await Get.toNamed(Routes.finishPlanScreen);
    }
  }

  // Hàm validate streak - chỉ gọi khi cần thiết (sau khi hoàn thành bài tập)
  Future<void> validateAndUpdateStreak() async {
    await _validateAllStreaks();
    await loadPlanStreak();
  }

  Future<DateTime?> _validateAllStreaks() async {
    if (currentWorkoutPlan.value == null) {
      return null;
    }

    if (dailyOuttakeGoalCalories.value <= 0) {
      await loadOuttakeGoalCalories();
    }

    final plan = currentWorkoutPlan.value!;
    final startDate = DateUtils.dateOnly(plan.startDate);
    final today = DateUtils.dateOnly(DateTime.now());
    final endDate = DateUtils.dateOnly(plan.endDate);

    final validateEndDate = today.isBefore(endDate) ? today : endDate;

    final _streakProvider = StreakProvider();
    final planID = plan.id ?? 0;

    // Ép mục tiêu > 0 để tránh lỗi logic
    var outtakeGoal = dailyOuttakeGoalCalories.value;
    if (outtakeGoal == 0) {
      outtakeGoal = 300;
      dailyOuttakeGoalCalories.value = 300;
    }

    List<Streak> allDayStreaks = [];
    List<bool> shouldCompleteList = [];
    int currentDay = 0;

    bool foundFirstIncompleteDay = false;
    int firstIncompleteDayIndex = -1;

    // Duyệt qua từng ngày để cập nhật trạng thái streak
    while (
        !startDate.add(Duration(days: currentDay)).isAfter(validateEndDate)) {
      final checkDate =
          DateUtils.dateOnly(startDate.add(Duration(days: currentDay)));

      if (checkDate.isAfter(today)) break;

      List<Streak> streakList = await _streakProvider.fetchByDate(checkDate);
      var matchingStreaks =
          streakList.where((element) => element.planID == planID).toList();

      Streak? dayStreak;

      if (matchingStreaks.isEmpty) {
        dayStreak = await _streakProvider.add(Streak(
          date: checkDate,
          planID: planID,
          value: false,
        ));
      } else {
        dayStreak = matchingStreaks.first;
      }

      final List<ExerciseTracker> exerciseTracks =
          await _exerciseTrackProvider.fetchByDate(checkDate);

      int outtake = 0;
      exerciseTracks.forEach((e) {
        outtake += e.outtakeCalories;
      });

      // Logic mới: Cứ có tập (outtake > 0) là được tính hoàn thành
      final shouldBeCompleted = outtake > 0;

      allDayStreaks.add(dayStreak);
      shouldCompleteList.add(shouldBeCompleted);

      // Chỉ tính là gãy chuỗi nếu đó là NGÀY TRONG QUÁ KHỨ (Hôm qua trở về trước)
      bool isPastDate = checkDate.isBefore(today);

      if (!shouldBeCompleted && isPastDate && !foundFirstIncompleteDay) {
        foundFirstIncompleteDay = true;
        firstIncompleteDayIndex = currentDay;
        _log(
            '⚠️ Tìm thấy ngày gãy chuỗi: ${checkDate.toString().split(" ")[0]} (Ngày ${currentDay + 1})');
      }

      currentDay++;
    }

    for (int i = 0; i < allDayStreaks.length; i++) {
      if (allDayStreaks[i].value != shouldCompleteList[i]) {
        Streak newStreak = Streak(
          date: allDayStreaks[i].date,
          planID: allDayStreaks[i].planID,
          value: shouldCompleteList[i],
        );
        await _streakProvider.update(allDayStreaks[i].id ?? 0, newStreak);
      }
    }

    if (foundFirstIncompleteDay && firstIncompleteDayIndex >= 0) {
      final firstIncompleteDate = DateUtils.dateOnly(
          startDate.add(Duration(days: firstIncompleteDayIndex)));
      return firstIncompleteDate;
    }
    return null;
  }

  Future<void> loadPlanStatus() async {
    final _prefs = await prefs;
    hasFinishedPlan.value = _prefs.getBool(planStatus) ?? false;
  }

  Future<void> loadOuttakeGoalCalories() async {
    final _prefs = await prefs;
    final savedGoal = _prefs.getInt(outtakeGoalCaloriesKey);

    if (savedGoal != null && savedGoal > 0) {
      dailyOuttakeGoalCalories.value = savedGoal;
    } else {
      // Tính mục tiêu từ thông tin user thay vì hardcode
      int defaultGoal;
      if (DataService.currentUser != null) {
        defaultGoal = WorkoutPlanUtils.calculateDailyOuttakeGoal(
            DataService.currentUser!);
        _log('📊 Mục tiêu tiêu hao tính từ user: $defaultGoal calories');
      } else {
        defaultGoal = AppValue.intensityWeight.toInt();
      }
      if (defaultGoal <= 0) defaultGoal = 300;
      await _prefs.setInt(outtakeGoalCaloriesKey, defaultGoal);
      dailyOuttakeGoalCalories.value = defaultGoal;
    }
  }

  /// Tính lại mục tiêu tiêu hao dựa trên thông tin user hiện tại
  Future<void> recalculateOuttakeGoalFromUser() async {
    if (DataService.currentUser == null) return;

    int newGoal =
        WorkoutPlanUtils.calculateDailyOuttakeGoal(DataService.currentUser!);
    if (newGoal > 0) {
      await saveOuttakeGoalCalories(newGoal);
      _log('📊 Đã cập nhật mục tiêu tiêu hao: $newGoal calories');
    }
  }

  Future<void> saveOuttakeGoalCalories(int goal) async {
    try {
      final _prefs = await prefs;
      await _prefs.setInt(outtakeGoalCaloriesKey, goal);
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

      currentStreakDay.value = 0;
      planStreak.clear();

      planExerciseCollection.clear();
      planExercise.clear();
      collectionSetting.clear();
      planMealCollection.clear();
      planMeal.clear();

      await _routeProvider.resetRoute(
        onProgress: (message, current, total) {
          _log('📊 $message ($current/$total)');
        },
      );

      await Future.delayed(const Duration(milliseconds: 300));

      try {
        await loadPlanStatus();
        await loadDailyGoalCalories();
        await loadOuttakeGoalCalories();
      } catch (e) {
        _log('⚠️ Lỗi khi load plan status và goals: $e');
      }

      _setupRealtimeListeners();
      _setupCaloriesListeners();

      if (currentWorkoutPlan.value != null) {
        final planID = currentWorkoutPlan.value!.id ?? 0;

        Future.microtask(() async {
          try {
            await loadDailyCalories();
            await loadPlanExerciseCollectionList(planID, lightLoad: true);
            await loadWorkoutPlanMealList(planID, lightLoad: true).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                _log('⚠️ Timeout khi load meal collections (background)');
                return;
              },
            );
            await loadPlanStreak().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                _log('⚠️ Timeout khi load streak (background)');
                return;
              },
            );
            update();
          } catch (e) {
            _log('⚠️ Lỗi khi load collections trong background: $e');
          }
        });
      } else {
        currentStreakDay.value = 0;
        planStreak.clear();
      }

      update();

      _log('✅ Reset lộ trình thành công');
    } catch (e) {
      _log('❌ Lỗi khi reset streak list: $e');
    } finally {
      isLoading.value = false;
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

    if (_hasInitialized) {
      return;
    }

    _hasInitialized = true;
    isLoading.value = true;

    try {
      // Load các thông tin cơ bản song song để tăng tốc
      await Future.wait<void>([
        loadPlanStatus(),
        loadWeightValues(),
        loadDailyGoalCalories(),
        loadOuttakeGoalCalories(),
      ]);

      if (currentWorkoutPlan.value == null) {
        await _autoCreateWorkoutPlanIfNeeded();
        if (currentWorkoutPlan.value != null) {
          await loadDailyGoalCalories();
        }
      }

      if (currentWorkoutPlan.value != null) {
        // Load song song các collections với timeout ngắn hơn
        try {
          await Future.wait<void>([
            loadDailyCalories(),
            loadPlanExerciseCollectionList(currentWorkoutPlan.value!.id ?? 0,
                lightLoad: true),
            loadWorkoutPlanMealList(currentWorkoutPlan.value!.id ?? 0,
                lightLoad: true),
          ]).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              _log('⚠️ Timeout khi load collections');
              return <void>[];
            },
          );
        } catch (e) {
          _log('⚠️ Lỗi khi load collections: $e');
        }

        // Load streak KHÔNG validate (đã tối ưu)
        await loadPlanStreak();
      } else {
        await loadDailyCalories();
        await loadPlanExerciseCollectionList(0, lightLoad: true);
        await loadWorkoutPlanMealList(0, lightLoad: true);
      }

      // Đánh dấu hoàn thành loading
      isLoading.value = false;

      // Setup listeners
      _setupRealtimeListeners();
      _setupDataServiceListeners();
      _setupCaloriesListeners();

      final now = DateTime.now();
      _lastCheckedDate = DateTime(now.year, now.month, now.day);

      _startDateCheckTimer();

      // Load thêm data trong background nếu cần
      if (currentWorkoutPlan.value != null) {
        Future.delayed(const Duration(seconds: 2), () async {
          // Load full data trong background
          try {
            await loadPlanExerciseCollectionList(
                currentWorkoutPlan.value!.id ?? 0);
            await loadWorkoutPlanMealList(currentWorkoutPlan.value!.id ?? 0);
            update();
          } catch (e) {
            // Ignore background errors
          }
        });
      }
    } catch (e) {
      _log('❌ Lỗi onInit: $e');
      isLoading.value = false;
    }
  }

  void _setupCaloriesListeners() {
    _outtakeCaloriesWorker?.dispose();
    _intakeCaloriesWorker?.dispose();

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

    Future.delayed(const Duration(milliseconds: 600), () {
      _validateDailyCalories();
    });
  }

  void _startDateCheckTimer() {
    _dateCheckTimer?.cancel();

    _dateCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndResetIfNewDay();
    });
  }

  void _setupDataServiceListeners() {
    _mealListWorker?.dispose();
    _workoutListWorker?.dispose();
    _planExerciseCollectionWorker?.dispose();
    _planMealCollectionWorker?.dispose();

    _mealListWorker = ever(DataService.instance.mealListRx, (_) {
      _reloadMealDebounceTimer?.cancel();
      _reloadMealDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!_isReloadingMealCollections && currentWorkoutPlan.value != null) {
          int planID = currentWorkoutPlan.value?.id ?? 0;
          loadWorkoutPlanMealList(planID).then((_) => update());
        } else if (!_isReloadingMealCollections) {
          loadWorkoutPlanMealList(0).then((_) => update());
        }
      });
    });

    _workoutListWorker = ever(DataService.instance.workoutListRx, (_) {
      _reloadExerciseDebounceTimer?.cancel();
      _reloadExerciseDebounceTimer =
          Timer(const Duration(milliseconds: 1000), () {
        if (!_isReloadingExerciseCollections &&
            currentWorkoutPlan.value != null) {
          int planID = currentWorkoutPlan.value?.id ?? 0;
          loadPlanExerciseCollectionList(planID).then((_) => update());
        } else if (!_isReloadingExerciseCollections) {
          loadPlanExerciseCollectionList(0).then((_) => update());
        }
      });
    });

    _log('✅ DataService listeners setup completed');
  }

  void _setupRealtimeListeners() {
    _exerciseCollectionSubscription?.cancel();
    _mealCollectionSubscription?.cancel();

    int planID = currentWorkoutPlan.value?.id ?? 0;

    _exerciseCollectionSubscription =
        _wkExerciseCollectionProvider.streamByPlanID(planID).listen(
      (collections) {
        _reloadExerciseDebounceTimer?.cancel();
        _reloadExerciseDebounceTimer =
            Timer(const Duration(milliseconds: 500), () {
          if (!_isReloadingExerciseCollections) {
            _reloadExerciseCollections();
          }
        });
      },
      onError: (error) {
        // Ignore errors
      },
    );

    _mealCollectionSubscription =
        _wkMealCollectionProvider.streamByPlanID(planID).listen(
      (collections) {
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

    _wkExerciseCollectionProvider.streamByPlanID(0).listen(
      (collections) {
        _reloadExerciseDebounceTimer?.cancel();
        _reloadExerciseDebounceTimer =
            Timer(const Duration(milliseconds: 500), () {
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

  Future<void> _reloadExerciseCollections() async {
    if (_isReloadingExerciseCollections) {
      return;
    }

    _isReloadingExerciseCollections = true;
    try {
      int planID = currentWorkoutPlan.value?.id ?? 0;
      await loadPlanExerciseCollectionList(planID);
      update();
    } finally {
      _isReloadingExerciseCollections = false;
    }
  }

  Future<void> _reloadMealCollections() async {
    if (_isReloadingMealCollections) {
      return;
    }

    _isReloadingMealCollections = true;
    try {
      int planID = currentWorkoutPlan.value?.id ?? 0;
      await loadWorkoutPlanMealList(planID);
      update();
    } finally {
      _isReloadingMealCollections = false;
    }
  }

  @override
  void onClose() {
    _exerciseCollectionSubscription?.cancel();
    _mealCollectionSubscription?.cancel();
    _reloadExerciseDebounceTimer?.cancel();
    _reloadMealDebounceTimer?.cancel();
    _caloriesValidationTimer?.cancel();
    _dateCheckTimer?.cancel();
    _outtakeCaloriesWorker?.dispose();
    _intakeCaloriesWorker?.dispose();

    _mealListWorker?.dispose();
    _workoutListWorker?.dispose();
    _planExerciseCollectionWorker?.dispose();
    _planMealCollectionWorker?.dispose();

    super.onClose();
  }

  void _markRelevantTabToUpdate() {
    if (!RefeshTabController.instance.isProfileTabNeedToUpdate) {
      RefeshTabController.instance.toggleProfileTabUpdate();
    }
  }

  Future<void> refreshAllData() async {
    isRefreshing.value = true;
    try {
      _log('🔄 Bắt đầu refresh tất cả dữ liệu...');

      int planID = currentWorkoutPlan.value?.id ?? 0;

      await Future.wait([
        loadDailyGoalCalories(),
        loadOuttakeGoalCalories(),
        loadDailyCalories(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('⚠️ Timeout khi load basic data');
          return <void>[];
        },
      );

      await Future.wait([
        loadPlanExerciseCollectionList(planID, lightLoad: true),
        loadWorkoutPlanMealList(planID, lightLoad: true),
        loadPlanStreak(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _log('⚠️ Timeout khi load collections và streaks');
          return <void>[];
        },
      );

      await Future.wait([
        loadPlanStreak(),
        loadWeightValues(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('⚠️ Timeout khi load streak và weight');
          return <void>[];
        },
      );

      update();

      _log('✅ Refresh hoàn tất');
    } catch (e) {
      _log('❌ Lỗi khi refresh: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _autoCreateWorkoutPlanIfNeeded() async {
    try {
      if (DataService.currentUser == null) {
        return;
      }

      final user = DataService.currentUser!;

      if (user.currentWeight == 0 ||
          user.goalWeight == 0 ||
          user.currentHeight == 0) {
        return;
      }

      final existingPlan =
          await _workoutPlanProvider.fetchByUserID(user.id ?? '');
      if (existingPlan != null) {
        currentWorkoutPlan.value = existingPlan;
        return;
      }

      await DataService.instance.loadWorkoutList();
      await DataService.instance.loadMealList();
      await DataService.instance.loadMealCategoryList();

      await _routeProvider.createRoute(user);

      final newPlan = await _workoutPlanProvider.fetchByUserID(user.id ?? '');
      if (newPlan != null) {
        currentWorkoutPlan.value = newPlan;
        dailyGoalCalories.value = newPlan.dailyGoalCalories.toInt();
      }
    } catch (e) {
      // Ignore
    }
  }
}
