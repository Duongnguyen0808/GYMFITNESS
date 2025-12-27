import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipt/app/core/utilities/utils.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/data/models/plan_meal.dart';
import 'package:vipt/app/data/models/plan_meal_collection.dart';
import 'package:vipt/app/data/models/streak.dart';
import 'package:vipt/app/data/models/vipt_user.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/workout_plan.dart';
import 'package:vipt/app/data/providers/plan_exercise_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_provider_api.dart';
import 'package:vipt/app/data/providers/streak_provider.dart';
import 'package:vipt/app/data/providers/workout_plan_provider.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/global_widgets/custom_confirmation_dialog.dart';

// Tắt log để tăng tốc độ - chỉ bật khi cần debug
const bool _enableRouteLogging = false;

void _log(String message) {
  if (_enableRouteLogging && kDebugMode) {
    print(message);
  }
}

class ExerciseNutritionRouteProvider {
  Future<void> createRoute(
    ViPTUser user, {
    Function(String message, int current, int total)? onProgress,
    bool skipInitialMessage =
        false, // Skip message đầu tiên nếu đã được set từ resetRoute
  }) async {
    try {
      if (onProgress != null && !skipInitialMessage) {
        onProgress('Đang tạo kế hoạch tập luyện...', 0, 100);
      }

      final _workoutPlanProvider = WorkoutPlanProvider();
      num weightDiff = user.goalWeight - user.currentWeight;
      num workoutPlanLengthInWeek =
          weightDiff.abs() / AppValue.intensityWeightPerWeek;
      int workoutPlanLengthInDays = workoutPlanLengthInWeek.toInt() * 7;

      // Đảm bảo plan length tối thiểu là 7 ngày
      if (workoutPlanLengthInDays < 7) {
        workoutPlanLengthInDays = 7;
      }

      print(
          '📋 Plan length: $workoutPlanLengthInDays ngày (sẽ tạo collections cho 60 ngày đầu tiên)');

      DateTime workoutPlanStartDate = DateTime.now();
      DateTime workoutPlanEndDate =
          DateTime.now().add(Duration(days: workoutPlanLengthInDays));

      num dailyGoalCalories = WorkoutPlanUtils.createDailyGoalCalories(user);
      num dailyIntakeCalories = dailyGoalCalories + AppValue.intensityWeight;
      num dailyOuttakeCalories = AppValue.intensityWeight;

      if (onProgress != null) {
        onProgress('Đang lưu kế hoạch...', 10, 100);
      }

      WorkoutPlan workoutPlan = WorkoutPlan(
          dailyGoalCalories: dailyGoalCalories,
          userID: user.id ?? '',
          startDate: workoutPlanStartDate,
          endDate: workoutPlanEndDate);
      workoutPlan = await _workoutPlanProvider.add(workoutPlan);

      final planID = workoutPlan.id ?? 0;

      // Tạo streaks cho toàn bộ plan trước
      if (onProgress != null) {
        onProgress('Đang tạo streak...', 30, 100);
      }

      await _generateInitialPlanStreak(
          planID: planID,
          startDate: workoutPlanStartDate,
          planLengthInDays: workoutPlanLengthInDays);

      // CHỈ TẠO 3 NGÀY ĐẦU TIÊN ngay lập tức
      const int immediateDays = 3;

      if (onProgress != null) {
        onProgress('Đang tạo kế hoạch cho vài ngày đầu...', 50, 100);
      }

      // Tạo 3 ngày đầu song song
      await Future.wait([
        _generateMealListImmediate(
          intakeCalories: dailyIntakeCalories,
          planID: planID,
          days: immediateDays,
        ),
        generateExerciseListImmediate(
          planID: planID,
          outtakeCalories: dailyOuttakeCalories,
          userWeight: user.currentWeight,
          days: immediateDays,
        ),
      ]).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _log('⚠️ Timeout khi tạo 3 ngày đầu - tiếp tục với dữ liệu hiện có');
          return <void>[];
        },
      );

      final _pefs = await SharedPreferences.getInstance();
      await _pefs.setBool('planStatus', false);

      if (onProgress != null) {
        onProgress('Hoàn tất!', 100, 100);
      }

      // Tạo collections còn lại trong background
      if (workoutPlanLengthInDays > immediateDays) {
        _generateRemainingCollectionsInBackground(
          planID: planID,
          intakeCalories: dailyIntakeCalories,
          outtakeCalories: dailyOuttakeCalories,
          userWeight: user.currentWeight,
          startDay: immediateDays,
          totalDays: workoutPlanLengthInDays,
        );
      }
    } catch (e) {
      _log('❌ Lỗi khi tạo route: $e');
      rethrow;
    }
  }

  /// Tạo exercise collections cho số ngày cần thiết ngay lập tức
  Future<void> generateExerciseListImmediate({
    required num outtakeCalories,
    required int planID,
    required num userWeight,
    required int days,
  }) async {
    _log('📅 Tạo exercise collections cho $days ngày đầu tiên (immediate)');

    for (int i = 0; i < days; i++) {
      try {
        await _generateExerciseListEveryDay(
          outtakeCalories: outtakeCalories,
          userWeight: userWeight,
          planID: planID,
          date: DateTime.now().add(Duration(days: i)),
        ).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            _log('⚠️ Timeout khi tạo exercise collection cho ngày ${i + 1}');
            return;
          },
        );
      } catch (e) {
        _log('⚠️ Lỗi khi tạo exercise collection cho ngày ${i + 1}: $e');
      }
    }
    _log('✅ Hoàn tất tạo exercise collections cho $days ngày đầu tiên');
  }

  Future<void> generateExerciseListWithPlanLength({
    required num outtakeCalories,
    required int planID,
    required num userWeight,
    required int workoutPlanLength,
    Function(int current, int total)? onProgress,
  }) async {
    final int actualLength = 60; // Chỉ tạo 60 ngày tiếp theo

    print(
        '📅 Tạo exercise collections cho $actualLength ngày tiếp theo (từ hôm nay)');

    for (int i = 0; i < actualLength; i++) {
      try {
        await _generateExerciseListEveryDay(
          outtakeCalories: outtakeCalories,
          userWeight: userWeight,
          planID: planID,
          date: DateTime.now().add(Duration(days: i)),
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            _log('⚠️ Timeout khi tạo exercise collection cho ngày ${i + 1}');
            return;
          },
        );

        if (onProgress != null && (i + 1) % 10 == 0) {
          onProgress(i + 1, actualLength);
        }

        if (i < actualLength - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        _log('⚠️ Lỗi khi tạo exercise collection cho ngày ${i + 1}: $e');
      }
    }

    if (onProgress != null) {
      onProgress(actualLength, actualLength);
    }
    _log('✅ Hoàn tất tạo exercise collections cho $actualLength ngày');
  }

  Future<void> _generateExerciseListEveryDay(
      {required num outtakeCalories,
      required num userWeight,
      required int planID,
      required DateTime date}) async {
    // --- LOGIC 1: NGÀY NGHỈ (REST DAY) ---
    if (date.weekday == DateTime.tuesday ||
        date.weekday == DateTime.thursday ||
        date.weekday == DateTime.saturday) {
      print(
          '💤 Ngày nghỉ (Rest Day): ${date.toString().split(' ')[0]} - Không tạo bài tập');
      return;
    }

    // --- LOGIC 2: RANDOM SỐ LƯỢNG BÀI (3 đến 5 bài) ---
    final _random = Random();
    int numberOfExercise = _random.nextInt(3) + 3;
    int everyExerciseSeconds = 45;

    List<Workout> exerciseList = _randomExercises(numberOfExercise);

    if (exerciseList.isEmpty) {
      return;
    }

    double totalCalo = 0;
    for (var element in exerciseList) {
      double calo = SessionUtils.calculateCaloOneWorkout(
          everyExerciseSeconds, element.metValue, userWeight);
      totalCalo += calo;
    }

    if (totalCalo <= 0) {
      return;
    }

    int round = (outtakeCalories / totalCalo).ceil();
    if (round < 1) round = 1;
    if (round > 5) round = 5;

    List<String> exerciseIDs = exerciseList
        .where((e) => e.id != null && e.id!.isNotEmpty)
        .map((e) => e.id!)
        .toList();

    if (exerciseIDs.isEmpty) {
      return;
    }

    final _collectionProvider = PlanExerciseCollectionProvider();

    try {
      await _collectionProvider.createWithExercises(
        date: date,
        planID: planID,
        round: round,
        exerciseTime: everyExerciseSeconds,
        numOfWorkoutPerRound: numberOfExercise,
        exerciseIDs: exerciseIDs,
      );
      print(
          '✅ Đã tạo bài tập cho ngày ${date.toString().split(' ')[0]} ($numberOfExercise bài, $round hiệp)');
    } catch (e) {
      _log('❌ Lỗi khi tạo exercise collection: $e');
    }
  }

  List<Workout> _randomExercises(int numberOfExercise) {
    int count = 0;
    final _random = Random();
    List<Workout> result = [];

    final allExerciseList = DataService.instance.workoutList;

    if (allExerciseList.isEmpty) {
      _log('⚠️ Không có workout nào để tạo plan');
      return result;
    }
    final maxExercises = allExerciseList.length;
    final targetCount =
        numberOfExercise > maxExercises ? maxExercises : numberOfExercise;

    while (count < targetCount) {
      var element = allExerciseList[_random.nextInt(allExerciseList.length)];
      if (!result.contains(element)) {
        result.add(element);
        count++;
      }
    }

    return result;
  }

  /// Tạo meal collections cho số ngày cần thiết ngay lập tức
  Future<void> _generateMealListImmediate({
    required num intakeCalories,
    required int planID,
    required int days,
  }) async {
    _log('🍽️ Tạo meal collections cho $days ngày đầu tiên (immediate)');

    for (int i = 0; i < days; i++) {
      try {
        await _generateMealList(
          intakeCalories: intakeCalories,
          planID: planID,
          date: DateTime.now().add(Duration(days: i)),
        ).timeout(
          const Duration(seconds: 5), // Tăng timeout lên một chút
          onTimeout: () {
            _log('⚠️ Timeout khi tạo meal collection cho ngày ${i + 1}');
            return;
          },
        );
      } catch (e) {
        _log('⚠️ Lỗi khi tạo meal collection cho ngày ${i + 1}: $e');
      }
    }

    _log('✅ Hoàn tất tạo meal collections cho $days ngày đầu tiên');
  }

  /// Tạo collections còn lại trong background
  void _generateRemainingCollectionsInBackground({
    required int planID,
    required num intakeCalories,
    required num outtakeCalories,
    required num userWeight,
    required int startDay,
    required int totalDays,
  }) {
    Future(() async {
      print(
          '🔄 Bắt đầu tạo collections còn lại trong background (từ ngày $startDay đến $totalDays)');

      const int batchSize = 10;
      final int remainingDays = totalDays - startDay;

      for (int batchStart = 0;
          batchStart < remainingDays;
          batchStart += batchSize) {
        final int batchEnd = (batchStart + batchSize < remainingDays)
            ? batchStart + batchSize
            : remainingDays;

        print(
            '📦 Background: Tạo batch ${batchStart + 1}-$batchEnd/$remainingDays');

        List<Future<void>> futures = [];
        for (int i = batchStart; i < batchEnd; i++) {
          final dayIndex = startDay + i;
          futures.addAll([
            _generateMealList(
              intakeCalories: intakeCalories,
              planID: planID,
              date: DateTime.now().add(Duration(days: dayIndex)),
            ).catchError((e) {
              print(
                  '⚠️ Background: Lỗi khi tạo meal collection cho ngày $dayIndex: $e');
            }),
            _generateExerciseListEveryDay(
              outtakeCalories: outtakeCalories,
              userWeight: userWeight,
              planID: planID,
              date: DateTime.now().add(Duration(days: dayIndex)),
            ).catchError((e) {
              print(
                  '⚠️ Background: Lỗi khi tạo exercise collection cho ngày $dayIndex: $e');
            }),
          ]);
        }

        await Future.wait(futures, eagerError: false);

        if (batchEnd < remainingDays) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      _log('✅ Hoàn tất tạo collections còn lại trong background');
    }).catchError((e) {
      _log('❌ Lỗi khi tạo collections trong background: $e');
    });
  }

  Future<void> _generateMealList(
      {required num intakeCalories,
      required int planID,
      required DateTime date}) async {
    // SỬA ĐỔI QUAN TRỌNG: Sử dụng logic random mới
    List<Meal> mealList = await _randomMeals();

    if (mealList.isEmpty) {
      print(
          '⚠️ Không thể tạo meal list vì không tìm thấy món ăn nào. Bỏ qua ngày: $date');
      return;
    }

    num ratio = await _calculateMealRatio(intakeCalories, mealList);

    double validRatio = ratio.toDouble();
    if (!validRatio.isFinite || validRatio.isNaN) {
      _log('⚠️ Ratio không hợp lệ, sử dụng giá trị mặc định: 1.0');
      validRatio = 1.0;
    }

    PlanMealCollection collection =
        PlanMealCollection(date: date, planID: planID, mealRatio: validRatio);

    try {
      collection = (await PlanMealCollectionProvider().add(collection));

      final mealProvider = PlanMealProvider();
      if (collection.id != null && collection.id!.isNotEmpty) {
        for (var e in mealList) {
          if (e.id != null && e.id!.isNotEmpty) {
            PlanMeal meal = PlanMeal(mealID: e.id!, listID: collection.id!);
            await mealProvider.add(meal);
          }
        }
        print(
            '✅ Đã tạo thực đơn cho ngày ${date.toString().split(' ')[0]} (${mealList.length} món)');
      }
    } catch (e) {
      _log('❌ Lỗi khi tạo PlanMealCollection: $e');
    }
  }

  Future<double> _calculateMealRatio(
      num intakeCalories, List<Meal> mealList) async {
    if (mealList.isEmpty) {
      return 1.0;
    }

    num totalCalories = 0;
    for (var element in mealList) {
      var mealNutri = MealNutrition(meal: element);
      await mealNutri.getIngredients();
      totalCalories += mealNutri.calories;
    }

    if (totalCalories <= 0) {
      return 1.0;
    }

    double ratio = intakeCalories / totalCalories;

    if (!ratio.isFinite || ratio.isNaN) {
      return 1.0;
    }

    if (ratio < 0.1) return 0.1;
    if (ratio > 10.0) return 10.0;

    return ratio;
  }

  // --- HÀM RANDOM MEALS ĐÃ ĐƯỢC SỬA ĐỔI ---
  Future<List<Meal>> _randomMeals() async {
    List<Meal> result = [];
    final _random = Random();

    // 1. Đảm bảo dữ liệu đã load
    if (DataService.instance.mealList.isEmpty) {
      await DataService.instance.loadMealList(forceReload: false);
    }

    final allMeals = DataService.instance.mealList;

    if (allMeals.isEmpty) {
      _log('⚠️ Không có meal nào trong hệ thống để tạo plan');
      return result;
    }

    // 2. Logic Random đơn giản và mạnh mẽ hơn:
    // Lấy ngẫu nhiên 3 đến 4 món từ tổng danh sách (không phụ thuộc thứ tự category)
    int numberOfMeals = _random.nextInt(2) + 3; // Random 3 hoặc 4 món

    // Copy list để shuffle không ảnh hưởng list gốc
    List<Meal> tempList = List.from(allMeals);
    tempList.shuffle(_random);

    // Lấy n món đầu tiên
    result = tempList.take(numberOfMeals).toList();

    return result;
  }

  Future<void> _generateInitialPlanStreak(
      {required DateTime startDate,
      required int planLengthInDays,
      required int planID}) async {
    final streakProvider = StreakProvider();

    List<Streak> streaks = [];
    for (int i = 0; i < planLengthInDays; i++) {
      DateTime date = DateUtils.dateOnly(startDate.add(Duration(days: i)));
      Streak streak = Streak(date: date, value: false, planID: planID);
      streaks.add(streak);
    }

    await streakProvider.batchAdd(streaks);
  }

  Future<Map<int, List<bool>>> loadStreakList() async {
    int currentStreakDay = 0;
    WorkoutPlan? list = await WorkoutPlanProvider()
        .fetchByUserID(DataService.currentUser!.id ?? '');
    if (list != null) {
      var plan = list;
      final streakProvider = StreakProvider();

      List<Streak> streakInDB =
          await streakProvider.fetchByPlanID(plan.id ?? 0);

      streakInDB.sort((a, b) => a.date.compareTo(b.date));

      final startDate = DateUtils.dateOnly(plan.startDate);
      final endDate = DateUtils.dateOnly(plan.endDate);
      final planLengthInDays = endDate.difference(startDate).inDays + 1;

      final Map<DateTime, Streak> streakMap = {};
      for (var s in streakInDB) {
        final dateKey = DateUtils.dateOnly(s.date);
        streakMap[dateKey] = s;
      }

      List<Streak> missingStreaks = [];
      for (int i = 0; i < planLengthInDays; i++) {
        final checkDate = DateUtils.dateOnly(startDate.add(Duration(days: i)));
        if (!streakMap.containsKey(checkDate)) {
          missingStreaks.add(Streak(
            date: checkDate,
            planID: plan.id ?? 0,
            value: false,
          ));
        }
      }

      if (missingStreaks.isNotEmpty) {
        await streakProvider.batchAdd(missingStreaks);
        for (var s in missingStreaks) {
          streakMap[DateUtils.dateOnly(s.date)] = s;
        }
        streakInDB = await streakProvider.fetchByPlanID(plan.id ?? 0);
        streakInDB.sort((a, b) => a.date.compareTo(b.date));
      }

      List<bool> streak = [];
      DateTime today = DateUtils.dateOnly(DateTime.now());
      bool foundToday = false;
      int todayIndex = -1;

      for (int i = 0; i < planLengthInDays; i++) {
        final checkDate = DateUtils.dateOnly(startDate.add(Duration(days: i)));

        Streak? dayStreak = streakInDB.firstWhere(
          (s) => DateUtils.isSameDay(s.date, checkDate),
          orElse: () => Streak(
            date: checkDate,
            planID: plan.id ?? 0,
            value: false,
          ),
        );

        if (DateUtils.isSameDay(checkDate, today)) {
          todayIndex = i;
          foundToday = true;
        }

        streak.add(dayStreak.value);
      }

      if (!foundToday || todayIndex < 0) {
        currentStreakDay = 0;
      } else {
        int consecutiveStreak = 0;
        for (int i = todayIndex; i >= 0; i--) {
          if (streak[i] == true) {
            consecutiveStreak++;
          } else {
            break;
          }
        }
        currentStreakDay = consecutiveStreak > 0 ? consecutiveStreak : 0;
      }

      Map<int, List<bool>> map = {};
      map[currentStreakDay] = streak;
      return map;
    }

    return <int, List<bool>>{};
  }

  Future<void> resetRoute({
    Function(String message, int current, int total)? onProgress,
  }) async {
    var user = DataService.currentUser;

    if (user == null) {
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
            content:
                'Không tìm thấy dữ liệu người dùng! Hãy khởi động lại ứng dụng.',
            showOkButton: false,
            labelCancel: 'Đóng',
            onCancel: () => Navigator.of(context).pop(),
            onOk: () => Navigator.of(context).pop(),
            buttonsAlignment: MainAxisAlignment.center,
            buttonFactorOnMaxWidth: double.infinity,
          );
        },
      );
      return;
    }

    try {
      await (() async {
        final workoutPlan =
            await WorkoutPlanProvider().fetchByUserID(user.id ?? '');

        if (workoutPlan != null) {
          if (onProgress != null) {
            onProgress('Đang xóa dữ liệu cũ...', 0, 100);
          }

          final planID = workoutPlan.id ?? 0;
          await _deletePlanData(planID);

          if (workoutPlan.id != null) {
            await WorkoutPlanProvider().delete(workoutPlan.id!);
          }
        } else {
          if (onProgress != null) {
            onProgress('Đang tạo lộ trình mới...', 0, 100);
          }
        }

        await createRoute(user,
            onProgress: onProgress, skipInitialMessage: true);
      })()
          .timeout(
        const Duration(seconds: 40),
        onTimeout: () {
          throw TimeoutException(
              'Quá trình reset mất quá nhiều thời gian. Vui lòng thử lại sau.');
        },
      );
    } on TimeoutException catch (e) {
      _log('❌ Timeout khi reset route: $e');
      rethrow;
    } catch (e) {
      _log('❌ Lỗi khi reset route: $e');
      rethrow;
    }
  }

  Future<void> _deletePlanData(int planID) async {
    try {
      _log('🗑️ Bắt đầu xóa dữ liệu cho planID: $planID');

      final apiService = ApiService.instance;

      try {
        await Future.wait([
          apiService.deletePlanExerciseCollectionsByPlanID(planID).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              _log('⚠️ Timeout khi batch delete exercise collections');
              throw TimeoutException('Timeout');
            },
          ).then((_) {
            _log('✅ Đã xóa tất cả exercise collections cho planID: $planID');
          }).catchError((e) async {
            _log('⚠️ Lỗi khi batch delete exercise collections: $e');
            await _deleteExerciseCollectionsFallback(planID);
          }),
          apiService.deletePlanMealCollectionsByPlanID(planID).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              _log('⚠️ Timeout khi batch delete meal collections');
              throw TimeoutException('Timeout');
            },
          ).then((_) {
            _log('✅ Đã xóa tất cả meal collections cho planID: $planID');
          }).catchError((e) async {
            _log('⚠️ Lỗi khi batch delete meal collections: $e');
            await _deleteMealCollectionsFallback(planID);
          }),
        ], eagerError: false)
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print(
                '⚠️ Timeout khi xóa dữ liệu plan - tiếp tục với việc tạo mới');
            return <Null>[];
          },
        );
      } catch (e) {
        _log('⚠️ Lỗi khi xóa collections: $e - tiếp tục với việc tạo mới');
      }

      try {
        final streakProvider = StreakProvider();
        final streaks = await streakProvider.fetchByPlanID(planID);

        final deleteFutures = streaks
            .where((streak) => streak.id != null)
            .map((streak) => streakProvider.delete(streak.id!).catchError((e) {
                  _log('⚠️ Lỗi khi xóa streak ${streak.id}: $e');
                }));

        await Future.wait(deleteFutures).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            _log('⚠️ Timeout khi xóa streaks');
            return <Null>[];
          },
        );
      } catch (e) {
        _log('⚠️ Lỗi khi xóa streaks: $e');
      }

      _log('✅ Hoàn tất xóa dữ liệu cho planID: $planID');
    } catch (e) {
      _log('❌ Lỗi khi xóa dữ liệu plan: $e');
    }
  }

  Future<void> _deleteExerciseCollectionsFallback(int planID) async {
    try {
      final exerciseCollectionProvider = PlanExerciseCollectionProvider();
      final exerciseCollections =
          await exerciseCollectionProvider.fetchByPlanID(planID).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _log('⚠️ Timeout khi fetch exercise collections cho fallback');
          throw TimeoutException('Timeout');
        },
      );
      for (var collection in exerciseCollections) {
        if (collection.id != null && collection.id!.isNotEmpty) {
          try {
            await exerciseCollectionProvider.delete(collection.id!).timeout(
              const Duration(seconds: 3),
              onTimeout: () {
                print(
                    '⚠️ Timeout khi xóa exercise collection ${collection.id} (fallback)');
                throw TimeoutException('Timeout');
              },
            );
          } catch (e2) {
            _log('⚠️ Lỗi khi xóa exercise collection ${collection.id}: $e2');
          }
        }
      }
    } catch (e2) {
      _log('⚠️ Lỗi khi fallback delete exercise collections: $e2');
    }
  }

  Future<void> _deleteMealCollectionsFallback(int planID) async {
    try {
      final mealCollectionProvider = PlanMealCollectionProvider();
      final mealCollections =
          await mealCollectionProvider.fetchByPlanID(planID).timeout(
                const Duration(seconds: 3),
              );
      for (var collection in mealCollections) {
        if (collection.id != null && collection.id!.isNotEmpty) {
          try {
            await mealCollectionProvider.delete(collection.id!).timeout(
                  const Duration(seconds: 2),
                );
          } catch (e2) {
            _log('⚠️ Lỗi khi xóa meal collection ${collection.id}: $e2');
          }
        }
      }
    } catch (e2) {
      _log('⚠️ Lỗi khi fallback delete meal collections: $e2');
    }
  }
}
