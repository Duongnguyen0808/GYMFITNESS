import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_meal.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

/// API Provider for PlanMeal
class PlanMealProvider implements Firestoration<String, PlanMeal> {
  final _apiService = ApiService.instance;

  @override
  String get collectionPath => AppValue.planMealsPath;

  @override
  Future<PlanMeal> add(PlanMeal obj) async {
    // PlanMeal is created as part of PlanMealCollection
    // This method is kept for compatibility but meals are managed via collection
    obj.id = DateTime.now().millisecondsSinceEpoch.toString();
    return obj;
  }

  @override
  Future<String> delete(String id) async {
    // PlanMeal deletion is handled via collection update
    return id;
  }

  @override
  Future<PlanMeal> fetch(String id) async {
    throw Exception('PlanMeal fetch by ID is not supported. Use fetchByListID instead.');
  }

  @override
  Future<List<PlanMeal>> fetchAll() async {
    try {
      return await _apiService.getPlanMeals();
    } catch (e) {
      // print('❌ Error fetching plan meals: $e');
      return [];
    }
  }

  Future<List<PlanMeal>> fetchByListID(String listID) async {
    try {
      return await _apiService.getPlanMeals(listID: listID);
    } catch (e) {
      // print('❌ Error fetching plan meals by listID: $e');
      return [];
    }
  }

  @override
  Future<PlanMeal> update(String id, PlanMeal obj) async {
    // PlanMeal update is handled via collection update
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // Not implemented - too dangerous
    throw Exception('deleteAll is not supported');
  }
}


