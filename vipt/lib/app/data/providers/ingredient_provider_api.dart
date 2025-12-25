import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/ingredient.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/fake_data.dart' as fake_data;

class IngredientProvider implements Firestoration<String, Ingredient> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time
  Stream<List<Ingredient>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<Ingredient> add(Ingredient obj) async {
    final response = await _apiService.createIngredient(obj.toMap());
    return Ingredient.fromMap(response['_id'] ?? response['id'], response);
  }

  @override
  String get collectionPath => AppValue.mealIngredientsPath;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteIngredient(id);
    return id;
  }

  @override
  Future<Ingredient> fetch(String id) async {
    try {
      final data = await _apiService.getIngredient(id);
      return Ingredient.fromMap(data['_id'] ?? data['id'], data);
    } catch (e) {
      throw Exception('Ingredient with id $id does not exist: $e');
    }
  }

  @override
  Future<List<Ingredient>> fetchAll() async {
    try {
      final dataList = await _apiService.getIngredients();
      return dataList.map((json) => Ingredient.fromMap(json['_id'] ?? json['id'], json)).toList();
    } catch (e) {
      print('❌ Error fetching ingredients: $e');
      return [];
    }
  }

  @override
  Future<Ingredient> update(String id, Ingredient obj) async {
    final response = await _apiService.updateIngredient(id, obj.toMap());
    return Ingredient.fromMap(response['_id'] ?? response['id'], response);
  }

  Future<void> addFakeData() async {
    for (var ingr in fake_data.ingredientFakeData) {
      // Create new ingredient without id for adding
      final newIngr = Ingredient(
        id: '',
        name: ingr.name,
        kcal: ingr.kcal,
        fat: ingr.fat,
        carbs: ingr.carbs,
        protein: ingr.protein,
        imageUrl: ingr.imageUrl,
      );
      await add(newIngr);
    }
  }
}

