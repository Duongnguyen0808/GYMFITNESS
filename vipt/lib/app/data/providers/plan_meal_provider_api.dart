import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_meal.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
// import 'package:vipt/app/data/services/api_service.dart'; // TODO: Uncomment when API is implemented

/// API Provider for PlanMeal
/// TODO: Implement full API endpoints in backend
class PlanMealProvider implements Firestoration<String, PlanMeal> {
  // final _apiService = ApiService.instance; // TODO: Use when API is implemented

  @override
  String get collectionPath => AppValue.planMealsPath;

  @override
  Future<PlanMeal> add(PlanMeal obj) async {
    // TODO: Implement API endpoint
    obj.id = DateTime.now().millisecondsSinceEpoch.toString();
    return obj;
  }

  @override
  Future<String> delete(String id) async {
    // TODO: Implement API endpoint
    return id;
  }

  @override
  Future<PlanMeal> fetch(String id) async {
    // TODO: Implement API endpoint
    throw Exception('PlanMeal API not implemented yet');
  }

  @override
  Future<List<PlanMeal>> fetchAll() async {
    // TODO: Implement API endpoint
    return [];
  }

  Future<List<PlanMeal>> fetchByListID(String listID) async {
    // TODO: Implement API endpoint
    return [];
  }

  @override
  Future<PlanMeal> update(String id, PlanMeal obj) async {
    // TODO: Implement API endpoint
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // TODO: Implement API endpoint
  }
}

