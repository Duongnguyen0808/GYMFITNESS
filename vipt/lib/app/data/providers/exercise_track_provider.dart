import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/exercise_tracker.dart';
import 'package:vipt/app/data/providers/database_provider.dart';
import 'package:vipt/app/data/providers/sqflite_helper.dart';
import 'package:vipt/app/data/services/data_service.dart';

class ExerciseTrackProvider implements SqfliteHelper<int, ExerciseTracker> {
  @override
  String tableName = AppValue.exerciseTrackTable;

  @override
  Future<ExerciseTracker> add(ExerciseTracker obj) async {
    // Tự động thêm userID nếu chưa có
    if (obj.userID == null && DataService.currentUser != null) {
      obj.userID = DataService.currentUser!.id;
    }
    final db = await DatabaseProvider.database;
    db!.insert(tableName, obj.toMap()).then((value) => obj.id = value);
    return obj;
  }

  @override
  Future<void> delete(int id) async {
    final db = await DatabaseProvider.database;
    await db!.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<ExerciseTracker?> fetch(int id) async {
    final db = await DatabaseProvider.database;
    final List<Map<String, dynamic>> maps =
        await db!.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ExerciseTracker.fromMap(maps[0]);
  }

  @override
  Future<List<ExerciseTracker>> fetchAll() async {
    final db = await DatabaseProvider.database;
    String? userID = DataService.currentUser?.id;
    List<Map<String, dynamic>> maps;
    if (userID != null) {
      maps = await db!.query(tableName, where: 'userID = ?', whereArgs: [userID]);
    } else {
      maps = await db!.query(tableName);
    }
    return List.generate(
        maps.length, (index) => ExerciseTracker.fromMap(maps[index]));
  }

  @override
  Future<List<ExerciseTracker>> fetchByDate(DateTime dateTime) async {
    final db = await DatabaseProvider.database;
    final String begin =
        DateTime(dateTime.year, dateTime.month, dateTime.day).toString();
    final String end = DateTime(
            dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 59, 59)
        .toString();
    String? userID = DataService.currentUser?.id;
    String whereClause = 'date >= ? and date <= ?';
    List<dynamic> whereArgs = [begin, end];
    if (userID != null) {
      whereClause += ' and userID = ?';
      whereArgs.add(userID);
    }
    final List<Map<String, dynamic>> maps = await db!.query(tableName,
        where: whereClause, whereArgs: whereArgs);
    if (maps.isEmpty) return [];
    return List.generate(
        maps.length, (index) => ExerciseTracker.fromMap(maps[index]));
  }

  @override
  Future<void> update(int id, ExerciseTracker obj) async {
    final db = await DatabaseProvider.database;
    await db!.update(tableName, obj.toMap(), where: 'id = ?', whereArgs: [id]);
  }
}

