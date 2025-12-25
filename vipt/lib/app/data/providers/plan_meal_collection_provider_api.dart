import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/plan_meal_collection.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';

/// API Provider for PlanMealCollection
class PlanMealCollectionProvider
    implements Firestoration<String, PlanMealCollection> {
  final _apiService = ApiService.instance;

  @override
  String get collectionPath => AppValue.planMealCollectionsPath;

  Stream<List<PlanMealCollection>> streamAll() {
    // Polling every 30 seconds for updates
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  Stream<List<PlanMealCollection>> streamByPlanID(int planID) {
    // Polling every 30 seconds for updates
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchByPlanID(planID);
    }).asyncMap((future) => future);
  }

  @override
  Future<PlanMealCollection> add(PlanMealCollection obj) async {
    // This method is kept for compatibility
    // Actual creation with meals is handled in admin form
    try {
      // Validate mealRatio trước khi gửi
      double mealRatio = obj.mealRatio;
      if (!mealRatio.isFinite || mealRatio.isNaN) {
        print(
            '⚠️ mealRatio không hợp lệ ($mealRatio), sử dụng giá trị mặc định: 1.0');
        mealRatio = 1.0;
      }
      // Giới hạn mealRatio trong khoảng hợp lý
      if (mealRatio < 0.1) mealRatio = 0.1;
      if (mealRatio > 10.0) mealRatio = 10.0;

      final data = {
        'date': obj.date.toIso8601String(),
        'planID': obj.planID,
        'mealRatio': mealRatio,
      };
      final collection = await _apiService.createPlanMealCollection(data);
      obj.id = collection.id;
      return obj;
    } catch (e) {
      throw Exception('Error creating plan meal collection: $e');
    }
  }

  /// Create collection with meals (used by admin form)
  Future<PlanMealCollection> createWithMeals({
    required DateTime date,
    required int planID,
    required double mealRatio,
    required List<String> mealIDs,
  }) async {
    try {
      // Validate mealRatio trước khi gửi
      double validMealRatio = mealRatio;
      if (!validMealRatio.isFinite || validMealRatio.isNaN) {
        print(
            '⚠️ mealRatio không hợp lệ ($mealRatio), sử dụng giá trị mặc định: 1.0');
        validMealRatio = 1.0;
      }
      // Giới hạn mealRatio trong khoảng hợp lý
      if (validMealRatio < 0.1) validMealRatio = 0.1;
      if (validMealRatio > 10.0) validMealRatio = 10.0;

      final data = {
        'date': date.toIso8601String(),
        'planID': planID,
        'mealRatio': validMealRatio,
        'mealIDs': mealIDs,
      };
      final collection = await _apiService.createPlanMealCollection(data);
      return collection;
    } catch (e) {
      throw Exception('Error creating plan meal collection with meals: $e');
    }
  }

  @override
  Future<String> delete(String id) async {
    try {
      await _apiService.deletePlanMealCollection(id);
      return id;
    } catch (e) {
      throw Exception('Error deleting plan meal collection: $e');
    }
  }

  @override
  Future<PlanMealCollection> fetch(String id) async {
    try {
      return await _apiService.getPlanMealCollection(id);
    } catch (e) {
      throw Exception('Plan meal collection with id $id does not exist: $e');
    }
  }

  @override
  Future<List<PlanMealCollection>> fetchAll() async {
    try {
      return await _apiService.getPlanMealCollections();
    } catch (e) {
      print('❌ Error fetching plan meal collections: $e');
      return [];
    }
  }

  Future<List<PlanMealCollection>> fetchByPlanID(int planID) async {
    try {
      return await _apiService.getPlanMealCollections(planID: planID);
    } catch (e) {
      print('❌ Error fetching plan meal collections by planID: $e');
      return [];
    }
  }

  @override
  Future<PlanMealCollection> update(String id, PlanMealCollection obj) async {
    // This method is kept for compatibility
    // Actual update with meals is handled in admin form
    try {
      // Validate mealRatio trước khi gửi
      double mealRatio = obj.mealRatio;
      if (!mealRatio.isFinite || mealRatio.isNaN) {
        print(
            '⚠️ mealRatio không hợp lệ ($mealRatio), sử dụng giá trị mặc định: 1.0');
        mealRatio = 1.0;
      }
      // Giới hạn mealRatio trong khoảng hợp lý
      if (mealRatio < 0.1) mealRatio = 0.1;
      if (mealRatio > 10.0) mealRatio = 10.0;

      final data = {
        'date': obj.date.toIso8601String(),
        'planID': obj.planID,
        'mealRatio': mealRatio,
      };
      final collection = await _apiService.updatePlanMealCollection(id, data);
      obj.id = collection.id;
      return obj;
    } catch (e) {
      throw Exception('Error updating plan meal collection: $e');
    }
  }

  /// Update collection with meals (used by admin form)
  Future<PlanMealCollection> updateWithMeals({
    required String id,
    required DateTime date,
    required int planID,
    required double mealRatio,
    required List<String> mealIDs,
  }) async {
    try {
      // Validate mealRatio trước khi gửi
      double validMealRatio = mealRatio;
      if (!validMealRatio.isFinite || validMealRatio.isNaN) {
        print(
            '⚠️ mealRatio không hợp lệ ($mealRatio), sử dụng giá trị mặc định: 1.0');
        validMealRatio = 1.0;
      }
      // Giới hạn mealRatio trong khoảng hợp lý
      if (validMealRatio < 0.1) validMealRatio = 0.1;
      if (validMealRatio > 10.0) validMealRatio = 10.0;

      final data = {
        'date': date.toIso8601String(),
        'planID': planID,
        'mealRatio': validMealRatio,
        'mealIDs': mealIDs,
      };
      final collection = await _apiService.updatePlanMealCollection(id, data);
      return collection;
    } catch (e) {
      throw Exception('Error updating plan meal collection with meals: $e');
    }
  }

  Future<void> deleteAll() async {
    // Not implemented - too dangerous
    throw Exception('deleteAll is not supported');
  }
}
