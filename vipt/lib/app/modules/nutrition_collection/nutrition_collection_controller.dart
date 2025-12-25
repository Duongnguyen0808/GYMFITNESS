import 'package:get/get.dart';
import 'package:vipt/app/data/models/meal_collection.dart';
import 'package:vipt/app/data/models/meal_nutrition.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/services/data_service.dart';

class NutritionCollectionController extends GetxController {
  // Reactive lists for UI updates
  final RxList<MealCollection> mealCollectionList = <MealCollection>[].obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoading = true.obs;
  
  // meal list cua collection dang duoc chon
  List<MealNutrition> currentMealList = [];
  
  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupRealtimeListeners();
  }
  
  /// Thiết lập listeners để lắng nghe thay đổi real-time từ DataService
  void _setupRealtimeListeners() {
    // Lắng nghe thay đổi meal collection list
    ever(DataService.instance.mealCollectionListRx, (_) {
      _loadMealCollections();
    });
  }
  
  Future<void> _initializeData() async {
    isLoading.value = true;
    try {
      // Đảm bảo dữ liệu đã được tải từ Firebase trước khi khởi tạo
      await DataService.instance.loadMealCollectionList();
      _loadMealCollections();
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }
  
  void _loadMealCollections() {
    mealCollectionList.assignAll(DataService.instance.mealCollectionList);
  }
  
  // Refresh meal collection data from Firebase
  Future<void> refreshMealCollectionData() async {
    isRefreshing.value = true;
    try {
      await DataService.instance.reloadMealData();
      _loadMealCollections();
    } finally {
      isRefreshing.value = false;
    }
  }

  late MealCollection currentCollection;

  num averageCalories = 0;
  num averageCarbs = 0;
  num averageProtein = 0;
  num averageFat = 0;

  setCurrentCollection(MealCollection mealCollection) {
    currentCollection = mealCollection;
  }

  initNutritionInfor() {
    averageCalories = 0;
    averageCarbs = 0;
    averageProtein = 0;
    averageFat = 0;
  }

  calculateNutritionInfor() {
    initNutritionInfor();
    for (var meal in currentMealList) {
      averageCalories += meal.calories;
      averageCarbs += meal.carbs;
      averageProtein += meal.protein;
      averageFat += meal.fat;
    }

    averageCalories /= currentCollection.dateToMealID.length;
    averageCarbs /= currentCollection.dateToMealID.length;
    averageProtein /= currentCollection.dateToMealID.length;
    averageFat /= currentCollection.dateToMealID.length;
  }

  fetchMealNutritionList() async {
    currentMealList.clear();
    final mealProvider = MealProvider();
    for (var element in currentCollection.dateToMealID.entries) {
      for (var mealID in element.value) {
        final meal = await mealProvider.fetch(mealID);
        final mealNutri = MealNutrition(meal: meal);
        await mealNutri.getIngredients();
        currentMealList.add(mealNutri);
      }
    }
  }

  getMealListByDay(String dayId) {
    return currentMealList
        .where((element) =>
            currentCollection.dateToMealID[dayId]!.contains(element.meal.id) ==
            true)
        .toList();
  }
}
