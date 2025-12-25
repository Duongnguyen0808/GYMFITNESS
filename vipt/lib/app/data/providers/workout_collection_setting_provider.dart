import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/collection_setting.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/auth_service.dart';

class WorkoutCollectionSettingProvider
    implements Firestoration<String, CollectionSetting> {
  final _apiService = ApiService.instance;

  @override
  Future<CollectionSetting> add(CollectionSetting obj) {
    throw UnimplementedError();
  }

  @override
  String get collectionPath => AppValue.usersPath;

  @override
  Future<String> delete(String id) {
    throw UnimplementedError();
  }

  @override
  Future<CollectionSetting> fetch(String id) {
    throw UnimplementedError();
  }

  @override
  Future<CollectionSetting> update(String id, CollectionSetting obj) async {
    final currentUser = AuthService.instance.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    final userId = currentUser['_id'] ?? currentUser['id'] ?? id;
    final userData = await _apiService.getUser(userId);
    
    if (userData['success'] == true) {
      final updatedData = Map<String, dynamic>.from(userData['data']);
      updatedData['collectionSetting'] = obj.toMap();
      
      await _apiService.updateUser(userId, updatedData);
      return obj;
    } else {
      throw Exception('Failed to update collection setting');
    }
  }

  @override
  Future<List<CollectionSetting>> fetchAll() {
    throw UnimplementedError();
  }
}

