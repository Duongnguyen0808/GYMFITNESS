import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/auth_service.dart';

class WorkoutCollectionProvider implements Firestoration<String, WorkoutCollection> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time cho default collections
  Stream<List<WorkoutCollection>> streamAllDefaultCollection() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAllDefaultCollection();
    }).asyncMap((future) => future);
  }

  /// Stream để lắng nghe thay đổi real-time cho user collections
  Stream<List<WorkoutCollection>> streamAllUserCollection() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAllUserCollection();
    }).asyncMap((future) => future);
  }

  @override
  Future<WorkoutCollection> add(WorkoutCollection obj) async {
    final collection = await _apiService.createWorkoutCollection(obj);
    obj.id = collection.id;
    return obj;
  }

  @override
  String get collectionPath => AppValue.workoutCollectionsPath;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteWorkoutCollection(id);
    return id;
  }

  @override
  Future<WorkoutCollection> fetch(String id) async {
    try {
      return await _apiService.getWorkoutCollection(id);
    } catch (e) {
      throw Exception('WorkoutCollection with id $id does not exist: $e');
    }
  }

  @override
  Future<List<WorkoutCollection>> fetchAll() {
    return fetchAllDefaultCollection();
  }

  @override
  Future<WorkoutCollection> update(String id, WorkoutCollection obj) async {
    final collection = await _apiService.updateWorkoutCollection(id, obj);
    obj.id = collection.id;
    return obj;
  }

  Future<WorkoutCollection> addDefaultCollection(WorkoutCollection obj) async {
    final collection = await _apiService.createWorkoutCollection(obj);
    obj.id = collection.id;
    return obj;
  }

  Future<String> deleteDefaultCollection(String id) async {
    await _apiService.deleteWorkoutCollection(id);
    return id;
  }

  Future<WorkoutCollection> addWorkoutToCollection(
      String workoutID, WorkoutCollection wc) async {
    wc.generatorIDs.add(workoutID);
    await update(wc.id ?? "", wc);
    return wc;
  }

  Future<WorkoutCollection> deleteWorkoutFromCollection(
      String workoutID, WorkoutCollection wc) async {
    wc.generatorIDs.remove(workoutID);
    await update(wc.id ?? '', wc);
    return wc;
  }

  Future<List<WorkoutCollection>> fetchAllDefaultCollection() async {
    try {
      return await _apiService.getWorkoutCollections(isDefault: true);
    } catch (e) {
      print('❌ Error fetching default workout collections: $e');
      return [];
    }
  }

  Future<List<WorkoutCollection>> fetchAllUserCollection() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser == null) return [];
      
      final userId = currentUser['_id'] ?? currentUser['id'];
      return await _apiService.getWorkoutCollections(userId: userId);
    } catch (e) {
      print('❌ Error fetching user workout collections: $e');
      return [];
    }
  }

  Future<WorkoutCollection> updateDefaultCollection(String id, WorkoutCollection obj) async {
    final collection = await _apiService.updateWorkoutCollection(id, obj);
    obj.id = collection.id;
    return obj;
  }
}


