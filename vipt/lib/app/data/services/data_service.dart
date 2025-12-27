import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/meal_collection.dart';
import 'package:vipt/app/data/models/vipt_user.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/providers/meal_category_provider_api.dart';
import 'package:vipt/app/data/providers/meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/providers/user_provider_api.dart';
import 'package:vipt/app/data/providers/workout_category_provider_api.dart';
import 'package:vipt/app/data/providers/workout_collection_category_provider_api.dart';
import 'package:vipt/app/data/providers/workout_collection_provider_api.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/providers/database_provider.dart';
import 'package:vipt/app/data/services/auth_service.dart';

class DataService extends GetxService with WidgetsBindingObserver {
  DataService._privateConstructor();

  static final DataService instance = DataService._privateConstructor();
  static ViPTUser? currentUser;

  static final RxList<Workout> _workoutList = <Workout>[].obs;
  static final RxList<Category> _workoutCateList = <Category>[].obs;
  static final RxList<Category> _collectionCateList = <Category>[].obs;
  static final RxList<WorkoutCollection> _collectionList =
      <WorkoutCollection>[].obs;
  static final RxList<WorkoutCollection> _userCollectionList =
      <WorkoutCollection>[].obs;
  static final RxList<Category> _mealCategories = <Category>[].obs;
  static final RxList<Meal> _mealList = <Meal>[].obs;
  static final RxList<MealCollection> _mealCollectionList =
      <MealCollection>[].obs;

  static final RxBool isLoadingWorkouts = false.obs;
  static final RxBool isLoadingMeals = false.obs;
  static final RxBool isLoadingCollections = false.obs;
  static final RxBool isLoadingMealCollections = false.obs;

  final List<StreamSubscription> _streamSubscriptions = [];
  static final RxBool isStreamsActive = false.obs;

  final _userProvider = UserProvider();
  final _workoutProvider = WorkoutProvider();
  final _workoutCategoryProvider = WorkoutCategoryProvider();
  final _collectionCategoryProvider = WorkoutCollectionCategoryProvider();
  final _collectionProvider = WorkoutCollectionProvider();
  final _mealCategoryProvider = MealCategoryProvider();
  final _mealProvider = MealProvider();
  final _mealCollectionProvider = MealCollectionProvider();

  List<Workout> get workoutList => [..._workoutList];
  List<Category> get workoutCateList => [..._workoutCateList];
  List<WorkoutCollection> get collectionList => [..._collectionList];
  List<WorkoutCollection> get userCollectionList => _userCollectionList;
  List<Category> get collectionCateList => [..._collectionCateList];
  List<Category> get mealCategoryList => [..._mealCategories];
  List<Meal> get mealList => [..._mealList];
  List<MealCollection> get mealCollectionList => [..._mealCollectionList];

  RxList<Workout> get workoutListRx => _workoutList;
  RxList<Category> get workoutCateListRx => _workoutCateList;
  RxList<WorkoutCollection> get collectionListRx => _collectionList;
  RxList<WorkoutCollection> get userCollectionListRx => _userCollectionList;
  RxList<Category> get collectionCateListRx => _collectionCateList;
  RxList<Category> get mealCategoryListRx => _mealCategories;
  RxList<Meal> get mealListRx => _mealList;
  RxList<MealCollection> get mealCollectionListRx => _mealCollectionList;

  loadMealCollectionList() async {
    if (_mealCollectionList.isNotEmpty) return;
    isLoadingMealCollections.value = true;
    try {
      final data = await _mealCollectionProvider.fetchAll();
      _mealCollectionList.assignAll(data);
    } catch (e) {
      // Ignore errors
    } finally {
      isLoadingMealCollections.value = false;
    }
  }

  bool _isLoadingMealCategories = false; // Flag để tránh load lặp lại

  loadMealCategoryList() async {
    // Tránh load lặp lại
    if (_isLoadingMealCategories) {
      // print('⏸️ Already loading meal categories, skipping...');
      return;
    }

    if (_mealCategories.isNotEmpty) return;

    _isLoadingMealCategories = true;
    isLoadingMeals.value = true;
    try {
      final data = await _mealCategoryProvider.fetchAll();
      _mealCategories.assignAll(data);
      // print('✅ Loaded ${data.length} meal categories successfully');
    } catch (e) {
      // print('❌ Error loading meal categories: $e');
      // print('Stack trace: ${StackTrace.current}');
      // Giữ lại list rỗng để app không crash
      _mealCategories.clear();
    } finally {
      _isLoadingMealCategories = false;
      isLoadingMeals.value = false;
    }
  }

  bool _isLoadingMeals = false; // Flag để tránh load lặp lại

  loadMealList({bool forceReload = false}) async {
    // Tránh load lặp lại
    if (_isLoadingMeals) {
      // print('⏸️ Already loading meals, skipping...');
      return;
    }

    // Nếu không force reload và đã có data, không load lại
    if (!forceReload && _mealList.isNotEmpty) return;

    _isLoadingMeals = true;
    isLoadingMeals.value = true;
    try {
      final data = await _mealProvider.fetchAll();
      _mealList.assignAll(data);
      // print('✅ Loaded ${data.length} meals successfully');
    } catch (e) {
      // print('❌ Error loading meals: $e');
      // print('Stack trace: ${StackTrace.current}');
      // Giữ lại list rỗng để app không crash
      _mealList.clear();
    } finally {
      _isLoadingMeals = false;
      isLoadingMeals.value = false;
    }
  }

  Future<void> reloadMealData() async {
    isLoadingMeals.value = true;
    isLoadingMealCollections.value = true;
    try {
      _mealCategories.clear();
      _mealList.clear();
      _mealCollectionList.clear();

      // Chạy song song các fetch operations để tăng tốc độ
      final futures = [
        _mealCategoryProvider.fetchAll(),
        _mealProvider.fetchAll(),
        _mealCollectionProvider.fetchAll(),
      ];

      final results = await Future.wait(futures).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // print('⚠️ Timeout khi reload meal data');
          throw TimeoutException('Timeout khi reload meal data');
        },
      );

      _mealCategories.assignAll(results[0] as List<Category>);
      _mealList.assignAll(results[1] as List<Meal>);
      _mealCollectionList.assignAll(results[2] as List<MealCollection>);

      // print('✅ Reloaded meal data: ${results[0].length} categories, ${results[1].length} meals, ${results[2].length} collections');
    } catch (e) {
      // print('❌ Error reloading meal data: $e');
      // print('Stack trace: ${StackTrace.current}');
      // Giữ lại lists rỗng để app không crash
    } finally {
      isLoadingMeals.value = false;
      isLoadingMealCollections.value = false;
    }
  }

  Future<void> reloadWorkoutData() async {
    isLoadingWorkouts.value = true;
    isLoadingCollections.value = true;
    try {
      _workoutList.clear();
      _workoutCateList.clear();
      _collectionList.clear();
      _collectionCateList.clear();

      // Chạy song song các fetch operations để tăng tốc độ
      final futures = [
        _workoutProvider.fetchAll(),
        _workoutCategoryProvider.fetchAll(),
        _collectionProvider.fetchAllDefaultCollection(),
        _collectionCategoryProvider.fetchAll(),
      ];

      final results = await Future.wait(futures).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // print('⚠️ Timeout khi reload workout data');
          throw TimeoutException('Timeout khi reload workout data');
        },
      );

      _workoutList.assignAll(results[0] as List<Workout>);
      _workoutCateList.assignAll(results[1] as List<Category>);
      _collectionList.assignAll(results[2] as List<WorkoutCollection>);
      _collectionCateList.assignAll(results[3] as List<Category>);
    } catch (e) {
      // print('❌ Error reloading workout data: $e');
    } finally {
      isLoadingWorkouts.value = false;
      isLoadingCollections.value = false;
    }
  }

  Future<void> reloadAllData() async {
    try {
      await Future.wait([
        reloadMealData(),
        reloadWorkoutData(),
      ]);
    } catch (e) {
      // Ignore errors
    }
  }

  loadUserCollectionList() async {
    try {
      final data = await _collectionProvider.fetchAllUserCollection();
      _userCollectionList.assignAll(data);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<ViPTUser?> createUser(ViPTUser user) async {
    currentUser = await _userProvider.add(user);
    return currentUser;
  }

  loadUserData() async {
    final currentAuthUser = AuthService.instance.currentUser;
    if (currentAuthUser == null) {
      currentUser = null;
      return;
    }

    final userId = currentAuthUser['_id'] ?? currentAuthUser['id'] ?? '';
    if (userId.isEmpty) {
      currentUser = null;
      return;
    }

    currentUser = await _userProvider.fetch(userId);
  }

  resetUserData() => currentUser = null;

  loadWorkoutList() async {
    if (_workoutList.isNotEmpty) return;
    isLoadingWorkouts.value = true;
    try {
      final data = await _workoutProvider.fetchAll();
      _workoutList.assignAll(data);
    } catch (e) {
      // Ignore errors
    } finally {
      isLoadingWorkouts.value = false;
    }
  }

  loadWorkoutCategory() async {
    if (_workoutCateList.isNotEmpty) return;
    isLoadingWorkouts.value = true;
    try {
      final data = await _workoutCategoryProvider.fetchAll();
      _workoutCateList.assignAll(data);
    } catch (e) {
      // Ignore errors
    } finally {
      isLoadingWorkouts.value = false;
    }
  }

  loadCollectionCategoryList() async {
    if (_collectionCateList.isNotEmpty) return;
    isLoadingCollections.value = true;
    try {
      final data = await _collectionCategoryProvider.fetchAll();
      _collectionCateList.assignAll(data);
    } catch (e) {
      // Ignore errors
    } finally {
      isLoadingCollections.value = false;
    }
  }

  loadCollectionList() async {
    if (_collectionList.isNotEmpty) return;
    isLoadingCollections.value = true;
    try {
      final data = await _collectionProvider.fetchAllDefaultCollection();
      _collectionList.assignAll(data);
    } catch (e) {
      // Ignore errors
    } finally {
      isLoadingCollections.value = false;
    }
  }

  void clearAllCache() {
    _workoutList.clear();
    _workoutCateList.clear();
    _collectionCateList.clear();
    _collectionList.clear();
    _userCollectionList.clear();
    _mealCategories.clear();
    _mealList.clear();
    _mealCollectionList.clear();
  }

  Future<void> clearCacheAndReset() async {
    clearAllCache();
    resetUserData();
    cancelAllStreams();
  }

  Future<void> clearAllUserData() async {
    clearAllCache();
    String? userID = currentUser?.id;
    await DatabaseProvider.clearAllLocalData(userID: userID);
    resetUserData();
    cancelAllStreams();
  }

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cancelAllStreams();
  }

  void startListeningToStreams() {
    if (isStreamsActive.value) {
      return;
    }

    if (AuthService.instance.currentUser == null) {
      return;
    }

    _streamSubscriptions.add(
      _mealProvider.streamAll().listen(
        (meals) {
          // print('📥 Stream meals update: ${meals.length} meals');
          _mealList.assignAll(meals);
        },
        onError: (error) {
          // print('❌ Stream meals error: $error');
          // Continue listening even on error
        },
        cancelOnError: false,
      ),
    );

    _streamSubscriptions.add(
      _mealCategoryProvider.streamAll().listen(
        (categories) {
          // print('📥 Stream meal categories update: ${categories.length} categories');
          _mealCategories.assignAll(categories);
        },
        onError: (error) {
          // print('❌ Stream meal categories error: $error');
        },
      ),
    );

    _streamSubscriptions.add(
      _mealCollectionProvider.streamAll().listen(
        (collections) {
          _mealCollectionList.assignAll(collections);
        },
        onError: (error) {
          // Ignore errors
        },
      ),
    );

    _streamSubscriptions.add(
      _workoutProvider.streamAll().listen(
        (workouts) {
          _workoutList.assignAll(workouts);
        },
        onError: (error) {
          // Ignore errors
        },
      ),
    );

    _streamSubscriptions.add(
      _workoutCategoryProvider.streamAll().listen(
        (categories) {
          _workoutCateList.assignAll(categories);
        },
        onError: (error) {
          // Ignore errors
        },
      ),
    );

    _streamSubscriptions.add(
      _collectionProvider.streamAllDefaultCollection().listen(
        (collections) {
          _collectionList.assignAll(collections);
        },
        onError: (error) {
          // Ignore errors
        },
      ),
    );

    _streamSubscriptions.add(
      _collectionCategoryProvider.streamAll().listen(
        (categories) {
          _collectionCateList.assignAll(categories);
        },
        onError: (error) {
          // Ignore errors
        },
      ),
    );

    isStreamsActive.value = true;
  }

  void startListeningToUserCollections() {
    _streamSubscriptions.add(
      _collectionProvider.streamAllUserCollection().listen(
        (collections) {
          _userCollectionList.assignAll(collections);
        },
        onError: (error) {
          // Ignore errors
        },
      ),
    );
  }

  void cancelAllStreams() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    isStreamsActive.value = false;
  }

  void pauseStreams() {
    for (var subscription in _streamSubscriptions) {
      subscription.pause();
    }
  }

  void resumeStreams() {
    for (var subscription in _streamSubscriptions) {
      subscription.resume();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAppResumed() {
    if (isStreamsActive.value) {
      resumeStreams();
    } else {
      reloadAllData();
    }
  }

  void _onAppPaused() {
    if (isStreamsActive.value) {
      pauseStreams();
    }
  }
}
