import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_exercise_collection.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

/// API Provider for PlanExerciseCollection
class PlanExerciseCollectionProvider implements Firestoration<String, PlanExerciseCollection> {
  final _apiService = ApiService.instance;

  @override
  String get collectionPath => AppValue.planExerciseCollectionsPath;

  Stream<List<PlanExerciseCollection>> streamAll() {
    // Polling every 30 seconds for updates
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  Stream<List<PlanExerciseCollection>> streamByPlanID(int planID) {
    // Polling every 30 seconds for updates
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchByPlanID(planID);
    }).asyncMap((future) => future);
  }

  @override
  Future<PlanExerciseCollection> add(PlanExerciseCollection obj) async {
    // This method is kept for compatibility
    // Actual creation with exercises and settings is handled in admin form
    try {
      final data = {
        'date': obj.date.toIso8601String(),
        'planID': obj.planID,
        'collectionSettingID': obj.collectionSettingID,
      };
      final collection = await _apiService.createPlanExerciseCollection(data);
      obj.id = collection.id;
      return obj;
    } catch (e) {
      throw Exception('Error creating plan exercise collection: $e');
    }
  }
  
  /// Create collection with exercises and settings (used by admin form)
  Future<PlanExerciseCollection> createWithExercises({
    required DateTime date,
    required int planID,
    required int round,
    required int exerciseTime,
    required int numOfWorkoutPerRound,
    required List<String> exerciseIDs,
  }) async {
    try {
      final data = {
        'date': date.toIso8601String(),
        'planID': planID,
        'round': round,
        'exerciseTime': exerciseTime,
        'numOfWorkoutPerRound': numOfWorkoutPerRound,
        'exerciseIDs': exerciseIDs,
      };
      final collection = await _apiService.createPlanExerciseCollection(data);
      return collection;
    } catch (e) {
      throw Exception('Error creating plan exercise collection with exercises: $e');
    }
  }

  @override
  Future<String> delete(String id) async {
    try {
      await _apiService.deletePlanExerciseCollection(id);
      return id;
    } catch (e) {
      throw Exception('Error deleting plan exercise collection: $e');
    }
  }

  @override
  Future<PlanExerciseCollection> fetch(String id) async {
    try {
      return await _apiService.getPlanExerciseCollection(id);
    } catch (e) {
      throw Exception('Plan exercise collection with id $id does not exist: $e');
    }
  }

  @override
  Future<List<PlanExerciseCollection>> fetchAll() async {
    try {
      return await _apiService.getPlanExerciseCollections();
    } catch (e) {
      print('❌ Error fetching plan exercise collections: $e');
      return [];
    }
  }

  Future<List<PlanExerciseCollection>> fetchByPlanID(int planID) async {
    try {
      return await _apiService.getPlanExerciseCollections(planID: planID);
    } catch (e) {
      print('❌ Error fetching plan exercise collections by planID: $e');
      return [];
    }
  }

  @override
  Future<PlanExerciseCollection> update(String id, PlanExerciseCollection obj) async {
    // This method is kept for compatibility
    // Actual update with exercises and settings is handled in admin form
    try {
      final data = {
        'date': obj.date.toIso8601String(),
        'planID': obj.planID,
        'collectionSettingID': obj.collectionSettingID,
      };
      final collection = await _apiService.updatePlanExerciseCollection(id, data);
      obj.id = collection.id;
      return obj;
    } catch (e) {
      throw Exception('Error updating plan exercise collection: $e');
    }
  }
  
  /// Update collection with exercises and settings (used by admin form)
  Future<PlanExerciseCollection> updateWithExercises({
    required String id,
    required DateTime date,
    required int planID,
    required String? collectionSettingID,
    required int round,
    required int exerciseTime,
    required int numOfWorkoutPerRound,
    required List<String> exerciseIDs,
  }) async {
    try {
      final data = {
        'date': date.toIso8601String(),
        'planID': planID,
        'round': round,
        'exerciseTime': exerciseTime,
        'numOfWorkoutPerRound': numOfWorkoutPerRound,
        'exerciseIDs': exerciseIDs,
      };
      if (collectionSettingID != null && collectionSettingID.isNotEmpty) {
        data['collectionSettingID'] = collectionSettingID;
      }
      final collection = await _apiService.updatePlanExerciseCollection(id, data);
      return collection;
    } catch (e) {
      throw Exception('Error updating plan exercise collection with exercises: $e');
    }
  }

  Future<void> deleteAll() async {
    // Not implemented - too dangerous
    throw Exception('deleteAll is not supported');
  }
}

