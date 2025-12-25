import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_exercise_collection_setting.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
// import 'package:vipt/app/data/services/api_service.dart'; // TODO: Uncomment when API is implemented

/// API Provider for PlanExerciseCollectionSetting
/// TODO: Implement full API endpoints in backend
class PlanExerciseCollectionSettingProvider implements Firestoration<String, PlanExerciseCollectionSetting> {
  // final _apiService = ApiService.instance; // TODO: Use when API is implemented

  @override
  String get collectionPath => AppValue.planExerciseCollectionSettingsPath;

  @override
  Future<PlanExerciseCollectionSetting> add(PlanExerciseCollectionSetting obj) async {
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
  Future<PlanExerciseCollectionSetting> fetch(String id) async {
    // TODO: Implement API endpoint
    throw Exception('PlanExerciseCollectionSetting API not implemented yet');
  }

  @override
  Future<List<PlanExerciseCollectionSetting>> fetchAll() async {
    // TODO: Implement API endpoint
    return [];
  }

  @override
  Future<PlanExerciseCollectionSetting> update(String id, PlanExerciseCollectionSetting obj) async {
    // TODO: Implement API endpoint
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // TODO: Implement API endpoint
  }
}

