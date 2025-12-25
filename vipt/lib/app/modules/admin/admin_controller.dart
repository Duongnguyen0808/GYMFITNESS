import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/data/providers/ingredient_provider_api.dart';
import 'package:vipt/app/data/providers/workout_equipment_provider_api.dart';
import 'package:vipt/app/data/providers/workout_collection_category_provider_api.dart';
import 'package:vipt/app/data/services/data_service.dart';

class AdminController extends GetxController {
  var isLoadingIngredients = false.obs;
  var isLoadingMeals = false.obs;
  var isLoadingEquipment = false.obs;
  var isLoadingCategories = false.obs;
  var isSyncing = false.obs;

  final IngredientProvider _ingredientProvider = IngredientProvider();
  final WorkoutEquipmentProvider _equipmentProvider = WorkoutEquipmentProvider();
  final WorkoutCollectionCategoryProvider _categoryProvider = WorkoutCollectionCategoryProvider();

  // Sync data to DataService cache (for mobile app to see changes)
  Future<void> syncMealDataToCache() async {
    isSyncing.value = true;
    try {
      await DataService.instance.reloadMealData();
      Get.snackbar(
        '✅ Đồng bộ thành công',
        'Dữ liệu món ăn đã được cập nhật cho mobile app',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi đồng bộ',
        'Không thể đồng bộ dữ liệu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncWorkoutDataToCache() async {
    isSyncing.value = true;
    try {
      await DataService.instance.reloadWorkoutData();
      Get.snackbar(
        '✅ Đồng bộ thành công',
        'Dữ liệu bài tập đã được cập nhật cho mobile app',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi đồng bộ',
        'Không thể đồng bộ dữ liệu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> syncAllDataToCache() async {
    isSyncing.value = true;
    try {
      await DataService.instance.reloadAllData();
      Get.snackbar(
        '✅ Đồng bộ thành công',
        'Tất cả dữ liệu đã được cập nhật cho mobile app',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi đồng bộ',
        'Không thể đồng bộ dữ liệu: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
      );
    } finally {
      isSyncing.value = false;
    }
  }

  // Import Ingredients
  Future<void> importIngredients() async {
    try {
      isLoadingIngredients.value = true;
      await _ingredientProvider.addFakeData();
      // Sync to cache after import
      await syncMealDataToCache();
      Get.snackbar(
        'Thành công',
        'Đã import nguyên liệu vào database',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể import nguyên liệu: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingIngredients.value = false;
    }
  }

  // Import Meals - NOTE: addFakeDate is commented out in MealProvider
  // Use seedMeals() from fake_data.dart instead
  Future<void> importMeals() async {
    try {
      isLoadingMeals.value = true;
      // Note: MealProvider.addFakeDate() is deprecated/commented out
      // Use the seed functions from fake_data.dart instead
      Get.snackbar(
        'Thông báo',
        'Vui lòng sử dụng nút Seed Data để import món ăn',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể import món ăn: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMeals.value = false;
    }
  }

  // Import Workout Equipment
  Future<void> importEquipment() async {
    try {
      isLoadingEquipment.value = true;
      await _equipmentProvider.addFakeData();
      // Sync to cache after import
      await syncWorkoutDataToCache();
      Get.snackbar(
        'Thành công',
        'Đã import thiết bị tập luyện vào database',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể import thiết bị: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingEquipment.value = false;
    }
  }

  // Import Workout Categories
  Future<void> importCategories() async {
    try {
      isLoadingCategories.value = true;
      _categoryProvider.addFakeData(); // Returns void, not Future
      // Sync to cache after import
      await syncWorkoutDataToCache();
      Get.snackbar(
        'Thành công',
        'Đã import danh mục bài tập vào database',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể import danh mục: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // Import All Data
  Future<void> importAllData() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn import TẤT CẢ dữ liệu mẫu?\nQuá trình này có thể mất vài phút.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await importIngredients();
              await Future.delayed(const Duration(seconds: 1));
              await importMeals();
              await Future.delayed(const Duration(seconds: 1));
              await importEquipment();
              await Future.delayed(const Duration(seconds: 1));
              await importCategories();
              
              // Sync all data to cache
              await syncAllDataToCache();
              
              Get.snackbar(
                '✅ Hoàn thành',
                'Đã import tất cả dữ liệu mẫu thành công!',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
            },
            child: const Text('Import tất cả'),
          ),
        ],
      ),
    );
  }
}

