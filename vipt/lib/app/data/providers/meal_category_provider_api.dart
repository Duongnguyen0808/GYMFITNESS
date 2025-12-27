import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

class MealCategoryProvider implements Firestoration<String, Category> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time
  Stream<List<Category>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<Category> add(Category obj) async {
    final category = await _apiService.createCategory(obj);
    obj.id = category.id;
    return obj;
  }

  @override
  String get collectionPath => AppValue.mealCategories;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteCategory(id);
    return id;
  }

  @override
  Future<Category> fetch(String id) async {
    try {
      return await _apiService.getCategory(id);
    } catch (e) {
      throw Exception('Category with id $id does not exist: $e');
    }
  }

  @override
  Future<List<Category>> fetchAll() async {
    try {
      return await _apiService.getCategories(type: 'meal');
    } catch (e) {
      // print('❌ Error fetching meal categories: $e');
      return [];
    }
  }

  @override
  Future<Category> update(String id, Category obj) async {
    final category = await _apiService.updateCategory(id, obj);
    obj.id = category.id;
    return obj;
  }
}


