import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/utilities/utils.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

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
      
      print('📥 Loading recommendation preview...');
      final data = await apiService.getPlanPreview();
      print('📦 Recommendation data received: ${data.keys.toList()}');
      print('📊 Plan length: ${data['planLengthInDays']} days');
      print('🔥 Daily calories: ${data['dailyGoalCalories']} kcal');
      print('🏋️ Exercises count: ${(data['exercises'] as List?)?.length ?? 0}');
      print('🍽️ Meals count: ${(data['meals'] as List?)?.length ?? 0}');
      
      recommendationData.assignAll(data);
      
      // Load exercises
      if (data['exercises'] != null && (data['exercises'] as List).isNotEmpty) {
        final exercisesList = (data['exercises'] as List)
            .map((e) {
              final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
              return Workout.fromMap(map['_id'] ?? map['id'] ?? '', map);
            })
            .toList();
        recommendedExercises.assignAll(exercisesList);
        print('✅ Loaded ${exercisesList.length} exercises');
      } else {
        print('⚠️ No exercises in response');
      }
      
      // Load meals
      if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
        final mealsList = (data['meals'] as List)
            .map((e) {
              final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e);
              return Meal.fromMap(map['_id'] ?? map['id'] ?? '', map);
            })
            .toList();
        recommendedMeals.assignAll(mealsList);
        print('✅ Loaded ${mealsList.length} meals');
      } else {
        print('⚠️ No meals in response');
      }
      
      isLoading.value = false;
    } catch (e, stackTrace) {
      errorMessage = 'Không thể tải đề xuất: ${e.toString()}';
      isLoading.value = false;
      print('❌ Lỗi khi load recommendation: $e');
      print('📍 Stack trace: $stackTrace');
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
        endDate: data['endDate'] != null
            ? DateTime.parse(data['endDate'])
            : null,
      );
      
      // Load data sau khi tạo plan
      await DataService.instance.loadWorkoutList();
      await DataService.instance.loadMealList();
      await DataService.instance.loadMealCategoryList();
      
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
      
      print('❌ Lỗi khi tạo plan: $e');
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
  int get dailyIntakeCalories => (recommendationData['dailyIntakeCalories'] ?? 0).toInt();
  int get dailyOuttakeCalories => (recommendationData['dailyOuttakeCalories'] ?? 0).toInt();
  int get dailyGoalCalories => (recommendationData['dailyGoalCalories'] ?? 0).toInt();
  String get startDate => formatDate(recommendationData['startDate']);
  String get endDate => formatDate(recommendationData['endDate']);
}

