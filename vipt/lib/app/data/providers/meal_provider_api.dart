import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

class MealProvider implements Firestoration<String, Meal> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time (sẽ dùng WebSocket sau)
  Stream<List<Meal>> streamAll() {
    // TODO: Implement WebSocket stream when backend supports it
    // For now, return a stream that fetches periodically
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<Meal> add(Meal obj) async {
    final meal = await _apiService.createMeal(obj);
    obj.id = meal.id;
    return obj;
  }

  @override
  String get collectionPath => AppValue.mealsPath;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteMeal(id);
    return id;
  }

  @override
  Future<Meal> fetch(String id) async {
    try {
      return await _apiService.getMeal(id);
    } catch (e) {
      throw Exception('Meal with id $id does not exist: $e');
    }
  }

  @override
  Future<List<Meal>> fetchAll() async {
    try {
      return await _apiService.getMeals();
    } catch (e) {
      print('❌ Error fetching meals: $e');
      return [];
    }
  }

  Future<String> fetchByName(String name) async {
    try {
      final meals = await _apiService.getMeals(search: name);
      if (meals.isNotEmpty && meals.first.id != null) {
        return meals.first.id!;
      }
      return "";
    } catch (e) {
      return "";
    }
  }

  @override
  Future<Meal> update(String id, Meal obj) async {
    final meal = await _apiService.updateMeal(id, obj);
    obj.id = meal.id;
    return obj;
  }
}

