import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/library_section.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

class LibrarySectionProvider implements Firestoration<String, LibrarySection> {
  final _apiService = ApiService.instance;

  /// Stream để lắng nghe thay đổi real-time
  Stream<List<LibrarySection>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<LibrarySection> add(LibrarySection obj) async {
    final response = await _apiService.createLibrarySection(obj.toMap());
    obj.id = response['_id'] ?? response['id'];
    return obj;
  }

  @override
  String get collectionPath => AppValue.librarySectionsPath;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteLibrarySection(id);
    return id;
  }

  @override
  Future<LibrarySection> fetch(String id) async {
    try {
      final data = await _apiService.getLibrarySection(id);
      return LibrarySection.fromMap(data['_id'] ?? data['id'], data);
    } catch (e) {
      throw Exception('LibrarySection with id $id does not exist: $e');
    }
  }

  @override
  Future<List<LibrarySection>> fetchAll() async {
    try {
      final dataList = await _apiService.getLibrarySections();
      return dataList.map((json) => LibrarySection.fromMap(json['_id'] ?? json['id'], json)).toList();
    } catch (e) {
      // print('❌ Error fetching library sections: $e');
      return [];
    }
  }

  /// Lấy danh sách sections đang active, sắp xếp theo order
  Future<List<LibrarySection>> fetchActiveSections() async {
    try {
      final dataList = await _apiService.getLibrarySections(activeOnly: true);
      return dataList.map((json) => LibrarySection.fromMap(json['_id'] ?? json['id'], json)).toList();
    } catch (e) {
      // print('❌ Error fetching active library sections: $e');
      return [];
    }
  }

  @override
  Future<LibrarySection> update(String id, LibrarySection obj) async {
    final response = await _apiService.updateLibrarySection(id, obj.toMap());
    obj.id = response['_id'] ?? response['id'];
    return obj;
  }
}



