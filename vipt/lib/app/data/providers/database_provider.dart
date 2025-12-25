import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vipt/app/core/values/values.dart';

class DatabaseProvider {
  DatabaseProvider._();

  static const String dbName = 'vipt_trackers_database.db';

  static final DatabaseProvider instance = DatabaseProvider._();

  static Database? _database;

  static Future<Database?> get database async {
    if (kIsWeb) {
      return null;
    }
    if (_database != null) return _database;
    _database = await open();
    return _database;
  }

  static Future<Database> open() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web platform');
    }
    return await openDatabase(
      join(await getDatabasesPath(), dbName),
      version: 2,
      onCreate: (db, version) async => _createDB(db),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Thêm userID vào các bảng tracker
          await db.execute('ALTER TABLE ${AppValue.waterTrackTable} ADD COLUMN userID TEXT');
          await db.execute('ALTER TABLE ${AppValue.exerciseTrackTable} ADD COLUMN userID TEXT');
          await db.execute('ALTER TABLE ${AppValue.mealNutritionTrackTable} ADD COLUMN userID TEXT');
          await db.execute('ALTER TABLE ${AppValue.localMealTable} ADD COLUMN userID TEXT');
          await db.execute('ALTER TABLE ${AppValue.weightTrackTable} ADD COLUMN userID TEXT');
        }
      },
    );
  }

  static _createDB(Database db) async {
    db.execute('''
      CREATE TABLE ${AppValue.waterTrackTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        waterVolume INTEGER,
        userID TEXT)
    ''');

    db.execute(''' 
    CREATE TABLE ${AppValue.exerciseTrackTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        outtakeCalories INTEGER,
        sessionNumber INTEGER,
        totalTime INTEGER,
        userID TEXT)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.mealNutritionTrackTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date TEXT,
        intakeCalories INTEGER,
        carbs INTEGER,
        protein INTEGER,
        fat INTEGER,
        userID TEXT)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.localMealTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        calories INTEGER,
        carbs INTEGER,
        protein INTEGER,
        fat INTEGER,
        userID TEXT)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.weightTrackTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        weight INTEGER,
        userID TEXT)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.workoutPlanTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dailyGoalCalories REAL,
        userID TEXT,
        startDate TEXT,
        endDate TEXT)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.planExerciseCollectionTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        planID INTEGER,
        collectionSettingID INTEGER)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.planExerciseTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exerciseID TEXT,
        listID INTEGER)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.planExerciseCollectionSettingTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        round INTEGER,
        numOfWorkoutPerRound INTEGER,
        isStartWithWarmUp INTEGER,
        isShuffle INTEGER,
        exerciseTime INTEGER,
        transitionTime INTEGER,
        restTime INTEGER,
        restFrequency INTEGER)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.planMealCollectionTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        planID INTEGER,
        mealRatio REAL)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.planMealTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealID TEXT,
        listID INTEGER)
    ''');

    db.execute('''
      CREATE TABLE ${AppValue.planStreakTable}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        planID INTEGER,
        value INTEGER)
    ''');
  }

  /// Xóa tất cả dữ liệu local database của user hiện tại (dùng khi đổi user)
  static Future<void> clearAllLocalData({String? userID}) async {
    final db = await database;
    if (db == null) return;
    
    try {
      if (userID != null) {
        // Xóa chỉ dữ liệu của user cụ thể
        await db.delete(AppValue.waterTrackTable, where: 'userID = ?', whereArgs: [userID]);
        await db.delete(AppValue.exerciseTrackTable, where: 'userID = ?', whereArgs: [userID]);
        await db.delete(AppValue.mealNutritionTrackTable, where: 'userID = ?', whereArgs: [userID]);
        await db.delete(AppValue.localMealTable, where: 'userID = ?', whereArgs: [userID]);
        await db.delete(AppValue.weightTrackTable, where: 'userID = ?', whereArgs: [userID]);
        
        // Xóa workout plan của user (workoutPlanTable đã có userID)
        // Lấy danh sách planID của user trước khi xóa
        final planMaps = await db.query(AppValue.workoutPlanTable, 
            columns: ['id'], 
            where: 'userID = ?', 
            whereArgs: [userID]);
        final planIDs = planMaps.map((map) => map['id'] as int).toList();
        
        // Xóa các bảng liên quan đến plan trước
        if (planIDs.isNotEmpty) {
          final placeholders = planIDs.map((_) => '?').join(',');
          // Xóa exercise collections và exercises
          final collectionMaps = await db.query(AppValue.planExerciseCollectionTable,
              columns: ['id'],
              where: 'planID IN ($placeholders)',
              whereArgs: planIDs);
          final collectionIDs = collectionMaps.map((map) => map['id'] as int).toList();
          
          if (collectionIDs.isNotEmpty) {
            final collectionPlaceholders = collectionIDs.map((_) => '?').join(',');
            await db.delete(AppValue.planExerciseTable,
                where: 'listID IN ($collectionPlaceholders)',
                whereArgs: collectionIDs);
          }
          
          await db.delete(AppValue.planExerciseCollectionTable,
              where: 'planID IN ($placeholders)',
              whereArgs: planIDs);
          
          // Xóa meal collections và meals
          final mealCollectionMaps = await db.query(AppValue.planMealCollectionTable,
              columns: ['id'],
              where: 'planID IN ($placeholders)',
              whereArgs: planIDs);
          final mealCollectionIDs = mealCollectionMaps.map((map) => map['id'] as int).toList();
          
          if (mealCollectionIDs.isNotEmpty) {
            final mealCollectionPlaceholders = mealCollectionIDs.map((_) => '?').join(',');
            await db.delete(AppValue.planMealTable,
                where: 'listID IN ($mealCollectionPlaceholders)',
                whereArgs: mealCollectionIDs);
          }
          
          await db.delete(AppValue.planMealCollectionTable,
              where: 'planID IN ($placeholders)',
              whereArgs: planIDs);
          
          // Xóa streaks
          await db.delete(AppValue.planStreakTable,
              where: 'planID IN ($placeholders)',
              whereArgs: planIDs);
        }
        
        // Cuối cùng xóa workout plan
        await db.delete(AppValue.workoutPlanTable, where: 'userID = ?', whereArgs: [userID]);
        
      } else {
        // Nếu không có userID, xóa tất cả (fallback cho trường hợp đăng xuất)
        await db.delete(AppValue.waterTrackTable);
        await db.delete(AppValue.exerciseTrackTable);
        await db.delete(AppValue.mealNutritionTrackTable);
        await db.delete(AppValue.localMealTable);
        await db.delete(AppValue.weightTrackTable);
        await db.delete(AppValue.workoutPlanTable);
        await db.delete(AppValue.planExerciseCollectionTable);
        await db.delete(AppValue.planExerciseTable);
        await db.delete(AppValue.planExerciseCollectionSettingTable);
        await db.delete(AppValue.planMealCollectionTable);
        await db.delete(AppValue.planMealTable);
        await db.delete(AppValue.planStreakTable);
      }
    } catch (e) {
    }
  }

  /// Đóng và reset database connection
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

