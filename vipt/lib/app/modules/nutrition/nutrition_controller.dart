import 'package:get/get.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/component.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/meal_category.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

class NutritionController extends GetxController {
  // Reactive lists for UI updates
  final RxList<Meal> meals = <Meal>[].obs;
  final RxList<MealCategory> mealCategories = <MealCategory>[].obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoading = true.obs;
  
  MealCategory mealTree = MealCategory();
  
  // Lưu lại category đang được xem để refresh khi data thay đổi
  Category? _currentViewingCategory;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupRealtimeListeners();
  }
  
  /// Thiết lập listeners để lắng nghe thay đổi real-time từ DataService
  bool _isRebuilding = false; // Flag để tránh rebuild lặp lại
  
  void _setupRealtimeListeners() {
    ever(DataService.instance.mealListRx, (_) {
      final count = DataService.instance.mealListRx.length;
      
      // Chỉ rebuild nếu có data và chưa đang rebuild
      if (count > 0 && 
          DataService.instance.mealCategoryListRx.isNotEmpty && 
          !_isRebuilding) {
        _rebuildAllData();
      }
    });
    
    ever(DataService.instance.mealCategoryListRx, (_) {
      final count = DataService.instance.mealCategoryListRx.length;
      
      // Chỉ rebuild nếu có data và chưa đang rebuild
      if (count > 0 && 
          DataService.instance.mealListRx.isNotEmpty && 
          !_isRebuilding) {
        _rebuildAllData();
      }
    });
    
  }
  
  /// Rebuild tất cả dữ liệu khi có thay đổi từ API
  void _rebuildAllData() {
    // Tránh rebuild lặp lại
    if (_isRebuilding) {
      print('⏸️ Already rebuilding, skipping...');
      return;
    }
    
    _isRebuilding = true;
    
    // Chỉ rebuild tree, không reload data từ API (data đã được update qua stream)
    // Việc reload sẽ được xử lý bởi stream listener
    try {
      initMealTree();
      initMealCategories();
      
      if (_currentViewingCategory != null) {
        _refreshCurrentMealList();
      }
    } catch (e) {
      print('❌ Error rebuilding meal data: $e');
    } finally {
      // Reset flag sau một khoảng thời gian ngắn để tránh block quá lâu
      Future.delayed(const Duration(milliseconds: 500), () {
        _isRebuilding = false;
      });
    }
  }
  
  /// Refresh danh sách meals đang hiển thị
  void _refreshCurrentMealList() {
    if (_currentViewingCategory == null) return;
    
    try {
      final categoryId = _currentViewingCategory!.id ?? '';
      
      final component = mealTree.searchComponent(categoryId, mealTree.components);
      
      if (component != null) {
        final mealList = List<Meal>.from(component.getList());
        meals.assignAll(mealList);
      }
    } catch (e) {
    }
  }
  
  Future<void> _initializeData() async {
    isLoading.value = true;
    try {
      await _ensureDataLoaded();
      initMealTree();
      initMealCategories();
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> _ensureDataLoaded() async {
    try {
      // Chỉ load nếu chưa có data
      if (DataService.instance.mealCategoryList.isEmpty) {
        await DataService.instance.loadMealCategoryList();
        print('Meal categories loaded: ${DataService.instance.mealCategoryList.length}');
      }
    } catch (e) {
      print('Error loading meal categories: $e');
    }
    
    try {
      // Chỉ load nếu chưa có data, không force reload để tránh gọi API lặp lại
      if (DataService.instance.mealList.isEmpty) {
        await DataService.instance.loadMealList();
        print('Meals loaded: ${DataService.instance.mealList.length}');
      }
    } catch (e) {
      print('Error loading meals: $e');
    }
  }
  
  Future<void> refreshMealData() async {
    isRefreshing.value = true;
    try {
      await DataService.instance.reloadMealData();
      initMealTree();
      initMealCategories();
    } catch (e) {
    } finally {
      isRefreshing.value = false;
    }
  }

  void initMealCategories() {
    mealCategories.assignAll(List<MealCategory>.from(mealTree.getList()));
  }

  void initMealTree() {
    final cateList = DataService.instance.mealCategoryList;
    final mealListData = DataService.instance.mealList;
    
    print('Initializing meal tree: ${cateList.length} categories, ${mealListData.length} meals');
    
    if (cateList.isEmpty) {
      print('Warning: No meal categories found');
      mealTree = MealCategory();
      return;
    }
    
    if (mealListData.isEmpty) {
      print('Warning: No meals found');
    }
    
    Map<String, MealCategory> map = {
      for (var e in cateList)
        if (e.id != null && e.id!.isNotEmpty)
          e.id!: MealCategory.fromCategory(e)
    };

    mealTree = MealCategory();

    // Build category tree
    for (var item in cateList) {
      if (item.id == null || item.id!.isEmpty) continue;
      
      if (item.isRootCategory()) {
        mealTree.add(map[item.id]!);
      } else {
        MealCategory? parentCate = map[item.parentCategoryID ?? ''];
        if (parentCate != null) {
          parentCate.add(map[item.id]!);
        }
      }
    }

    // Add meals to categories
    for (var item in mealListData) {
      if (item.categoryIDs.isEmpty) {
        print('⚠️ Meal ${item.name} has no categoryIDs');
        continue;
      }
      
      for (var cateID in item.categoryIDs) {
        if (cateID.isEmpty) continue;
        
        MealCategory? wkCate =
            mealTree.searchComponent(cateID, mealTree.components);
        if (wkCate != null) {
          wkCate.add(item);
          print('✅ Added meal ${item.name} to category ${wkCate.name}');
        } else {
          print('⚠️ Category $cateID not found for meal ${item.name}');
        }
      }
    }
    
    print('✅ Meal tree initialized: ${mealTree.components.length} root categories');
  }

  void loadMealsBaseOnCategory(Category cate) {
    _currentViewingCategory = cate;
    
    meals.assignAll(List<Meal>.from(mealTree
        .searchComponent(cate.id ?? '', mealTree.components)!
        .getList()));
    Get.toNamed(Routes.dishList, arguments: cate);
  }
  
  void reloadMealsForCategory(Category cate) {
    _currentViewingCategory = cate;
    
    meals.assignAll(List<Meal>.from(mealTree
        .searchComponent(cate.id ?? '', mealTree.components)!
        .getList()));
  }
  
  void clearCurrentCategory() {
    _currentViewingCategory = null;
  }

  void loadChildCategoriesBaseOnParentCategory(String categoryID) {
    mealCategories.assignAll(List<MealCategory>.from(
        mealTree.searchComponent(categoryID, mealTree.components)!.getList()));
    Get.toNamed(Routes.dishCategory, preventDuplicates: false);
  }

  void loadContent(Component comp) {
    var cate = comp as MealCategory;
    if (cate.hasChildIsCate()) {
      loadChildCategoriesBaseOnParentCategory(cate.id ?? '');
    } else {
      loadMealsBaseOnCategory(cate);
    }
  }
}
