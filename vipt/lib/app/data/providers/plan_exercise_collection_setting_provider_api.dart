import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_exercise_collection_setting.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

/// API Provider for PlanExerciseCollectionSetting
/// Note: Settings are usually created/updated as part of PlanExerciseCollection
/// This provider is kept for compatibility and fetching existing settings
class PlanExerciseCollectionSettingProvider implements Firestoration<String, PlanExerciseCollectionSetting> {
  final _apiService = ApiService.instance;

  @override
  String get collectionPath => AppValue.planExerciseCollectionSettingsPath;

  @override
  Future<PlanExerciseCollectionSetting> add(PlanExerciseCollectionSetting obj) async {
    // Settings are created automatically when creating PlanExerciseCollection
    // This method is kept for compatibility
    obj.id = DateTime.now().millisecondsSinceEpoch.toString();
    return obj;
  }

  @override
  Future<String> delete(String id) async {
    // Settings are deleted automatically when deleting PlanExerciseCollection
    return id;
  }

  @override
  Future<PlanExerciseCollectionSetting> fetch(String id) async {
    try {
      final data = await _apiService.getPlanExerciseCollectionSetting(id);
      return PlanExerciseCollectionSetting.fromMap(id, data);
    } catch (e) {
      throw Exception('Plan exercise collection setting with id $id does not exist: $e');
    }
  }

  @override
  Future<List<PlanExerciseCollectionSetting>> fetchAll() async {
    // Not implemented - settings are fetched via collections
    return [];
  }

  @override
  Future<PlanExerciseCollectionSetting> update(String id, PlanExerciseCollectionSetting obj) async {
    // Settings are updated automatically when updating PlanExerciseCollection
    // This method is kept for compatibility
    obj.id = id;
    return obj;
  }

  Future<void> deleteAll() async {
    // Not implemented - too dangerous
    throw Exception('deleteAll is not supported');
  }
}

