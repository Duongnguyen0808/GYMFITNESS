import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:get/get.dart';
import 'package:vipt/app/data/models/ingredient.dart';
import 'package:vipt/app/data/providers/ingredient_provider_api.dart';

class IngredientController extends GetxController {
  final RxList<Ingredient> ingredients = <Ingredient>[].obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoading = true.obs;

  final IngredientProvider _ingredientProvider = IngredientProvider();

  @override
  void onInit() {
    super.onInit();
    loadIngredients();
  }

  Future<void> loadIngredients() async {
    isLoading.value = true;
    try {
      final ingredientsList = await _ingredientProvider.fetchAll();
      ingredients.assignAll(ingredientsList);
    } catch (e) {
      if (kDebugMode) {
        // Log lỗi chỉ trong debug mode
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshIngredients() async {
    isRefreshing.value = true;
    try {
      await loadIngredients();
    } finally {
      isRefreshing.value = false;
    }
  }
}
