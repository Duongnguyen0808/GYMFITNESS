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
  RxBool isRefreshing = false.obs;

  // Stream subscriptions cho real-time updates
  StreamSubscription<List<PlanExerciseCollection>>?
      _exerciseCollectionSubscription;
  StreamSubscription<List<PlanMealCollection>>? _mealCollectionSubscription;

  // Workers để lắng nghe thay đổi từ DataService
  Worker? _mealListWorker;
  Worker? _workoutListWorker;
  Worker? _planExerciseCollectionWorker;
  Worker? _planMealCollectionWorker;

  // Flag để tránh reload vòng lặp
  bool _isReloadingExerciseCollections = false;
  bool _isReloadingMealCollections = false;
  Timer? _reloadExerciseDebounceTimer;
  Timer? _reloadMealDebounceTimer;

  // Timer cho calories listeners
  Timer? _caloriesValidationTimer;
  Worker? _outtakeCaloriesWorker;
  Worker? _intakeCaloriesWorker;

  // Timer để kiểm tra date change và tự động reset calories khi qua ngày mới
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

  Future<void> loadPlanExerciseCollectionList(int planID,
      {bool lightLoad = false}) async {
    try {
      // Giới hạn số collections load - chỉ load 30 ngày gần nhất và 30 ngày tiếp theo
      DateTime now = DateTime.now();
      DateTime filterStartDate = now.subtract(const Duration(days: 30));
      DateTime filterEndDate = now.add(const Duration(days: 30));

      List<PlanExerciseCollection> allCollections =
          await _wkExerciseCollectionProvider.fetchByPlanID(planID);

      if (allCollections.isEmpty && planID != 0) {
        // Fallback về default nếu user plan không có collections
        allCollections = await _wkExerciseCollectionProvider.fetchByPlanID(0);
      }

      if (allCollections.isNotEmpty) {
        // Lọc collections trong khoảng thời gian hợp lý
        List<PlanExerciseCollection> filteredCollections = allCollections
            .where((col) =>
                col.date.isAfter(
                    filterStartDate.subtract(const Duration(days: 1))) &&
                col.date.isBefore(filterEndDate.add(const Duration(days: 1))))
            .toList();

        // Sắp xếp theo ngày
        filteredCollections.sort((a, b) => a.date.compareTo(b.date));

        // Nếu là lightLoad (sau reset), chỉ load 7 ngày đầu tiên
        // Ngược lại, giới hạn tối đa 60 collections để tránh load quá nhiều
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

        // Clear lists trước khi load
        planExercise.clear();
        collectionSetting.clear();

        // Load settings và exercises theo batch
        // Nếu là lightLoad, dùng batch size nhỏ hơn (3) để tránh quá tải backend
        // Ngược lại, dùng batch size lớn hơn (20) để tăng tốc độ
        final int batchSize = lightLoad ? 3 : 20;
        for (int batchStart = 0;
            batchStart < filteredCollections.length;
            batchStart += batchSize) {
          int batchEnd = (batchStart + batchSize < filteredCollections.length)
              ? batchStart + batchSize
              : filteredCollections.length;

          // Load batch hiện tại
          List<Future<void>> batchFutures = [];
          for (int i = batchStart; i < batchEnd; i++) {
            final collection = filteredCollections[i];

            // Chỉ load setting nếu chưa có trong cache
            if (collection.collectionSettingID.isNotEmpty) {
              final existingSetting = collectionSetting.firstWhereOrNull(
                (s) => s.id == collection.collectionSettingID,
              );
              if (existingSetting == null) {
                batchFutures.add(
                  loadCollectionSetting(collection.collectionSettingID)
                      .catchError((e) {
                    // Chỉ log nếu không phải 404 để tránh spam
                    final errorString = e.toString().toLowerCase();
                    if (!errorString.contains('404') &&
                        !errorString.contains('not found')) {
                      print(
                          '⚠️ Lỗi khi load setting ${collection.collectionSettingID}: $e');
                    }
                  }),
                );
              }
            }

            // Chỉ load exercises nếu collection có ID
            if (collection.id != null && collection.id!.isNotEmpty) {
              batchFutures.add(
                loadPlanExerciseList(collection.id!).catchError((e) {
                  print(
                      '⚠️ Lỗi khi load exercises cho collection ${collection.id}: $e');
                }),
              );
            }
          }

          // Chờ batch hiện tại với timeout
          // Nếu là lightLoad, dùng timeout ngắn hơn (5 giây) để nhanh hơn
          try {
            await Future.wait(batchFutures).timeout(
              Duration(seconds: lightLoad ? 5 : 8),
              onTimeout: () {
                print('⚠️ Timeout khi load batch ${batchStart}-${batchEnd}');
                return <void>[];
              },
            );
          } catch (e) {
            print('⚠️ Lỗi khi load batch: $e');
          }

          // Không nghỉ giữa các batch để tăng tốc độ
        }
      } else {
        // Không có collections, clear lists
        planExerciseCollection.clear();
        planExercise.clear();
        collectionSetting.clear();
      }
    } catch (e) {
      print('❌ Lỗi khi load plan exercise collections: $e');
      // Giữ lại list rỗng để app không crash
      planExerciseCollection.clear();
    }
  }

  Future<void> loadPlanExerciseList(String listID) async {
    // Kiểm tra listID hợp lệ
    if (listID.isEmpty) {
      return;
    }

    // Xóa các planExercise cũ với listID này để tránh duplicate
    planExercise.removeWhere((element) => element.listID == listID);

    try {
      List<PlanExercise> _list =
          await _wkExerciseProvider.fetchByListID(listID).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout khi load exercises cho listID $listID');
          return <PlanExercise>[];
        },
      );

      if (_list.isNotEmpty) {
        planExercise.addAll(_list);
      }
    } catch (e) {
      print('⚠️ Lỗi khi load exercises cho listID $listID: $e');
    }
  }

  Future<void> loadCollectionSetting(String id) async {
    // Kiểm tra xem setting đã tồn tại chưa để tránh duplicate
    final existingIndex =
        collectionSetting.indexWhere((element) => element.id == id);
    if (existingIndex != -1) {
      // Đã tồn tại, không cần load lại
      return;
    }

    // Kiểm tra id hợp lệ
    if (id.isEmpty) {
      return;
    }

    try {
      var setting = await _colSettingProvider.fetch(id).timeout(
            const Duration(seconds: 3), // Giảm timeout xuống 3 giây
          );
      collectionSetting.add(setting);
    } catch (e) {
      // Ignore errors - setting có thể đã bị xóa hoặc timeout
      // Chỉ log nếu không phải 404 để tránh spam log
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('404') && !errorString.contains('not found')) {
        print('⚠️ Không thể load setting $id: $e');
      }
    }
  }

  Future<void> loadDailyCalories() async {
    final date = DateTime.now();
    final today = DateTime(date.year, date.month, date.day);

    // Kiểm tra xem đã qua ngày mới chưa
    if (_lastCheckedDate != null && _lastCheckedDate != today) {
      print('📅 Đã qua ngày mới, reset calories về 0');
    }

    // Lưu ngày hiện tại để kiểm tra lần sau
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

  /// Kiểm tra xem đã qua ngày mới chưa và tự động reset calories nếu cần
  void _checkAndResetIfNewDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Nếu chưa có lastCheckedDate hoặc đã qua ngày mới
    if (_lastCheckedDate == null || _lastCheckedDate != today) {
      print(
          '📅 Phát hiện ngày mới, tự động reset calories và validate lại streaks');
      // Gọi loadDailyCalories để reset calories về 0 (vì sẽ fetch data mới cho ngày hôm nay)
      loadDailyCalories().then((_) {
        // Sau khi load calories xong, gọi loadPlanStreak để validate lại tất cả các ngày đã qua và cập nhật ngọn lửa
        loadPlanStreak();
      });
    }
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
        // Reload plan streak để cập nhật UI (bao gồm tất cả các ngày đã qua)
        await loadPlanStreak();
        update(); // Trigger UI update
      }
    } else {
      // Chưa đạt mục tiêu
      if (todayStreakValue) {
        Streak newStreak = Streak(
            date: todayStreak.date, planID: todayStreak.planID, value: false);
        await _streakProvider.update(todayStreak.id ?? 0, newStreak);
        // Reload plan streak để cập nhật UI (bao gồm tất cả các ngày đã qua)
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

  Future<void> loadWorkoutPlanMealList(int planID,
      {bool lightLoad = false}) async {
    try {
      // Nếu planID = 0, chỉ load default collections
      if (planID == 0) {
        List<PlanMealCollection> defaultCollections =
            await _wkMealCollectionProvider.fetchByPlanID(0);

        if (defaultCollections.isNotEmpty) {
          defaultCollections.sort((a, b) => a.date.compareTo(b.date));

          // Nếu là lightLoad, chỉ load 7 ngày đầu
          if (lightLoad && defaultCollections.length > 7) {
            defaultCollections = defaultCollections.sublist(0, 7);
          }

          planMealCollection.assignAll(defaultCollections);

          planMeal.clear();

          // Nếu là lightLoad, load tuần tự để tránh quá tải
          if (lightLoad) {
            for (int i = 0; i < defaultCollections.length; i++) {
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                await loadPlanMealList(defaultCollections[i].id!).timeout(
                  const Duration(seconds: 3),
                  onTimeout: () {
                    print(
                        '⚠️ Timeout khi load meal list ${defaultCollections[i].id}');
                    return;
                  },
                );
              }
            }
          } else {
            for (int i = 0; i < defaultCollections.length; i++) {
              if (defaultCollections[i].id != null &&
                  defaultCollections[i].id!.isNotEmpty) {
                await loadPlanMealList(defaultCollections[i].id!);
              }
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
              .where((col) =>
                  col.date.isAfter(
                      filterStartDate.subtract(const Duration(days: 1))) &&
                  col.date.isBefore(filterEndDate.add(const Duration(days: 1))))
              .toList();

          // Nếu là lightLoad, chỉ load 7 ngày đầu
          // Ngược lại, giới hạn tối đa 90 collections để tránh load quá nhiều
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

          planMeal.clear();

          // Nếu là lightLoad, load theo batch nhỏ (3 collections mỗi batch) để tránh quá tải
          if (lightLoad) {
            const int batchSize = 3;
            for (int batchStart = 0;
                batchStart < filteredCollections.length;
                batchStart += batchSize) {
              int batchEnd =
                  (batchStart + batchSize < filteredCollections.length)
                      ? batchStart + batchSize
                      : filteredCollections.length;

              List<Future<void>> batchFutures = [];
              for (int i = batchStart; i < batchEnd; i++) {
                if (filteredCollections[i].id != null &&
                    filteredCollections[i].id!.isNotEmpty) {
                  batchFutures
                      .add(loadPlanMealList(filteredCollections[i].id!));
                }
              }

              try {
                await Future.wait(batchFutures).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    print(
                        '⚠️ Timeout khi load meal batch ${batchStart}-${batchEnd}');
                    return <void>[];
                  },
                );
              } catch (e) {
                print('⚠️ Lỗi khi load meal batch: $e');
              }
            }
          } else {
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
  RxInt currentDayNumber =
      0.obs; // Số thứ tự ngày trong plan (Ngày 1, Ngày 2, ...)
  static const String planStatus = 'planStatus';
  static const String lastStreakLossNotificationDateKey =
      'lastStreakLossNotificationDate';

  final _routeProvider = ExerciseNutritionRouteProvider();

  Future<void> loadPlanStreak() async {
    planStreak.clear();

    if (currentWorkoutPlan.value == null) {
      // Nếu không có workout plan, set về 0 và clear streak
      currentStreakDay.value = 0;
      currentDayNumber.value = 0;
      planStreak.clear();
      return;
    }

    // Validate tất cả các ngày từ ngày bắt đầu đến hiện tại trước khi load
    final firstIncompleteDate = await _validateAllStreaks();

    // Tính số thứ tự ngày hiện tại trong plan (Ngày 1, Ngày 2, ...)
    final plan = currentWorkoutPlan.value!;
    final startDate = DateTime(
      plan.startDate.year,
      plan.startDate.month,
      plan.startDate.day,
    );
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    // Nếu streak bị mất (có ngày không đạt mục tiêu), reset currentDayNumber về 1
    if (firstIncompleteDate != null) {
      currentDayNumber.value = 1;

      // Kiểm tra xem đã hiển thị thông báo cho ngày này chưa
      final _prefs = await prefs;
      final lastNotificationDateStr =
          _prefs.getString(lastStreakLossNotificationDateKey);
      final firstIncompleteDateStr =
          firstIncompleteDate.toIso8601String().split('T')[0];

      // Chỉ hiển thị thông báo nếu chưa hiển thị cho ngày này
      if (lastNotificationDateStr != firstIncompleteDateStr) {
        // Lưu ngày đã hiển thị thông báo
        await _prefs.setString(
            lastStreakLossNotificationDateKey, firstIncompleteDateStr);

        // Hiển thị thông báo streak bị mất (chỉ 1 lần)
        Get.snackbar(
          '🔥 Chuỗi ngày đã bị mất',
          'Bạn đã không đạt mục tiêu một ngày. Chuỗi đã được reset về Ngày 1',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
        );
      }
    } else {
      // Tính số ngày từ startDate đến hôm nay (bắt đầu từ 1)
      final daysDifference = todayDateOnly.difference(startDate).inDays;
      if (daysDifference >= 0) {
        currentDayNumber.value = daysDifference + 1;
      } else {
        // Nếu chưa đến ngày bắt đầu plan
        currentDayNumber.value = 0;
      }
    }

    Map<int, List<bool>> list = await _routeProvider.loadStreakList();
    if (list.isNotEmpty) {
      currentStreakDay.value = list.keys.first;
      planStreak.assignAll(list.values
          .first); // Dùng assignAll thay vì addAll để trigger reactive update
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
  /// Returns DateTime? của ngày đầu tiên không đạt mục tiêu (null nếu không có)
  Future<DateTime?> _validateAllStreaks() async {
    if (currentWorkoutPlan.value == null) {
      return null;
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
      return null;
    }

    print(
        '🔥 Bắt đầu validate streaks từ ${startDate.toString().split(' ')[0]} đến ${validateEndDate.toString().split(' ')[0]}');

    int updatedCount = 0;
    int currentDay = 0;
    bool foundFirstIncompleteDay =
        false; // Đánh dấu đã tìm thấy ngày đầu tiên không đạt mục tiêu
    int firstIncompleteDayIndex =
        -1; // Index của ngày đầu tiên không đạt mục tiêu

    // Bước 1: Validate tất cả các ngày và tìm ngày đầu tiên không đạt mục tiêu
    List<Streak> allDayStreaks = [];
    List<bool> shouldCompleteList = [];

    while (
        !startDate.add(Duration(days: currentDay)).isAfter(validateEndDate)) {
      final checkDate =
          DateUtils.dateOnly(startDate.add(Duration(days: currentDay)));
      final dayNumber = currentDay + 1;

      // Lấy streak cho ngày này
      List<Streak> streakList = await _streakProvider.fetchByDate(checkDate);
      var matchingStreaks =
          streakList.where((element) => element.planID == planID).toList();

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

      // Chỉ cần kiểm tra outtake >= goal (không cần trừ intake)
      // Vì mục tiêu là calories tiêu hao, không phải calories tiêu hao trừ đi calories hấp thụ
      final shouldBeCompleted = outtake >= outtakeGoal;

      print(
          '📊 Ngày $dayNumber (${checkDate.toString().split(' ')[0]}): intake=$intake, outtake=$outtake, goal=$outtakeGoal, shouldComplete=$shouldBeCompleted (outtake >= goal), currentValue=${dayStreak.value}');

      // Lưu lại để xử lý sau
      allDayStreaks.add(dayStreak);
      shouldCompleteList.add(shouldBeCompleted);

      // Tìm ngày đầu tiên không đạt mục tiêu
      if (!shouldBeCompleted && !foundFirstIncompleteDay) {
        foundFirstIncompleteDay = true;
        firstIncompleteDayIndex = currentDay;
        print('⚠️ Tìm thấy ngày đầu tiên không đạt mục tiêu: Ngày $dayNumber');
      }

      currentDay++;
    }

    // Bước 2: Cập nhật streaks
    // Logic: Nếu có ngày không đạt mục tiêu, tất cả các ngày TRƯỚC và SAU ngày đó phải reset về false
    // Streak phải liên tiếp từ ngày đầu tiên đến ngày hiện tại, không được có khoảng trống
    // Nếu có một ngày không đạt ở giữa, tất cả các ngày trước đó cũng phải reset
    for (int i = 0; i < allDayStreaks.length; i++) {
      final dayStreak = allDayStreaks[i];
      final dayNumber = i + 1;
      bool finalValue = shouldCompleteList[i];

      // Nếu đã tìm thấy ngày đầu tiên không đạt mục tiêu
      if (foundFirstIncompleteDay) {
        // Reset tất cả các ngày TRƯỚC và TẠI ngày không đạt mục tiêu về false
        // Các ngày SAU sẽ giữ nguyên giá trị của chúng (streak mới bắt đầu từ đó nếu đạt mục tiêu)
        if (i <= firstIncompleteDayIndex) {
          finalValue = false;
          print(
              '🔄 Reset ngày $dayNumber về false vì ngày ${firstIncompleteDayIndex + 1} không đạt mục tiêu (streak phải liên tiếp)');
        }
        // Nếu i > firstIncompleteDayIndex, giữ nguyên finalValue từ shouldCompleteList
      }

      // Cập nhật streak nếu cần
      if (dayStreak.value != finalValue) {
        Streak newStreak = Streak(
          date: dayStreak.date,
          planID: dayStreak.planID,
          value: finalValue,
        );
        await _streakProvider.update(dayStreak.id ?? 0, newStreak);
        updatedCount++;
        print(
            '✅ Cập nhật streak ngày $dayNumber: ${dayStreak.value} -> $finalValue');
      }
    }

    print('🔥 Hoàn tất validate streaks: cập nhật $updatedCount ngày');

    // Trả về ngày đầu tiên không đạt mục tiêu (null nếu không có)
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

      // Clear tất cả cache trước khi reset để tránh fetch dữ liệu cũ
      planExerciseCollection.clear();
      planExercise.clear();
      collectionSetting.clear();
      planMealCollection.clear();
      planMeal.clear();

      // Reset route (xóa và tạo lại workout plan) với progress callback
      // Không cần timeout ở đây vì resetRoute đã có timeout bên trong rồi
      await _routeProvider.resetRoute(
        onProgress: (message, current, total) {
          // Có thể hiển thị progress ở đây nếu cần
          print('📊 $message ($current/$total)');
        },
      );

      // Đợi một chút để đảm bảo database đã commit
      await Future.delayed(const Duration(milliseconds: 300));

      // Chỉ reload những dữ liệu cơ bản nhất - đơn giản hóa để tránh treo
      try {
        await loadPlanStatus();
        await loadDailyGoalCalories(); // Reload workout plan và update currentWorkoutPlan
        await loadOuttakeGoalCalories(); // Reload mục tiêu calories tiêu hao
      } catch (e) {
        print('⚠️ Lỗi khi load plan status và goals: $e');
      }

      // Setup lại real-time listeners trước (sẽ tự động load data khi có)
      _setupRealtimeListeners();
      _setupCaloriesListeners();

      // Load collections và streak trong background (không block UI)
      // Điều này giúp app không bị treo và user có thể tiếp tục sử dụng
      if (currentWorkoutPlan.value != null) {
        final planID = currentWorkoutPlan.value!.id ?? 0;

        // Load dữ liệu trong background (không await để không block)
        Future.microtask(() async {
          try {
            await loadDailyCalories();
            await loadPlanExerciseCollectionList(planID, lightLoad: true)
                .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('⚠️ Timeout khi load exercise collections (background)');
                return;
              },
            );
            await loadWorkoutPlanMealList(planID, lightLoad: true).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('⚠️ Timeout khi load meal collections (background)');
                return;
              },
            );
            await loadPlanStreak().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⚠️ Timeout khi load streak (background)');
                return;
              },
            );
            update(); // Update UI sau khi load xong
          } catch (e) {
            print('⚠️ Lỗi khi load collections trong background: $e');
          }
        });
      } else {
        currentStreakDay.value = 0;
        planStreak.clear();
      }

      // Trigger UI update ngay lập tức (với dữ liệu đã có)
      update();

      print('✅ Reset lộ trình thành công');
    } catch (e) {
      print('❌ Lỗi khi reset streak list: $e');
      // Không rethrow để tránh crash app - chỉ log lỗi và đảm bảo app vẫn hoạt động
    } finally {
      // Luôn đảm bảo loading được set về false để UI không bị treo
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

      // Lắng nghe thay đổi từ DataService để tự động reload
      _setupDataServiceListeners();

      // Lắng nghe thay đổi calories để tự động validate
      _setupCaloriesListeners();

      // Khởi tạo lastCheckedDate với ngày hiện tại
      final now = DateTime.now();
      _lastCheckedDate = DateTime(now.year, now.month, now.day);

      // Bắt đầu timer để kiểm tra date change định kỳ (mỗi 1 phút)
      _startDateCheckTimer();

      // Nếu không có workout plan, thử load lại sau một chút (có thể đang được tạo async)
      if (currentWorkoutPlan.value == null) {
        Future.delayed(const Duration(seconds: 2), () async {
          await loadDailyGoalCalories();
          if (currentWorkoutPlan.value != null) {
            await loadPlanExerciseCollectionList(
                currentWorkoutPlan.value!.id ?? 0);
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

  /// Bắt đầu timer để kiểm tra date change định kỳ
  void _startDateCheckTimer() {
    // Hủy timer cũ nếu có
    _dateCheckTimer?.cancel();

    // Kiểm tra mỗi 1 phút xem có qua ngày mới không
    _dateCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndResetIfNewDay();
    });
  }

  /// Thiết lập listeners để lắng nghe thay đổi từ DataService
  void _setupDataServiceListeners() {
    // Hủy workers cũ nếu có
    _mealListWorker?.dispose();
    _workoutListWorker?.dispose();
    _planExerciseCollectionWorker?.dispose();
    _planMealCollectionWorker?.dispose();

    // Lắng nghe thay đổi mealList từ DataService
    _mealListWorker = ever(DataService.instance.mealListRx, (_) {
      // Khi có meal mới, reload meal collections để hiển thị
      _reloadMealDebounceTimer?.cancel();
      _reloadMealDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
        if (!_isReloadingMealCollections && currentWorkoutPlan.value != null) {
          int planID = currentWorkoutPlan.value?.id ?? 0;
          loadWorkoutPlanMealList(planID).then((_) => update());
        } else if (!_isReloadingMealCollections) {
          // Nếu không có user plan, reload default plan
          loadWorkoutPlanMealList(0).then((_) => update());
        }
      });
    });

    // Lắng nghe thay đổi workoutList từ DataService
    _workoutListWorker = ever(DataService.instance.workoutListRx, (_) {
      // Khi có workout mới, reload exercise collections để hiển thị
      _reloadExerciseDebounceTimer?.cancel();
      _reloadExerciseDebounceTimer =
          Timer(const Duration(milliseconds: 1000), () {
        if (!_isReloadingExerciseCollections &&
            currentWorkoutPlan.value != null) {
          int planID = currentWorkoutPlan.value?.id ?? 0;
          loadPlanExerciseCollectionList(planID).then((_) => update());
        } else if (!_isReloadingExerciseCollections) {
          // Nếu không có user plan, reload default plan
          loadPlanExerciseCollectionList(0).then((_) => update());
        }
      });
    });

    // Lắng nghe thay đổi planExerciseCollection từ DataService (nếu có)
    // Note: planExerciseCollection không có trong DataService, nhưng có thể thêm sau

    print('✅ DataService listeners setup completed');
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
    _dateCheckTimer?.cancel(); // Hủy date check timer
    _outtakeCaloriesWorker?.dispose();
    _intakeCaloriesWorker?.dispose();

    // Dispose DataService workers
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

  /// Refresh tất cả dữ liệu trên màn hình chính
  Future<void> refreshAllData() async {
    isRefreshing.value = true;
    try {
      print('🔄 Bắt đầu refresh tất cả dữ liệu...');

      int planID = currentWorkoutPlan.value?.id ?? 0;

      // Load những dữ liệu cơ bản nhất song song và nhanh nhất có thể
      await Future.wait([
        // 1. Reload workout plan và goal calories
        loadDailyGoalCalories(),
        loadOuttakeGoalCalories(),
        // 2. Reload daily calories
        loadDailyCalories(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout khi load basic data');
          return <void>[];
        },
      );

      // Load plan collections và streak với lightLoad để nhanh hơn
      // Chỉ load những collections cần thiết nhất (7 ngày gần nhất)
      await Future.wait([
        loadPlanExerciseCollectionList(planID, lightLoad: true),
        loadWorkoutPlanMealList(planID, lightLoad: true),
        loadPlanStreak(), // Validate lại tất cả streaks khi refresh
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⚠️ Timeout khi load collections và streaks');
          return <void>[];
        },
      );

      // Load streak và weight song song
      await Future.wait([
        loadPlanStreak(),
        loadWeightValues(),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout khi load streak và weight');
          return <void>[];
        },
      );

      // Trigger UI update
      update();

      print('✅ Refresh hoàn tất');
    } catch (e) {
      print('❌ Lỗi khi refresh: $e');
    } finally {
      isRefreshing.value = false;
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
      if (user.currentWeight == 0 ||
          user.goalWeight == 0 ||
          user.currentHeight == 0) {
        return;
      }

      // Kiểm tra lại xem có workout plan chưa (có thể đã được tạo trong lúc này)
      final existingPlan =
          await _workoutPlanProvider.fetchByUserID(user.id ?? '');
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
