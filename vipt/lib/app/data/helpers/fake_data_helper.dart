import 'package:shared_preferences/shared_preferences.dart';
import '../fake_data.dart';
import '../models/meal.dart';
import '../providers/meal_category_provider_api.dart';
import '../providers/ingredient_provider_api.dart';
import '../providers/meal_provider_api.dart';
import '../providers/meal_collection_provider_api.dart';
import '../providers/workout_category_provider_api.dart';
import '../providers/workout_equipment_provider_api.dart';

/// Helper class để quản lý việc seed fake data
class FakeDataHelper {
  static const String _seedDataKey = 'is_data_seeded';
  static const String _seedVersionKey = 'seed_data_version';
  static const int _currentVersion = 1;

  /// Kiểm tra xem dữ liệu đã được seed chưa
  static Future<bool> isDataSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool(_seedDataKey) ?? false;
    final version = prefs.getInt(_seedVersionKey) ?? 0;

    // Nếu version khác thì cần seed lại
    return isSeeded && version == _currentVersion;
  }

  /// Đánh dấu dữ liệu đã được seed
  static Future<void> markAsSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seedDataKey, true);
    await prefs.setInt(_seedVersionKey, _currentVersion);
  }

  /// Reset flag để seed lại
  static Future<void> resetSeedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seedDataKey);
    await prefs.remove(_seedVersionKey);
  }

  /// Xóa tất cả dữ liệu đã seed
  static Future<void> deleteAllSeededData() async {
    try {
      final mealProvider = MealProvider();
      final ingredientProvider = IngredientProvider();
      final mealCategoryProvider = MealCategoryProvider();
      final mealCollectionProvider = MealCollectionProvider();
      final workoutCategoryProvider = WorkoutCategoryProvider();
      final workoutEquipmentProvider = WorkoutEquipmentProvider();

      final meals = await mealProvider.fetchAll();
      for (var meal in meals) {
        if (meal.id != null) await mealProvider.delete(meal.id!);
      }

      final ingredients = await ingredientProvider.fetchAll();
      for (var ingredient in ingredients) {
        if (ingredient.id != null)
          await ingredientProvider.delete(ingredient.id!);
      }

      final mealCategories = await mealCategoryProvider.fetchAll();
      for (var category in mealCategories) {
        if (category.id != null)
          await mealCategoryProvider.delete(category.id!);
      }

      final mealCollections = await mealCollectionProvider.fetchAll();
      for (var collection in mealCollections) {
        if (collection.id != null)
          await mealCollectionProvider.delete(collection.id!);
      }

      final workoutCategories = await workoutCategoryProvider.fetchAll();
      for (var category in workoutCategories) {
        if (category.id != null)
          await workoutCategoryProvider.delete(category.id!);
      }

      final workoutEquipments = await workoutEquipmentProvider.fetchAll();
      for (var equipment in workoutEquipments) {
        if (equipment.id != null)
          await workoutEquipmentProvider.delete(equipment.id!);
      }

      await resetSeedFlag();
    } catch (e) {
      rethrow;
    }
  }

  /// Seed tất cả dữ liệu (gọi hàm này từ UI)
  static Future<void> seedAllData({bool force = false}) async {
    if (!force) {
      final alreadySeeded = await isDataSeeded();
      if (alreadySeeded) {
        return;
      }
    }

    try {
      await seedAllFakeData();
      await markAsSeeded();
    } catch (e) {
      rethrow;
    }
  }

  /// Seed từng phần riêng biệt (nếu cần)
  static Future<void> seedMealData() async {
    try {
      await seedMealCategories();
      await seedIngredients();
      await seedMeals();
      await seedMealCollections();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> seedWorkoutData() async {
    try {
      await seedWorkouts();
    } catch (e) {
      rethrow;
    }
  }

  static const Map<String, List<String>> _mealToCategoryNames = {
    'Apple Sauce Oatmeal': ['Breakfast'],
    'Oatmeal With Apples & Raisins': ['Breakfast'],
    'Protein Kiwi Pizza': ['Breakfast'],
    'Oat Cookies': ['Breakfast'],
    'Apple Cookies': ['Breakfast'],
    'Tortilla Mushroom Pie': ['Breakfast'],
    'Quinoa With Banana': ['Breakfast'],
    'Mushroom Steak A': ['Lunch/Dinner'],
    'Mushroom Steak': ['Lunch/Dinner'],
    'Protein Cauliflower Bites': ['Lunch/Dinner'],
    'Mushroom Walnut Burger': ['Lunch/Dinner'],
    'Quinoa & Sweet Potato': ['Lunch/Dinner'],
    'Air-Fried Tofu': ['Lunch/Dinner'],
    'Broccoli & Cauliflower Curry With Rice': ['Lunch/Dinner'],
    'Sweet Potato Curry With Rice': ['Lunch/Dinner'],
    'Roasted Chickpeas': ['Snack'],
    'Raw Gingerbread Bites': ['Snack'],
    'Pumpkin Oat Bites': ['Snack'],
    'Buckwheat Bread': ['Snack'],
    'Onion Rings': ['Snack'],
    'Carrot Cake Bites': ['Snack'],
    'Apple Nachos': ['Snack'],
  };

  static Future<Map<String, dynamic>> fixAllMealCategoryIds() async {
    final mealProvider = MealProvider();
    final categoryProvider = MealCategoryProvider();
    
    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    List<String> errors = [];

    try {
      final categories = await categoryProvider.fetchAll();
      
      if (categories.isEmpty) {
        throw Exception('Không tìm thấy categories trong database!');
      }
      
      final Map<String, String> categoryNameToId = {};
      for (var cat in categories) {
        categoryNameToId[cat.name] = cat.id!;
      }
      
      final meals = await mealProvider.fetchAll();
      
      for (var meal in meals) {
        try {
          List<String>? targetCategoryNames;
          
          if (_mealToCategoryNames.containsKey(meal.name)) {
            targetCategoryNames = _mealToCategoryNames[meal.name];
          } else {
            targetCategoryNames = _guessCategoryForMeal(meal.name);
          }
          
          if (targetCategoryNames == null || targetCategoryNames.isEmpty) {
            skippedCount++;
            continue;
          }
          
          List<String> newCategoryIds = [];
          for (var catName in targetCategoryNames) {
            if (categoryNameToId.containsKey(catName)) {
              newCategoryIds.add(categoryNameToId[catName]!);
            }
          }
          
          if (newCategoryIds.isEmpty) {
            skippedCount++;
            continue;
          }
          
          final currentIds = meal.categoryIDs;
          final needsUpdate = !_listEquals(currentIds, newCategoryIds);
          
          if (!needsUpdate) {
            skippedCount++;
            continue;
          }
          
          final updatedMeal = Meal(
            id: meal.id!,
            name: meal.name,
            asset: meal.asset,
            categoryIDs: newCategoryIds,
            cookTime: meal.cookTime,
            steps: meal.steps,
            ingreIDToAmount: meal.ingreIDToAmount,
          );
          
          await mealProvider.update(meal.id!, updatedMeal);
          updatedCount++;
          
        } catch (e) {
          errors.add('${meal.name}: $e');
          errorCount++;
        }
      }
      
      return {
        'success': true,
        'updated': updatedCount,
        'skipped': skippedCount,
        'errors': errorCount,
        'errorMessages': errors,
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'updated': updatedCount,
        'skipped': skippedCount,
        'errors': errorCount,
      };
    }
  }
  
  static List<String>? _guessCategoryForMeal(String mealName) {
    final lowerName = mealName.toLowerCase();
    if (lowerName.contains('oatmeal') || 
        lowerName.contains('breakfast') ||
        lowerName.contains('pancake') ||
        lowerName.contains('cereal') ||
        lowerName.contains('toast') ||
        lowerName.contains('egg') ||
        lowerName.contains('smoothie') ||
        lowerName.contains('banana') && lowerName.contains('quinoa')) {
      return ['Breakfast'];
    }
    if (lowerName.contains('snack') ||
        lowerName.contains('bites') ||
        lowerName.contains('cookies') ||
        lowerName.contains('chips') ||
        lowerName.contains('nachos') ||
        lowerName.contains('bread') ||
        lowerName.contains('rings') ||
        lowerName.contains('chickpeas')) {
      return ['Snack'];
    }
    if (lowerName.contains('curry') ||
        lowerName.contains('rice') ||
        lowerName.contains('steak') ||
        lowerName.contains('burger') ||
        lowerName.contains('tofu') ||
        lowerName.contains('potato') ||
        lowerName.contains('cauliflower') && !lowerName.contains('bites')) {
      return ['Lunch/Dinner'];
    }
    
    return null;
  }
  
  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!b.contains(a[i])) return false;
    }
    return true;
  }
}
