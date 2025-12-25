import 'package:get/get.dart';
import 'package:vipt/app/data/models/component.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/workout_category.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

class WorkoutController extends GetxController {
  // Reactive lists for UI updates
  final RxList<Workout> workouts = <Workout>[].obs;
  final RxList<WorkoutCategory> workoutCategories = <WorkoutCategory>[].obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoading = true.obs;

  WorkoutCategory workoutTree = WorkoutCategory();
  
  // Lưu lại category đang được xem để refresh khi data thay đổi
  Category? _currentViewingCategory;

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    _setupRealtimeListeners();
  }
  
  /// Thiết lập listeners để lắng nghe thay đổi real-time từ DataService
  void _setupRealtimeListeners() {
    // Lắng nghe thay đổi workout list
    ever(DataService.instance.workoutListRx, (_) {
      _rebuildAllData();
    });
    
    // Lắng nghe thay đổi workout categories
    ever(DataService.instance.workoutCateListRx, (_) {
      _rebuildAllData();
    });
  }
  
  /// Rebuild tất cả dữ liệu khi có thay đổi từ Firebase
  void _rebuildAllData() {
    initWorkoutTree();
    initWorkoutCategories();
    
    // Nếu đang xem một category, refresh danh sách workouts
    if (_currentViewingCategory != null) {
      _refreshCurrentWorkoutList();
    }
  }
  
  /// Refresh danh sách workouts đang hiển thị
  void _refreshCurrentWorkoutList() {
    if (_currentViewingCategory == null) return;
    
    try {
      final component = workoutTree.searchComponent(
        _currentViewingCategory!.id ?? '', 
        workoutTree.components
      );
      if (component != null) {
        workouts.assignAll(List<Workout>.from(component.getList()));
      }
    } catch (e) {
    }
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    try {
      // Đảm bảo dữ liệu đã được tải từ Firebase trước khi khởi tạo
      await _ensureDataLoaded();
      initWorkoutTree();
      initWorkoutCategories();
      initWorkoutList();
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  // Đảm bảo dữ liệu đã được tải
  Future<void> _ensureDataLoaded() async {
    await DataService.instance.loadWorkoutCategory();
    await DataService.instance.loadWorkoutList();
  }

  // Refresh workout data from Firebase
  Future<void> refreshWorkoutData() async {
    isRefreshing.value = true;
    try {
      // Reload từ Firebase (sẽ clear cache và fetch mới)
      await DataService.instance.reloadWorkoutData();

      // Rebuild workout tree từ dữ liệu mới
      initWorkoutTree();

      // Cập nhật danh sách categories và workouts để UI rebuild
      initWorkoutCategories();
      initWorkoutList();

    } catch (e) {
    } finally {
      isRefreshing.value = false;
    }
  }

  // Reload workouts for current category without navigation
  void reloadWorkoutsForCategory(Category cate) {
    _currentViewingCategory = cate;
    
    workouts.assignAll(List<Workout>.from(workoutTree
        .searchComponent(cate.id ?? '', workoutTree.components)!
        .getList()));
  }
  
  // Clear current category khi user rời khỏi màn hình
  void clearCurrentCategory() {
    _currentViewingCategory = null;
  }

  // hàm khởi tạo cây workout
  void initWorkoutTree() {
    final cateList = DataService.instance.workoutCateList;
    final workoutList = DataService.instance.workoutList;

    // Kiểm tra dữ liệu có rỗng không
    if (cateList.isEmpty) {
      workoutTree = WorkoutCategory();
      return;
    }

    // map giữ các workout category
    Map map = {for (var e in cateList) e.id: WorkoutCategory.fromCategory(e)};

    // khởi tạo gốc cây
    workoutTree = WorkoutCategory();

    // thiết lập các node của cây là các workout category
    for (var item in cateList) {
      if (item.isRootCategory()) {
        workoutTree.add(map[item.id]);
      } else {
        WorkoutCategory? parentCate = map[item.parentCategoryID];
        if (parentCate != null) {
          parentCate.add(WorkoutCategory.fromCategory(item));
        }
      }
    }

    // thêm các workout vào các workout category phù hợp
    for (var item in workoutList) {
      for (var cateID in item.categoryIDs) {
        WorkoutCategory? wkCate =
            workoutTree.searchComponent(cateID, workoutTree.components);
        if (wkCate != null) {
          wkCate.add(item);
        }
      }
    }
  }

  void initWorkoutList() {
    workouts.clear();
  }

  void initWorkoutCategories() {
    // workoutCategories = DataService.instance.workoutCateList
    //     .where((element) => element.parentCategoryID == null)
    //     .toList();

    workoutCategories
        .assignAll(List<WorkoutCategory>.from(workoutTree.getList()));
  }

  // void initCateListAndNumWorkout() {
  //   cateListAndNumWorkout = DataService.instance.cateListAndNumWorkout;
  // }

  void loadWorkoutListBaseOnCategory(Category cate) {
    // Lưu lại category đang xem
    _currentViewingCategory = cate;

    workouts.assignAll(List<Workout>.from(workoutTree
        .searchComponent(cate.id ?? '', workoutTree.components)!
        .getList()));
    Get.toNamed(Routes.exerciseList, arguments: cate);
  }

  void loadChildCategoriesBaseOnParentCategory(String categoryID) {
    // workoutCategories = DataService.instance.workoutCateList
    //     .where((element) => element.parentCategoryID == categoryID)
    //     .toList();

    workoutCategories.assignAll(List<WorkoutCategory>.from(workoutTree
        .searchComponent(categoryID, workoutTree.components)!
        .getList()));
    Get.toNamed(Routes.workoutCategory, preventDuplicates: false);
  }

  void loadContent(Component comp) {
    var cate = comp as WorkoutCategory;
    if (cate.hasChildIsCate()) {
      loadChildCategoriesBaseOnParentCategory(cate.id ?? '');
    } else {
      loadWorkoutListBaseOnCategory(cate);
    }
  }
}
