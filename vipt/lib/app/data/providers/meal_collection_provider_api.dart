import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/meal_collection.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

class MealCollectionProvider implements Firestoration<String, MealCollection> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time
  Stream<List<MealCollection>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<MealCollection> add(MealCollection obj) async {
    final collection = await _apiService.createMealCollection(obj);
    obj.id = collection.id;
    return obj;
  }

  @override
  String get collectionPath => AppValue.mealCollections;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteMealCollection(id);
    return id;
  }

  @override
  Future<MealCollection> fetch(String id) async {
    try {
      return await _apiService.getMealCollection(id);
    } catch (e) {
      throw Exception('MealCollection with id $id does not exist: $e');
    }
  }

  @override
  Future<List<MealCollection>> fetchAll() async {
    try {
      return await _apiService.getMealCollections();
    } catch (e) {
      print('❌ Error fetching meal collections: $e');
      return [];
    }
  }

  @override
  Future<MealCollection> update(String id, MealCollection obj) async {
    final collection = await _apiService.updateMealCollection(id, obj);
    obj.id = collection.id;
    return obj;
  }
}

