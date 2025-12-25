import 'dart:async';
import 'dart:math';

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

class ExerciseNutritionRouteProvider {
  Future<void> createRoute(
    ViPTUser user, {
    Function(String message, int current, int total)? onProgress,
    bool skipInitialMessage = false, // Skip message đầu tiên nếu đã được set từ resetRoute
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
      
      // Lưu ý: Chúng ta vẫn lưu plan length đầy đủ, nhưng chỉ tạo collections cho 60 ngày đầu tiên
      // Collections khác sẽ được tạo khi cần (lazy loading)
      print('📋 Plan length: $workoutPlanLengthInDays ngày (sẽ tạo collections cho 60 ngày đầu tiên)');

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

      // Tạo streaks cho toàn bộ plan trước (streak chỉ là dữ liệu local, rất nhanh)
      if (onProgress != null) {
        onProgress('Đang tạo streak...', 30, 100);
      }
      
      await _generateInitialPlanStreak(
          planID: planID,
          startDate: workoutPlanStartDate,
          planLengthInDays: workoutPlanLengthInDays);

      // CHỈ TẠO 3 NGÀY ĐẦU TIÊN ngay lập tức (nhanh hơn, đủ cho vài ngày đầu)
      // Các ngày còn lại sẽ được tạo trong background
      const int immediateDays = 3;
      
      if (onProgress != null) {
        onProgress('Đang tạo kế hoạch cho vài ngày đầu...', 50, 100);
      }
      
      // Tạo 3 ngày đầu song song cho nhanh (với timeout hợp lý)
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
          print('⚠️ Timeout khi tạo 3 ngày đầu - tiếp tục với dữ liệu hiện có');
          return <void>[];
        },
      );

      final _pefs = await SharedPreferences.getInstance();
      await _pefs.setBool('planStatus', false);

      if (onProgress != null) {
        onProgress('Hoàn tất!', 100, 100);
      }
      
      // Tạo collections còn lại trong background (không chặn UI)
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
      print('❌ Lỗi khi tạo route: $e');
      rethrow;
    }
  }

  /// Tạo exercise collections cho số ngày cần thiết ngay lập tức (dùng khi reset)
  Future<void> generateExerciseListImmediate({
    required num outtakeCalories,
    required int planID,
    required num userWeight,
    required int days,
  }) async {
    print('📅 Tạo exercise collections cho $days ngày đầu tiên (immediate)');
    
    // Tạo tuần tự để đảm bảo ổn định (không quá tải server)
    for (int i = 0; i < days; i++) {
      try {
        await _generateExerciseListEveryDay(
          outtakeCalories: outtakeCalories,
          userWeight: userWeight,
          planID: planID,
          date: DateTime.now().add(Duration(days: i)),
        ).timeout(
          const Duration(seconds: 8), // Tăng timeout lên 8 giây để backend có đủ thời gian xử lý
          onTimeout: () {
            print('⚠️ Timeout khi tạo exercise collection cho ngày ${i + 1}');
            return;
          },
        );
      } catch (e) {
        print('⚠️ Lỗi khi tạo exercise collection cho ngày ${i + 1}: $e');
        // Tiếp tục với ngày tiếp theo
      }
    }
    
    print('✅ Hoàn tất tạo exercise collections cho $days ngày đầu tiên');
  }

  Future<void> generateExerciseListWithPlanLength({
    required num outtakeCalories,
    required int planID,
    required num userWeight,
    required int workoutPlanLength,
    Function(int current, int total)? onProgress,
  }) async {
    // CHỈ TẠO CHO 60 NGÀY TIẾP THEO (từ hôm nay)
    // Tương ứng với cách loadPlanExerciseCollectionList chỉ load 60 ngày
    final int actualLength = 60; // Chỉ tạo 60 ngày tiếp theo
    
    print('📅 Tạo exercise collections cho $actualLength ngày tiếp theo (từ hôm nay)');
    
    // Tạo tuần tự (một ngày một lần) để tránh quá tải server
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
            print('⚠️ Timeout khi tạo exercise collection cho ngày ${i + 1}');
            return;
          },
        );
        
        // Báo cáo tiến trình mỗi 10 ngày
        if (onProgress != null && (i + 1) % 10 == 0) {
          onProgress(i + 1, actualLength);
        }
        
        // Nghỉ ngắn giữa mỗi request để tránh quá tải
        if (i < actualLength - 1) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      } catch (e) {
        print('⚠️ Lỗi khi tạo exercise collection cho ngày ${i + 1}: $e');
        // Tiếp tục với ngày tiếp theo
      }
    }
    
    // Báo cáo hoàn tất
    if (onProgress != null) {
      onProgress(actualLength, actualLength);
    }
    
    print('✅ Hoàn tất tạo exercise collections cho $actualLength ngày');
  }

  Future<void> _generateExerciseListEveryDay(
      {required num outtakeCalories,
      required num userWeight,
      required int planID,
      required DateTime date}) async {
    int numberOfExercise = 10;
    int everyExerciseSeconds = 45;
    List<Workout> exerciseList1 = _randomExercises(numberOfExercise);
    List<Workout> exerciseList2 = _randomExercises(numberOfExercise);

    if (exerciseList1.isEmpty || exerciseList2.isEmpty) {
      return;
    }

    double totalCalo1 = 0;
    for (var element in exerciseList1) {
      double calo = SessionUtils.calculateCaloOneWorkout(
          everyExerciseSeconds, element.metValue, userWeight);
      totalCalo1 += calo;
    }

    double totalCalo2 = 0;
    for (var element in exerciseList2) {
      double calo = SessionUtils.calculateCaloOneWorkout(
          everyExerciseSeconds, element.metValue, userWeight);
      totalCalo2 += calo;
    }

    if (totalCalo1 <= 0 || totalCalo2 <= 0) {
      return;
    }

    int round1 = ((outtakeCalories / 2) / totalCalo1).ceil();
    int round2 = ((outtakeCalories / 2) / totalCalo2).ceil();

    // Đảm bảo round >= 1
    if (round1 < 1) round1 = 1;
    if (round2 < 1) round2 = 1;

    // Lấy danh sách exercise IDs
    List<String> exerciseIDs1 = exerciseList1
        .where((e) => e.id != null && e.id!.isNotEmpty)
        .map((e) => e.id!)
        .toList();
    List<String> exerciseIDs2 = exerciseList2
        .where((e) => e.id != null && e.id!.isNotEmpty)
        .map((e) => e.id!)
        .toList();

    // Kiểm tra exerciseIDs không rỗng
    if (exerciseIDs1.isEmpty || exerciseIDs2.isEmpty) {
      print('⚠️ Không thể tạo exercise collection vì không có exercise IDs hợp lệ');
      return;
    }

    // Sử dụng createWithExercises để tạo collection cùng với setting và exercises
    final _collectionProvider = PlanExerciseCollectionProvider();
    
    try {
      await _collectionProvider.createWithExercises(
        date: date,
        planID: planID,
        round: round1,
        exerciseTime: everyExerciseSeconds,
        numOfWorkoutPerRound: numberOfExercise,
        exerciseIDs: exerciseIDs1,
      );
    } catch (e) {
      print('❌ Lỗi khi tạo exercise collection 1: $e');
      // Tiếp tục tạo collection 2 dù collection 1 lỗi
    }

    try {
      await _collectionProvider.createWithExercises(
        date: date,
        planID: planID,
        round: round2,
        exerciseTime: everyExerciseSeconds,
        numOfWorkoutPerRound: numberOfExercise,
        exerciseIDs: exerciseIDs2,
      );
    } catch (e) {
      print('❌ Lỗi khi tạo exercise collection 2: $e');
    }
  }

  List<Workout> _randomExercises(int numberOfExercise) {
    int count = 0;
    final _random = Random();
    List<Workout> result = [];
    
    // Đảm bảo workout list đã được load (không force reload)
    final allExerciseList = DataService.instance.workoutList;

    if (allExerciseList.isEmpty) {
      print('⚠️ Không có workout nào để tạo plan');
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

  /// Tạo meal collections cho số ngày cần thiết ngay lập tức (dùng khi reset)
  Future<void> _generateMealListImmediate({
    required num intakeCalories,
    required int planID,
    required int days,
  }) async {
    print('🍽️ Tạo meal collections cho $days ngày đầu tiên (immediate)');
    
    // Tạo tuần tự để đảm bảo ổn định và nhanh hơn (không quá tải server)
    for (int i = 0; i < days; i++) {
      try {
        await _generateMealList(
          intakeCalories: intakeCalories,
          planID: planID,
          date: DateTime.now().add(Duration(days: i)),
        ).timeout(
          const Duration(seconds: 3), // Giảm timeout xuống 3 giây
          onTimeout: () {
            print('⚠️ Timeout khi tạo meal collection cho ngày ${i + 1}');
            return;
          },
        );
      } catch (e) {
        print('⚠️ Lỗi khi tạo meal collection cho ngày ${i + 1}: $e');
        // Tiếp tục với ngày tiếp theo
      }
    }
    
    print('✅ Hoàn tất tạo meal collections cho $days ngày đầu tiên');
  }

  
  /// Tạo collections còn lại trong background (không chặn UI)
  void _generateRemainingCollectionsInBackground({
    required int planID,
    required num intakeCalories,
    required num outtakeCalories,
    required num userWeight,
    required int startDay,
    required int totalDays,
  }) {
    // Chạy trong background, không await
    Future(() async {
      print('🔄 Bắt đầu tạo collections còn lại trong background (từ ngày $startDay đến $totalDays)');
      
      const int batchSize = 10;
      final int remainingDays = totalDays - startDay;
      
      for (int batchStart = 0; batchStart < remainingDays; batchStart += batchSize) {
        final int batchEnd = (batchStart + batchSize < remainingDays) 
            ? batchStart + batchSize 
            : remainingDays;
        
        print('📦 Background: Tạo batch ${batchStart + 1}-$batchEnd/$remainingDays');
        
        // Tạo song song trong batch
        List<Future<void>> futures = [];
        for (int i = batchStart; i < batchEnd; i++) {
          final dayIndex = startDay + i;
          futures.addAll([
            _generateMealList(
              intakeCalories: intakeCalories,
              planID: planID,
              date: DateTime.now().add(Duration(days: dayIndex)),
            ).catchError((e) {
              print('⚠️ Background: Lỗi khi tạo meal collection cho ngày $dayIndex: $e');
            }),
            _generateExerciseListEveryDay(
              outtakeCalories: outtakeCalories,
              userWeight: userWeight,
              planID: planID,
              date: DateTime.now().add(Duration(days: dayIndex)),
            ).catchError((e) {
              print('⚠️ Background: Lỗi khi tạo exercise collection cho ngày $dayIndex: $e');
            }),
          ]);
        }
        
        await Future.wait(futures, eagerError: false);
        
        // Nghỉ giữa các batch để tránh quá tải
        if (batchEnd < remainingDays) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      print('✅ Hoàn tất tạo collections còn lại trong background');
    }).catchError((e) {
      print('❌ Lỗi khi tạo collections trong background: $e');
    });
  }

  Future<void> _generateMealList(
      {required num intakeCalories,
      required int planID,
      required DateTime date}) async {
    List<Meal> mealList = await _randomMeals();
    
    // Kiểm tra mealList không rỗng
    if (mealList.isEmpty) {
      print('⚠️ Không thể tạo meal list vì không có meal nào. Bỏ qua ngày: $date');
      return;
    }
    
    num ratio = await _calculateMealRatio(intakeCalories, mealList);
    
    // Đảm bảo ratio hợp lệ trước khi tạo collection
    double validRatio = ratio.toDouble();
    if (!validRatio.isFinite || validRatio.isNaN) {
      print('⚠️ Ratio không hợp lệ, sử dụng giá trị mặc định: 1.0');
      validRatio = 1.0;
    }

    PlanMealCollection collection = PlanMealCollection(
        date: date, planID: planID, mealRatio: validRatio);
    collection = (await PlanMealCollectionProvider().add(collection));

    final mealProvider = PlanMealProvider();
    if (collection.id != null && collection.id!.isNotEmpty) {
      for (var e in mealList) {
        if (e.id != null && e.id!.isNotEmpty) {
          PlanMeal meal = PlanMeal(mealID: e.id!, listID: collection.id!);
          await mealProvider.add(meal);
        }
      }
    }
  }

  Future<double> _calculateMealRatio(
      num intakeCalories, List<Meal> mealList) async {
    // Kiểm tra mealList không rỗng
    if (mealList.isEmpty) {
      print('⚠️ Meal list rỗng, sử dụng mealRatio mặc định: 1.0');
      return 1.0;
    }
    
    num totalCalories = 0;
    for (var element in mealList) {
      var mealNutri = MealNutrition(meal: element);
      await mealNutri.getIngredients();
      totalCalories += mealNutri.calories;
    }

    // Kiểm tra totalCalories > 0 để tránh chia cho 0
    if (totalCalories <= 0) {
      print('⚠️ Total calories = 0 hoặc âm, sử dụng mealRatio mặc định: 1.0');
      return 1.0;
    }

    double ratio = intakeCalories / totalCalories;
    
    // Kiểm tra ratio hợp lệ (không phải Infinity hoặc NaN)
    if (!ratio.isFinite || ratio.isNaN) {
      print('⚠️ MealRatio không hợp lệ (Infinity/NaN), sử dụng giá trị mặc định: 1.0');
      return 1.0;
    }
    
    // Giới hạn ratio trong khoảng hợp lý (0.1 đến 10.0)
    if (ratio < 0.1) {
      print('⚠️ MealRatio quá nhỏ ($ratio), giới hạn về 0.1');
      return 0.1;
    }
    if (ratio > 10.0) {
      print('⚠️ MealRatio quá lớn ($ratio), giới hạn về 10.0');
      return 10.0;
    }

    return ratio;
  }

  Future<List<Meal>> _randomMeals() async {
    List<Meal> result = [];
    final _random = Random();

    // Đảm bảo meal list và categories đã được load (không force reload)
    if (DataService.instance.mealList.isEmpty) {
      // Chỉ load nếu chưa có, không force reload
      await DataService.instance.loadMealList(forceReload: false);
    }
    
    if (DataService.instance.mealCategoryList.isEmpty) {
      await DataService.instance.loadMealCategoryList();
    }

    if (DataService.instance.mealList.isEmpty) {
      print('⚠️ Không có meal nào để tạo plan');
      return result;
    }

    List<String> mealCategoryIDs =
        DataService.instance.mealCategoryList.map((e) => e.id ?? '').toList();

    if (mealCategoryIDs.length < 3) {
      print('⚠️ Không đủ meal categories (cần ít nhất 3)');
      return result;
    }

    final breakfastList = DataService.instance.mealList
        .where((element) => element.categoryIDs.contains(mealCategoryIDs[0]))
        .toList();
    final lunchDinnerList = DataService.instance.mealList
        .where((element) => element.categoryIDs.contains(mealCategoryIDs[1]))
        .toList();
    final snackList = DataService.instance.mealList
        .where((element) => element.categoryIDs.contains(mealCategoryIDs[2]))
        .toList();

    if (breakfastList.isEmpty) {
      return result;
    }

    if (lunchDinnerList.isEmpty) {
      return result;
    }

    if (snackList.isEmpty) {
      return result;
    }

    var breakfastMeal = breakfastList[_random.nextInt(breakfastList.length)];
    if (!result.contains(breakfastMeal)) {
      result.add(breakfastMeal);
    }

    var lunchDinnerMeal =
        lunchDinnerList[_random.nextInt(lunchDinnerList.length)];
    if (!result.contains(lunchDinnerMeal)) {
      result.add(lunchDinnerMeal);
    }

    var snackMeal = snackList[_random.nextInt(snackList.length)];
    if (!result.contains(snackMeal)) {
      result.add(snackMeal);
    }
    return result;
  }

  Future<void> _generateInitialPlanStreak(
      {required DateTime startDate,
      required int planLengthInDays,
      required int planID}) async {
    // final _prefs = await SharedPreferences.getInstance();
    final streakProvider = StreakProvider();

    // Tạo tất cả streaks trước
    List<Streak> streaks = [];
    for (int i = 0; i < planLengthInDays; i++) {
      DateTime date = DateUtils.dateOnly(startDate.add(Duration(days: i)));
      Streak streak = Streak(date: date, value: false, planID: planID);
      streaks.add(streak);
    }
    
    // Batch insert tất cả cùng lúc (nhanh hơn nhiều)
    await streakProvider.batchAdd(streaks);
  }

  Future<Map<int, List<bool>>> loadStreakList() async {
    int currentStreakDay = 0;
    WorkoutPlan? list = await WorkoutPlanProvider()
        .fetchByUserID(DataService.currentUser!.id ?? '');
    if (list != null) {
      var plan = list;
      final streakProvider = StreakProvider();
      
      // Lấy tất cả streak từ database
      List<Streak> streakInDB =
          await streakProvider.fetchByPlanID(plan.id ?? 0);

      // Sắp xếp streak theo date để đảm bảo thứ tự đúng
      streakInDB.sort((a, b) => a.date.compareTo(b.date));

      // Tính số ngày trong plan
      final startDate = DateUtils.dateOnly(plan.startDate);
      final endDate = DateUtils.dateOnly(plan.endDate);
      final planLengthInDays = endDate.difference(startDate).inDays + 1;
      
      // Tạo map để dễ dàng tìm streak theo date
      final Map<DateTime, Streak> streakMap = {};
      for (var s in streakInDB) {
        final dateKey = DateUtils.dateOnly(s.date);
        streakMap[dateKey] = s;
      }
      
      // Đảm bảo tất cả các ngày từ startDate đến endDate đều có streak
      List<Streak> missingStreaks = [];
      for (int i = 0; i < planLengthInDays; i++) {
        final checkDate = DateUtils.dateOnly(startDate.add(Duration(days: i)));
        if (!streakMap.containsKey(checkDate)) {
          // Tạo streak mới cho ngày này
          missingStreaks.add(Streak(
            date: checkDate,
            planID: plan.id ?? 0,
            value: false,
          ));
        }
      }
      
      // Batch insert các streak còn thiếu
      if (missingStreaks.isNotEmpty) {
        await streakProvider.batchAdd(missingStreaks);
        // Thêm vào streakMap để sử dụng sau
        for (var s in missingStreaks) {
          streakMap[DateUtils.dateOnly(s.date)] = s;
        }
        // Reload lại từ database để có ID
        streakInDB = await streakProvider.fetchByPlanID(plan.id ?? 0);
        streakInDB.sort((a, b) => a.date.compareTo(b.date));
      }

      // Tạo danh sách streak values cho tất cả các ngày
      List<bool> streak = [];
      DateTime today = DateUtils.dateOnly(DateTime.now());
      bool foundToday = false;
      int todayIndex = -1;
      
      for (int i = 0; i < planLengthInDays; i++) {
        final checkDate = DateUtils.dateOnly(startDate.add(Duration(days: i)));
        
        // Tìm streak cho ngày này
        Streak? dayStreak = streakInDB.firstWhere(
          (s) => DateUtils.isSameDay(s.date, checkDate),
          orElse: () => Streak(
            date: checkDate,
            planID: plan.id ?? 0,
            value: false,
          ),
        );
        
        if (DateUtils.isSameDay(checkDate, today)) {
          todayIndex = i; // Lưu index của ngày hôm nay
          foundToday = true;
        }
        
        streak.add(dayStreak.value);
      }
      
      // Tính currentStreakDay dựa trên streak liên tiếp từ hôm nay đếm ngược
      // Nếu hôm nay chưa đạt mục tiêu, streak = 0
      // Nếu hôm nay đã đạt mục tiêu, đếm ngược bao nhiêu ngày liên tiếp đã đạt mục tiêu
      if (!foundToday || todayIndex < 0) {
        // Nếu không tìm thấy ngày hiện tại trong plan (plan đã kết thúc hoặc chưa bắt đầu)
        currentStreakDay = 0;
      } else {
        // Kiểm tra streak liên tiếp từ hôm nay đếm ngược
        int consecutiveStreak = 0;
        
        // Đếm ngược từ hôm nay về trước
        for (int i = todayIndex; i >= 0; i--) {
          if (streak[i] == true) {
            // Ngày này đã đạt mục tiêu
            consecutiveStreak++;
          } else {
            // Gặp ngày chưa đạt mục tiêu, dừng lại
            break;
          }
        }
        
        // currentStreakDay = số ngày liên tiếp đã đạt mục tiêu (bắt đầu từ 1)
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
      // Timeout tổng thể cho toàn bộ quá trình reset (15 giây - đủ cho 7 ngày đầu)
      await (() async {
        // Tìm workout plan của user hiện tại
        final workoutPlan = await WorkoutPlanProvider().fetchByUserID(user.id ?? '');
        
        if (workoutPlan != null) {
          // Có plan cũ, cần xóa trước
          if (onProgress != null) {
            onProgress('Đang xóa dữ liệu cũ...', 0, 100);
          }
          
          final planID = workoutPlan.id ?? 0;
          
          // Xóa tất cả dữ liệu liên quan đến plan này
          await _deletePlanData(planID);
          
          // Xóa workout plan
          if (workoutPlan.id != null) {
            await WorkoutPlanProvider().delete(workoutPlan.id!);
          }
        } else {
          // Không có plan cũ, chỉ cần tạo mới (trường hợp người dùng mới)
          if (onProgress != null) {
            onProgress('Đang tạo lộ trình mới...', 0, 100);
          }
        }

        // Tạo route mới (hoặc tạo lần đầu) với progress callback
        // skipInitialMessage = true vì đã set message ở trên rồi
        await createRoute(user, onProgress: onProgress, skipInitialMessage: true);
      })().timeout(
        const Duration(seconds: 40), // Tăng timeout tổng thể lên 40 giây để đủ thời gian cho 3 ngày đầu + buffer
        onTimeout: () {
          throw TimeoutException('Quá trình reset mất quá nhiều thời gian. Vui lòng thử lại sau.');
        },
      );
    } on TimeoutException catch (e) {
      print('❌ Timeout khi reset route: $e');
      rethrow;
    } catch (e) {
      print('❌ Lỗi khi reset route: $e');
      rethrow;
    }
  }

  /// Xóa tất cả dữ liệu liên quan đến một planID cụ thể (sử dụng batch delete để tối ưu)
  Future<void> _deletePlanData(int planID) async {
    try {
      print('🗑️ Bắt đầu xóa dữ liệu cho planID: $planID');
      
      final apiService = ApiService.instance;
      
      // Xóa song song để nhanh hơn
      try {
        await Future.wait([
          // 1. Batch delete tất cả PlanExerciseCollections
          apiService.deletePlanExerciseCollectionsByPlanID(planID).timeout(
            const Duration(seconds: 10), // Tăng timeout lên 10 giây
            onTimeout: () {
              print('⚠️ Timeout khi batch delete exercise collections');
              throw TimeoutException('Timeout');
            },
          ).then((_) {
            print('✅ Đã xóa tất cả exercise collections cho planID: $planID');
          }).catchError((e) async {
            print('⚠️ Lỗi khi batch delete exercise collections: $e');
            // Fallback: xóa từng cái nếu batch delete thất bại - AWAIT để đảm bảo hoàn tất
            await _deleteExerciseCollectionsFallback(planID);
          }),
          
          // 2. Batch delete tất cả PlanMealCollections
          apiService.deletePlanMealCollectionsByPlanID(planID).timeout(
            const Duration(seconds: 10), // Tăng timeout lên 10 giây
            onTimeout: () {
              print('⚠️ Timeout khi batch delete meal collections');
              throw TimeoutException('Timeout');
            },
          ).then((_) {
            print('✅ Đã xóa tất cả meal collections cho planID: $planID');
          }).catchError((e) async {
            print('⚠️ Lỗi khi batch delete meal collections: $e');
            // Fallback: xóa từng cái nếu batch delete thất bại - AWAIT để đảm bảo hoàn tất
            await _deleteMealCollectionsFallback(planID);
          }),
        ], eagerError: false).timeout(
          const Duration(seconds: 15), // Tăng timeout tổng thể lên 15 giây
          onTimeout: () {
            print('⚠️ Timeout khi xóa dữ liệu plan - tiếp tục với việc tạo mới');
            return <Null>[];
          },
        );
      } catch (e) {
        print('⚠️ Lỗi khi xóa collections: $e - tiếp tục với việc tạo mới');
      }

      // 3. Xóa Streaks của plan này (local database, nhanh)
      try {
        final streakProvider = StreakProvider();
        final streaks = await streakProvider.fetchByPlanID(planID);
        print('🔥 Tìm thấy ${streaks.length} streaks');
        
        // Xóa song song để tăng tốc độ
        final deleteFutures = streaks
            .where((streak) => streak.id != null)
            .map((streak) => streakProvider.delete(streak.id!).catchError((e) {
                  print('⚠️ Lỗi khi xóa streak ${streak.id}: $e');
                }));
        
        await Future.wait(deleteFutures).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Timeout khi xóa streaks');
            return <Null>[];
          },
        );
      } catch (e) {
        print('⚠️ Lỗi khi xóa streaks: $e');
      }
      
      print('✅ Hoàn tất xóa dữ liệu cho planID: $planID');
    } catch (e) {
      print('❌ Lỗi khi xóa dữ liệu plan: $e');
      // Không rethrow để tránh crash, nhưng log lỗi
      // Tiếp tục tạo plan mới ngay cả khi xóa không thành công
    }
  }
  
  /// Fallback: Xóa exercise collections từng cái một
  Future<void> _deleteExerciseCollectionsFallback(int planID) async {
    try {
      final exerciseCollectionProvider = PlanExerciseCollectionProvider();
      final exerciseCollections = await exerciseCollectionProvider.fetchByPlanID(planID).timeout(
        const Duration(seconds: 5), // Tăng timeout lên 5 giây
        onTimeout: () {
          print('⚠️ Timeout khi fetch exercise collections cho fallback');
          throw TimeoutException('Timeout');
        },
      );
      for (var collection in exerciseCollections) {
        if (collection.id != null && collection.id!.isNotEmpty) {
          try {
            await exerciseCollectionProvider.delete(collection.id!).timeout(
              const Duration(seconds: 3), // Tăng timeout lên 3 giây
              onTimeout: () {
                print('⚠️ Timeout khi xóa exercise collection ${collection.id} (fallback)');
                throw TimeoutException('Timeout');
              },
            );
          } catch (e2) {
            print('⚠️ Lỗi khi xóa exercise collection ${collection.id}: $e2');
          }
        }
      }
    } catch (e2) {
      print('⚠️ Lỗi khi fallback delete exercise collections: $e2');
    }
  }
  
  /// Fallback: Xóa meal collections từng cái một
  Future<void> _deleteMealCollectionsFallback(int planID) async {
    try {
      final mealCollectionProvider = PlanMealCollectionProvider();
      final mealCollections = await mealCollectionProvider.fetchByPlanID(planID).timeout(
        const Duration(seconds: 3),
      );
      for (var collection in mealCollections) {
        if (collection.id != null && collection.id!.isNotEmpty) {
          try {
            await mealCollectionProvider.delete(collection.id!).timeout(
              const Duration(seconds: 2),
            );
          } catch (e2) {
            print('⚠️ Lỗi khi xóa meal collection ${collection.id}: $e2');
          }
        }
      }
    } catch (e2) {
      print('⚠️ Lỗi khi fallback delete meal collections: $e2');
    }
  }
}

