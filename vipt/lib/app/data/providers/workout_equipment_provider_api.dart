import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/workout_equipment.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/fake_data.dart' as fake_data;

class WorkoutEquipmentProvider implements Firestoration<String, WorkoutEquipment> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time
  Stream<List<WorkoutEquipment>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<WorkoutEquipment> add(WorkoutEquipment obj) async {
    final response = await _apiService.createEquipment(obj.toMap());
    obj.id = response['_id'] ?? response['id'];
    return obj;
  }

  @override
  String get collectionPath => AppValue.workoutEquipmentCollectionPath;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteEquipment(id);
    return id;
  }

  @override
  Future<WorkoutEquipment> fetch(String id) async {
    try {
      final data = await _apiService.getSingleEquipment(id);
      return WorkoutEquipment.fromMap(data['_id'] ?? data['id'], data);
    } catch (e) {
      throw Exception('Equipment with id $id does not exist: $e');
    }
  }

  @override
  Future<List<WorkoutEquipment>> fetchAll() async {
    try {
      final dataList = await _apiService.getEquipment();
      return dataList.map((json) => WorkoutEquipment.fromMap(json['_id'] ?? json['id'], json)).toList();
    } catch (e) {
      print('❌ Error fetching equipment: $e');
      return [];
    }
  }

  @override
  Future<WorkoutEquipment> update(String id, WorkoutEquipment obj) async {
    final response = await _apiService.updateEquipment(id, obj.toMap());
    obj.id = response['_id'] ?? response['id'];
    return obj;
  }

  Future<void> addFakeData() async {
    for (var item in fake_data.workoutEquipmentFakeData) {
      await add(item);
    }
  }
}

