import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_exercise.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

/// API Provider for PlanExercise
class PlanExerciseProvider implements Firestoration<String, PlanExercise> {
  final _apiService = ApiService.instance;

  @override
  String get collectionPath => AppValue.planExercisesPath;

  @override
  Future<PlanExercise> add(PlanExercise obj) async {
    // PlanExercise is created as part of PlanExerciseCollection
    // This method is kept for compatibility but exercises are managed via collection
    obj.id = DateTime.now().millisecondsSinceEpoch.toString();
    return obj;
  }

  @override
  Future<String> delete(String id) async {
    // PlanExercise deletion is handled via collection update
    return id;
  }

  @override
  Future<PlanExercise> fetch(String id) async {
    throw Exception('PlanExercise fetch by ID is not supported. Use fetchByListID instead.');
  }

  @override
  Future<List<PlanExercise>> fetchAll() async {
    try {
      return await _apiService.getPlanExercises();
    } catch (e) {
      // print('❌ Error fetching plan exercises: $e');
      return [];
    }
  }

  Future<List<PlanExercise>> fetchByListID(String listID) async {
    try {
      return await _apiService.getPlanExercises(listID: listID);
    } catch (e) {
      // print('❌ Error fetching plan exercises by listID: $e');
      return [];
    }
  }

  @override
  Future<PlanExercise> update(String id, PlanExercise obj) async {
    // PlanExercise update is handled via collection update
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // Not implemented - too dangerous
    throw Exception('deleteAll is not supported');
  }
}


