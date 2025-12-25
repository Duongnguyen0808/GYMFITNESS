import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_exercise_collection.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
// import 'package:vipt/app/data/services/api_service.dart'; // TODO: Uncomment when API is implemented

/// API Provider for PlanExerciseCollection
/// TODO: Implement full API endpoints in backend
class PlanExerciseCollectionProvider implements Firestoration<String, PlanExerciseCollection> {
  // final _apiService = ApiService.instance; // TODO: Use when API is implemented

  @override
  String get collectionPath => AppValue.planExerciseCollectionsPath;

  Stream<List<PlanExerciseCollection>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  Stream<List<PlanExerciseCollection>> streamByPlanID(int planID) {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchByPlanID(planID);
    }).asyncMap((future) => future);
  }

  @override
  Future<PlanExerciseCollection> add(PlanExerciseCollection obj) async {
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
  Future<PlanExerciseCollection> fetch(String id) async {
    // TODO: Implement API endpoint
    throw Exception('PlanExerciseCollection API not implemented yet');
  }

  @override
  Future<List<PlanExerciseCollection>> fetchAll() async {
    // TODO: Implement API endpoint
    return [];
  }

  Future<List<PlanExerciseCollection>> fetchByPlanID(int planID) async {
    // TODO: Implement API endpoint
    return [];
  }

  @override
  Future<PlanExerciseCollection> update(String id, PlanExerciseCollection obj) async {
    // TODO: Implement API endpoint
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // TODO: Implement API endpoint
  }
}

