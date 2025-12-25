import 'package:vipt/app/data/services/api_client.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/models/meal_collection.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  final _client = ApiClient.instance;

  // ============ AUTH ============
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String? gender,
    DateTime? dateOfBirth,
    num? currentWeight,
    num? currentHeight,
    num? goalWeight,
    String? activeFrequency,
    String? weightUnit,
    String? heightUnit,
    Map<String, dynamic>? otherFields,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'password': password,
    };

    // Chỉ thêm các field nếu có giá trị
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (gender != null) body['gender'] = gender;
    if (dateOfBirth != null)
      body['dateOfBirth'] = dateOfBirth.toIso8601String();
    if (currentWeight != null && currentWeight > 0)
      body['currentWeight'] = currentWeight;
    if (currentHeight != null && currentHeight > 0)
      body['currentHeight'] = currentHeight;
    if (goalWeight != null && goalWeight > 0) body['goalWeight'] = goalWeight;
    if (activeFrequency != null) body['activeFrequency'] = activeFrequency;
    if (weightUnit != null) body['weightUnit'] = weightUnit;
    if (heightUnit != null) body['heightUnit'] = heightUnit;
    if (otherFields != null) body.addAll(otherFields);

    return await _client.post('/auth/register', body, includeAuth: false);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await _client.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
        includeAuth: false);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _client.get('/auth/me');
  }

  Future<void> logout() async {
    await _client.clearToken();
  }

  // ============ USERS ============
  Future<Map<String, dynamic>> getUser(String id) async {
    return await _client.get('/users/$id');
  }

  Future<Map<String, dynamic>> updateUser(
      String id, Map<String, dynamic> data) async {
    return await _client.put('/users/$id', data);
  }

  // ============ MEALS ============
  Future<List<Meal>> getMeals({String? categoryId, String? search}) async {
    final queryParams = <String, String>{};
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (search != null) queryParams['search'] = search;

    final response = await _client.get('/meals', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data
        .map((json) => Meal.fromMap(json['_id'] ?? json['id'], json))
        .toList();
  }

  Future<Meal> getMeal(String id) async {
    final response = await _client.get('/meals/$id');
    final data = response['data'];
    return Meal.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<Meal> createMeal(Meal meal) async {
    final response = await _client.post('/meals', meal.toMap());
    final data = response['data'];
    return Meal.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<Meal> updateMeal(String id, Meal meal) async {
    final response = await _client.put('/meals/$id', meal.toMap());
    final data = response['data'];
    return Meal.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<void> deleteMeal(String id) async {
    await _client.delete('/meals/$id');
  }

  // ============ WORKOUTS ============
  Future<List<Workout>> getWorkouts(
      {String? categoryId, String? search}) async {
    final queryParams = <String, String>{};
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (search != null) queryParams['search'] = search;

    final response = await _client.get('/workouts', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data
        .map((json) => Workout.fromMap(json['_id'] ?? json['id'], json))
        .toList();
  }

  Future<Workout> getWorkout(String id) async {
    final response = await _client.get('/workouts/$id');
    final data = response['data'];
    return Workout.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<Workout> createWorkout(Workout workout) async {
    final response = await _client.post('/workouts', workout.toMap());
    final data = response['data'];
    return Workout.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<Workout> updateWorkout(String id, Workout workout) async {
    final response = await _client.put('/workouts/$id', workout.toMap());
    final data = response['data'];
    return Workout.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<void> deleteWorkout(String id) async {
    await _client.delete('/workouts/$id');
  }

  // ============ CATEGORIES ============
  Future<List<Category>> getCategories({String? type, String? parentId}) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;
    if (parentId != null) queryParams['parentId'] = parentId;

    final response = await _client.get('/categories', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data
        .map((json) => Category.fromMap(json['_id'] ?? json['id'], json))
        .toList();
  }

  Future<Category> getCategory(String id) async {
    final response = await _client.get('/categories/$id');
    final data = response['data'];
    return Category.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<Category> createCategory(Category category) async {
    final response = await _client.post('/categories', category.toMap());
    final data = response['data'];
    return Category.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<Category> updateCategory(String id, Category category) async {
    final response = await _client.put('/categories/$id', category.toMap());
    final data = response['data'];
    return Category.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/categories/$id');
  }

  // ============ WORKOUT COLLECTIONS ============
  Future<List<WorkoutCollection>> getWorkoutCollections(
      {String? userId, bool? isDefault}) async {
    final queryParams = <String, String>{};
    if (userId != null) queryParams['userId'] = userId;
    if (isDefault != null) queryParams['isDefault'] = isDefault.toString();

    final response =
        await _client.get('/collections/workouts', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data
        .map((json) =>
            WorkoutCollection.fromMap(json['_id'] ?? json['id'], json))
        .toList();
  }

  Future<WorkoutCollection> getWorkoutCollection(String id) async {
    final response = await _client.get('/collections/workouts/$id');
    final data = response['data'];
    return WorkoutCollection.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<WorkoutCollection> createWorkoutCollection(
      WorkoutCollection collection) async {
    final response =
        await _client.post('/collections/workouts', collection.toMap());
    final data = response['data'];
    return WorkoutCollection.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<WorkoutCollection> updateWorkoutCollection(
      String id, WorkoutCollection collection) async {
    final response =
        await _client.put('/collections/workouts/$id', collection.toMap());
    final data = response['data'];
    return WorkoutCollection.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<void> deleteWorkoutCollection(String id) async {
    await _client.delete('/collections/workouts/$id');
  }

  // ============ MEAL COLLECTIONS ============
  Future<List<MealCollection>> getMealCollections() async {
    final response = await _client.get('/collections/meals');
    final List<dynamic> data = response['data'] ?? [];
    return data
        .map((json) => MealCollection.fromMap(json['_id'] ?? json['id'], json))
        .toList();
  }

  Future<MealCollection> getMealCollection(String id) async {
    final response = await _client.get('/collections/meals/$id');
    final data = response['data'];
    return MealCollection.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<MealCollection> createMealCollection(MealCollection collection) async {
    final response =
        await _client.post('/collections/meals', collection.toMap());
    final data = response['data'];
    return MealCollection.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<MealCollection> updateMealCollection(
      String id, MealCollection collection) async {
    final response =
        await _client.put('/collections/meals/$id', collection.toMap());
    final data = response['data'];
    return MealCollection.fromMap(data['_id'] ?? data['id'], data);
  }

  Future<void> deleteMealCollection(String id) async {
    await _client.delete('/collections/meals/$id');
  }

  // ============ EQUIPMENT ============
  Future<List<Map<String, dynamic>>> getEquipment({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;

    final response = await _client.get('/equipment', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getSingleEquipment(String id) async {
    final response = await _client.get('/equipment/$id');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createEquipment(
      Map<String, dynamic> equipment) async {
    final response = await _client.post('/equipment', equipment);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateEquipment(
      String id, Map<String, dynamic> equipment) async {
    final response = await _client.put('/equipment/$id', equipment);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteEquipment(String id) async {
    await _client.delete('/equipment/$id');
  }

  // ============ INGREDIENTS ============
  Future<List<Map<String, dynamic>>> getIngredients({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;

    final response =
        await _client.get('/ingredients', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getIngredient(String id) async {
    final response = await _client.get('/ingredients/$id');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createIngredient(
      Map<String, dynamic> ingredient) async {
    final response = await _client.post('/ingredients', ingredient);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateIngredient(
      String id, Map<String, dynamic> ingredient) async {
    final response = await _client.put('/ingredients/$id', ingredient);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteIngredient(String id) async {
    await _client.delete('/ingredients/$id');
  }

  // ============ LIBRARY SECTIONS ============
  Future<List<Map<String, dynamic>>> getLibrarySections(
      {bool? activeOnly}) async {
    final queryParams = <String, String>{};
    if (activeOnly == true) queryParams['activeOnly'] = 'true';

    final response =
        await _client.get('/library-sections', queryParams: queryParams);
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => json as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> getLibrarySection(String id) async {
    final response = await _client.get('/library-sections/$id');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createLibrarySection(
      Map<String, dynamic> section) async {
    final response = await _client.post('/library-sections', section);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateLibrarySection(
      String id, Map<String, dynamic> section) async {
    final response = await _client.put('/library-sections/$id', section);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteLibrarySection(String id) async {
    await _client.delete('/library-sections/$id');
  }
}
