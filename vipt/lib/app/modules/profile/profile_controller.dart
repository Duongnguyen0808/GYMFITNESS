import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vipt/app/data/models/exercise_tracker.dart';
import 'package:vipt/app/data/models/meal_nutrition_tracker.dart';
import 'package:vipt/app/data/models/water_tracker.dart';
import 'package:vipt/app/data/models/weight_tracker.dart';
import 'package:vipt/app/data/providers/exercise_track_provider.dart';
import 'package:vipt/app/data/providers/meal_nutrition_track_provider.dart';
import 'package:vipt/app/data/providers/water_track_provider.dart';
import 'package:vipt/app/data/providers/weight_tracker_provider.dart';

class ProfileController extends GetxController {
  static final DateTime _firstDateOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  static final DateTime _lastDateOfWeek =
      _firstDateOfWeek.add(const Duration(days: 7));
  static final DateTimeRange defaultDateTime =
      DateTimeRange(start: _firstDateOfWeek, end: _lastDateOfWeek);
  static final DateTimeRange defaultWeightDateRange =
      DateTimeRange(start: _firstDateOfWeek, end: DateTime.now());
  static const String defaultImageStr = '';
  static const String beforeImagePrefKey = 'beforeImage';
  static const String afterImagePrefKey = 'afterImage';

  final Future<SharedPreferences> prefs = SharedPreferences.getInstance();

  final _exerciseProvider = ExerciseTrackProvider();
  final _nutritionProvider = MealNutritionTrackProvider();
  final _waterProvider = WaterTrackProvider();
  final _weightProvider = WeightTrackerProvider();

  // ------------------------ Exercise Track ------------------------ //
  Rx<double> exerciseSecondsWeekly = 0.0.obs;
  Rx<int> exerciseCaloriesWeekly = 0.obs;
  RxList<List<ExerciseTracker>> exerciseTracksWeekly =
      <List<ExerciseTracker>>[[], [], [], [], [], [], []].obs;
  Rx<DateTimeRange> exerciseDateRange = defaultDateTime.obs;

  RxString exerciseStartDateStr = ''.obs;
  RxString exerciseEndDateStr = ''.obs;
  
  void _updateExerciseDateStrings() {
    exerciseStartDateStr.value = '${exerciseDateRange.value.start.day}/${exerciseDateRange.value.start.month}/${exerciseDateRange.value.start.year}';
    exerciseEndDateStr.value = '${exerciseDateRange.value.end.day}/${exerciseDateRange.value.end.month}/${exerciseDateRange.value.end.year}';
  }
  List<int>? _cachedExerciseCaloList;
  List<int> get exerciseCaloList {
    if (_cachedExerciseCaloList != null) return _cachedExerciseCaloList!;
    
    List<int> list = List<int>.generate(exerciseTracksWeekly.length, (index) {
      int count = 0;
      for (var element in exerciseTracksWeekly[index]) {
        count += element.outtakeCalories;
      }
      return count;
    });
    list.add(1);
    _cachedExerciseCaloList = list;
    return list;
  }

  Future<void> changeExerciseDateRange(
      DateTime startDate, DateTime endDate) async {
    exerciseDateRange.value = DateTimeRange(start: startDate, end: endDate);
    _updateExerciseDateStrings();
    await loadExerciseTracks();
  }

  Future<void> loadExerciseTracks() async {
    exerciseCaloriesWeekly.value = 0;
    exerciseSecondsWeekly.value = 0;

    // Load song song thay vì tuần tự
    final futures = List.generate(7, (i) async {
      final date = exerciseDateRange.value.start.add(Duration(days: i));
      return await _exerciseProvider.fetchByDate(date);
    });

    final results = await Future.wait(futures);

    for (int i = 0; i < 7; i++) {
      final exerciseTracks = results[i];
      int temptOuttakeCalories = 0;
      double temptTotalTime = 0;
      for (var element in exerciseTracks) {
        temptOuttakeCalories += element.outtakeCalories;
        temptTotalTime += element.totalTime;
      }

      exerciseCaloriesWeekly.value += temptOuttakeCalories;
      exerciseSecondsWeekly.value += temptTotalTime;
      exerciseTracksWeekly[i] = exerciseTracks;
    }
    _cachedExerciseCaloList = null; // Clear cache khi load lại
  }
  // ------------------------ Exercise Track ------------------------ //

  // ------------------------ Nutrition Track ------------------------ //
  Rx<int> nutritionCaloWeekly = 0.obs;
  RxList<List<MealNutritionTracker>> nutritionTracksWeekly =
      <List<MealNutritionTracker>>[[], [], [], [], [], [], []].obs;
  Rx<DateTimeRange> nutritionDateRange = defaultDateTime.obs;

  RxString nutritionStartDateStr = ''.obs;
  RxString nutritionEndDateStr = ''.obs;
  
  void _updateNutritionDateStrings() {
    nutritionStartDateStr.value = '${nutritionDateRange.value.start.day}/${nutritionDateRange.value.start.month}/${nutritionDateRange.value.start.year}';
    nutritionEndDateStr.value = '${nutritionDateRange.value.end.day}/${nutritionDateRange.value.end.month}/${nutritionDateRange.value.end.year}';
  }
  List<int>? _cachedNutritionCaloList;
  List<int> get nutritionCaloList {
    if (_cachedNutritionCaloList != null) return _cachedNutritionCaloList!;
    
    List<int> list = List<int>.generate(nutritionTracksWeekly.length, (index) {
      int count = 0;
      for (var element in nutritionTracksWeekly[index]) {
        count += element.intakeCalories;
      }
      return count;
    });
    list.add(1);
    _cachedNutritionCaloList = list;
    return list;
  }

  Future<void> loadNutritionTracks() async {
    nutritionCaloWeekly.value = 0;
    nutritionTracksWeekly.value = [[], [], [], [], [], [], []];
    
    // Load song song thay vì tuần tự
    final futures = List.generate(7, (i) async {
      final date = nutritionDateRange.value.start.add(Duration(days: i));
      return await _nutritionProvider.fetchByDate(date);
    });

    final results = await Future.wait(futures);
    int temptSum = 0;

    for (int i = 0; i < 7; i++) {
      final nutritionTracks = results[i];
      int temptIntakeCalories = 0;
      for (var element in nutritionTracks) {
        temptIntakeCalories += element.intakeCalories;
      }
      temptSum += temptIntakeCalories;
      nutritionTracksWeekly[i] = nutritionTracks;
    }

    nutritionCaloWeekly.value = temptSum;
    _cachedNutritionCaloList = null; // Clear cache khi load lại
  }

  Future<void> changeNutritionDateChange(
      DateTime startDate, DateTime endDate) async {
    nutritionDateRange.value = DateTimeRange(start: startDate, end: endDate);
    _updateNutritionDateStrings();
    await loadNutritionTracks();
  }
  // ------------------------ Nutrition Track ------------------------ //

  // ------------------------ Water Track ------------------------ //
  Rx<int> waterVolumeWeekly = 0.obs;
  RxList<List<WaterTracker>> waterTracksWeekly =
      <List<WaterTracker>>[[], [], [], [], [], [], []].obs;
  Rx<DateTimeRange> waterDateRange = defaultDateTime.obs;

  RxString waterStartDateStr = ''.obs;
  RxString waterEndDateStr = ''.obs;
  
  void _updateWaterDateStrings() {
    waterStartDateStr.value = '${waterDateRange.value.start.day}/${waterDateRange.value.start.month}/${waterDateRange.value.start.year}';
    waterEndDateStr.value = '${waterDateRange.value.end.day}/${waterDateRange.value.end.month}/${waterDateRange.value.end.year}';
  }
  List<int>? _cachedWaterVolumeList;
  List<int> get waterVolumeList {
    if (_cachedWaterVolumeList != null) return _cachedWaterVolumeList!;
    
    List<int> list = List<int>.generate(waterTracksWeekly.length, (index) {
      int count = 0;
      for (var element in waterTracksWeekly[index]) {
        count += element.waterVolume;
      }
      return count;
    });
    list.add(1);
    _cachedWaterVolumeList = list;
    return list;
  }

  Future<void> loadWaterTracks() async {
    waterVolumeWeekly.value = 0;
    
    // Load song song thay vì tuần tự
    final futures = List.generate(7, (i) async {
      final date = waterDateRange.value.start.add(Duration(days: i));
      return await _waterProvider.fetchByDate(date);
    });

    final results = await Future.wait(futures);
    int temptSum = 0;

    for (int i = 0; i < 7; i++) {
      final waterTracks = results[i];
      int temptWaterVolume = 0;
      for (var element in waterTracks) {
        temptWaterVolume += element.waterVolume;
      }
      temptSum += temptWaterVolume;
      waterTracksWeekly[i] = waterTracks;
    }
    waterVolumeWeekly.value = temptSum;
    _cachedWaterVolumeList = null; // Clear cache khi load lại
  }

  Future<void> changeWaterDateChange(
      DateTime startDate, DateTime endDate) async {
    waterDateRange.value = DateTimeRange(start: startDate, end: endDate);
    _updateWaterDateStrings();
    await loadWaterTracks();
  }
  // ------------------------ Water Track ------------------------ //

  // ------------------------ Weight Track ------------------------ //
  Rx<DateTimeRange> weightDateRange = defaultWeightDateRange.obs;
  RxList<WeightTracker> allWeightTracks = <WeightTracker>[].obs;

  RxString weightStartDateStr = ''.obs;
  RxString weightEndDateStr = ''.obs;
  
  void _updateWeightDateStrings() {
    weightStartDateStr.value = '${weightDateRange.value.start.day}/${weightDateRange.value.start.month}/${weightDateRange.value.start.year}';
    weightEndDateStr.value = '${weightDateRange.value.end.day}/${weightDateRange.value.end.month}/${weightDateRange.value.end.year}';
  }

  Map<DateTime, double>? _cachedWeightTrackMap;
  DateTimeRange? _cachedWeightDateRange;

  Map<DateTime, double> get weightTrackList {
    // Cache result để tránh sort lại mỗi lần get
    if (_cachedWeightTrackMap != null && 
        _cachedWeightDateRange == weightDateRange.value) {
      return _cachedWeightTrackMap!;
    }

    final sortedTracks = List<WeightTracker>.from(allWeightTracks);
    sortedTracks.sort((x, y) => x.date.compareTo(y.date));

    final result = sortedTracks.length == 1 
        ? _fakeMap(sortedTracks) 
        : _convertToMap(sortedTracks);
    
    _cachedWeightTrackMap = result;
    _cachedWeightDateRange = weightDateRange.value;
    
    return result;
  }

  Map<DateTime, double> _convertToMap(List<WeightTracker> tracks) {
    return {for (var e in tracks) e.date: e.weight.toDouble()};
  }

  Map<DateTime, double> _fakeMap(List<WeightTracker> tracks) {
    var map = _convertToMap(tracks);
    if (tracks.isNotEmpty) {
      map.addAll({tracks.first.date.subtract(const Duration(days: 1)): 0});
    }
    return map;
  }


  Future<void> loadWeightTracks() async {
    allWeightTracks.clear();
    _cachedWeightTrackMap = null; // Clear cache khi load lại
    int duration = weightDateRange.value.duration.inDays + 1;
    
    // Load song song thay vì tuần tự
    final futures = List.generate(duration, (i) async {
      final fetchDate = weightDateRange.value.start.add(Duration(days: i));
      return await _weightProvider.fetchByDate(fetchDate);
    });

    final results = await Future.wait(futures);

    for (int i = 0; i < duration; i++) {
      final weighTracks = results[i];
      if (weighTracks.isNotEmpty) {
        weighTracks.sort((x, y) => x.weight.compareTo(y.weight));
        allWeightTracks.add(weighTracks.last);
      }
    }
  }

  Future<void> changeWeighDateRange(
      DateTime startDate, DateTime endDate) async {
    if (startDate.day == endDate.day &&
        startDate.month == endDate.month &&
        startDate.year == endDate.year) {
      startDate = startDate.subtract(const Duration(days: 1));
    }
    weightDateRange.value = DateTimeRange(start: startDate, end: endDate);
    _updateWeightDateStrings();
    await loadWeightTracks();
  }
  // ------------------------ Weight Track ------------------------ //

  // ------------------------ Image Before - After ------------------------ //

  RxString beforeImagePath = defaultImageStr.obs;
  RxString afterImagePath = defaultImageStr.obs;

  Future<void> loadImagesFromApplicationFolder() async {
    final _prefs = await prefs;
    String? beforeImageSavedPath = _prefs.getString(beforeImagePrefKey);
    if (beforeImageSavedPath != null) {
      beforeImagePath.value = beforeImageSavedPath;
    }

    String? afterImageSavedPath = _prefs.getString(afterImagePrefKey);
    if (afterImageSavedPath != null) {
      afterImagePath.value = afterImageSavedPath;
    }
  }

  Future<File> saveImagesToApplicationFolder(
      String prefKey, File imageFile) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;

    final fileName = basename(imageFile.path);
    final File localFile = await imageFile.copy('$appDocPath/$fileName');

    final _prefs = await prefs;
    await _prefs.setString(prefKey, localFile.path);

    return localFile;
  }

  Future<void> pickBeforeImage(File imageFile) async {
    beforeImagePath.value = imageFile.path;
    await saveImagesToApplicationFolder(beforeImagePrefKey, imageFile);
  }

  Future<void> pickAfterImage(File imageFile) async {
    afterImagePath.value = imageFile.path;
    await saveImagesToApplicationFolder(afterImagePrefKey, imageFile);
  }

  // ------------------------ Image Before - After ------------------------ //

  final RxBool isLoading = true.obs;

  @override
  void onInit() async {
    super.onInit();
    // Tăng delay initial load để UI render trước, tránh block main thread
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Load dữ liệu song song nhưng không block UI
    _loadDataInBackground();
  }

  Future<void> _loadDataInBackground() async {
    isLoading.value = true;
    try {
      // Initialize date strings
      _updateExerciseDateStrings();
      _updateNutritionDateStrings();
      _updateWaterDateStrings();
      _updateWeightDateStrings();
      
      // Load dữ liệu song song thay vì tuần tự để tăng tốc độ
      await Future.wait([
        loadExerciseTracks(),
        loadNutritionTracks(),
        loadWaterTracks(),
        loadWeightTracks(),
        loadImagesFromApplicationFolder(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }
}
