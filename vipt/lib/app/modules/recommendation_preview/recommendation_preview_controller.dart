import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/utilities/utils.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

// Tắt log để tăng tốc độ - chỉ bật khi cần debug
const bool _enableLogging = false;
void _log(String message) {
  if (_enableLogging && kDebugMode) {
    print(message);
  }
}

class RecommendationPreviewController extends GetxController {
  final apiService = ApiService.instance;

  RxBool isLoading = true.obs;
  RxBool isCreatingPlan = false.obs;
  RxMap<String, dynamic> recommendationData = <String, dynamic>{}.obs;
  RxList<Workout> recommendedExercises = <Workout>[].obs;
  RxList<Meal> recommendedMeals = <Meal>[].obs;

  String? errorMessage;

  @override
  void onInit() {
    super.onInit();
    loadRecommendation();
  }

  Future<void> loadRecommendation() async {
    try {
      isLoading.value = true;
      errorMessage = null;

      _log('📥 Loading recommendation preview...');
      final data = await apiService.getPlanPreview();
      _log('📦 Recommendation data received: ${data.keys.toList()}');

      recommendationData.assignAll(data);

      // Load exercises
      if (data['exercises'] != null && (data['exercises'] as List).isNotEmpty) {
        final exercisesList = (data['exercises'] as List).map((e) {
          final map =
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
          return Workout.fromMap(map['_id'] ?? map['id'] ?? '', map);
        }).toList();
        recommendedExercises.assignAll(exercisesList);
        _log('✅ Loaded ${exercisesList.length} exercises');
      }

      // Load meals
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        final mealsList = (data['meals'] as List).map((e) {
          final map =
              e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
          return Meal.fromMap(map['_id'] ?? map['id'] ?? '', map);
        }).toList();
        recommendedMeals.assignAll(mealsList);
        _log('✅ Loaded ${mealsList.length} meals');
      }

      isLoading.value = false;
    } catch (e) {
      errorMessage = 'Không thể tải đề xuất: ${e.toString()}';
      isLoading.value = false;
      _log('❌ Lỗi khi load recommendation: $e');
    }
  }

  Future<void> regenerateRecommendation() async {
    await loadRecommendation();
  }

  Future<void> confirmAndCreatePlan() async {
    try {
      isCreatingPlan.value = true;
      UIUtils.showLoadingDialog();

      final data = Map<String, dynamic>.from(recommendationData);

      // Create plan from recommendation
      await apiService.createPlanFromRecommendation(
        planLengthInDays: data['planLengthInDays'] as int,
        dailyGoalCalories: data['dailyGoalCalories'] as num,
        dailyIntakeCalories: data['dailyIntakeCalories'] as num,
        dailyOuttakeCalories: data['dailyOuttakeCalories'] as num,
        recommendedExerciseIDs: (data['recommendedExerciseIDs'] as List)
            .map((e) => e.toString())
            .toList(),
        recommendedMealIDs: (data['recommendedMealIDs'] as List)
            .map((e) => e.toString())
            .toList(),
        startDate: data['startDate'] != null
            ? DateTime.parse(data['startDate'])
            : DateTime.now(),
        endDate:
            data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      );

      // Load data sau khi tạo plan - chạy song song để tăng tốc
      await Future.wait<void>([
        DataService.instance.loadWorkoutList(),
        DataService.instance.loadMealList(),
        DataService.instance.loadMealCategoryList(),
      ]);

      // Bắt đầu lắng nghe real-time streams
      DataService.instance.startListeningToStreams();
      DataService.instance.startListeningToUserCollections();

      UIUtils.hideLoadingDialog();
      isCreatingPlan.value = false;

      // Navigate to home
      Get.offAllNamed(Routes.home);
    } catch (e) {
      UIUtils.hideLoadingDialog();
      isCreatingPlan.value = false;

      Get.snackbar(
        'Lỗi',
        'Không thể tạo lộ trình: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      _log('❌ Lỗi khi tạo plan: $e');
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  int get planLengthInDays => recommendationData['planLengthInDays'] ?? 0;
  int get bmr => (recommendationData['bmr'] ?? 0).toInt();
  int get tdee => (recommendationData['tdee'] ?? 0).toInt();
  int get dailyIntakeCalories =>
      (recommendationData['dailyIntakeCalories'] ?? 0).toInt();
  int get dailyOuttakeCalories =>
      (recommendationData['dailyOuttakeCalories'] ?? 0).toInt();
  int get dailyGoalCalories =>
      (recommendationData['dailyGoalCalories'] ?? 0).toInt();
  String get startDate => formatDate(recommendationData['startDate']);
  String get endDate => formatDate(recommendationData['endDate']);
}
