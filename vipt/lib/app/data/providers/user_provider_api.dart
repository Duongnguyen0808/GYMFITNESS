import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/vipt_user.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

class UserProvider implements Firestoration<String, ViPTUser> {
  final _apiService = ApiService.instance;

  @override
  Future<ViPTUser> add(ViPTUser obj) async {
    try {
      // User được tạo trong quá trình registration
      // Này chỉ để update profile
      final userMap = obj.toMap();
      final userId = obj.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }
      userMap.remove('id');
      
      final result = await _apiService.updateUser(userId, userMap);
      if (result['success'] == true) {
        return ViPTUser.fromMap(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Failed to create user');
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<String> delete(String id) {
    throw UnimplementedError('User deletion not supported');
  }

  @override
  Future<ViPTUser> fetch(String id) async {
    try {
      final result = await _apiService.getUser(id);
      if (result['success'] == true && result['data'] != null) {
        return ViPTUser.fromMap(result['data']);
      } else {
        throw Exception('User not found: Document with id "$id" does not exist.');
      }
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  @override
  Future<ViPTUser> update(String id, ViPTUser obj) async {
    try {
      final userMap = obj.toMap();
      userMap.remove('id');
      
      final result = await _apiService.updateUser(id, userMap);
      if (result['success'] == true) {
        return ViPTUser.fromMap(result['data']);
      } else {
        throw Exception(result['message'] ?? 'Failed to update user');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  String get collectionPath => AppValue.usersPath;

  Future<bool> checkIfUserExist(String uid) async {
    try {
      final result = await _apiService.getUser(uid);
      return result['success'] == true && result['data'] != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ViPTUser>> fetchAll() {
    throw UnimplementedError('Fetching all users not supported');
  }
}


