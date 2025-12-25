import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_exercise.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
// import 'package:vipt/app/data/services/api_service.dart'; // TODO: Uncomment when API is implemented

/// API Provider for PlanExercise
/// TODO: Implement full API endpoints in backend
class PlanExerciseProvider implements Firestoration<String, PlanExercise> {
  // final _apiService = ApiService.instance; // TODO: Use when API is implemented

  @override
  String get collectionPath => AppValue.planExercisesPath;

  @override
  Future<PlanExercise> add(PlanExercise obj) async {
    // TODO: Implement API endpoint
    // For now, return object with generated ID
    obj.id = DateTime.now().millisecondsSinceEpoch.toString();
    return obj;
  }

  @override
  Future<String> delete(String id) async {
    // TODO: Implement API endpoint
    return id;
  }

  @override
  Future<PlanExercise> fetch(String id) async {
    // TODO: Implement API endpoint
    throw Exception('PlanExercise API not implemented yet');
  }

  @override
  Future<List<PlanExercise>> fetchAll() async {
    // TODO: Implement API endpoint
    return [];
  }

  Future<List<PlanExercise>> fetchByListID(String listID) async {
    // TODO: Implement API endpoint
    return [];
  }

  @override
  Future<PlanExercise> update(String id, PlanExercise obj) async {
    // TODO: Implement API endpoint
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // TODO: Implement API endpoint
  }
}

