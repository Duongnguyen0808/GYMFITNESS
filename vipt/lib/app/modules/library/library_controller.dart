import 'dart:async';
import 'package:get/get.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/data/providers/library_section_provider_api.dart';
import 'package:vipt/app/data/models/library_section.dart';

class LibraryController extends GetxController {
  // Loading states
  final RxBool isRefreshing = false.obs;
  final RxBool hasDataUpdated = false.obs;

  // Chỉ giữ lại 3 mục đã test hoạt động
  static const List<String> _allowedRoutes = [
    '/workoutCategory', // Danh mục bài tập
    '/workoutCollectionCategory', // Danh mục bộ luyện tập
    '/dishCategory', // Danh mục món ăn
  ];

  // Library sections
  final RxList<LibrarySection> sections = <LibrarySection>[].obs;
  final LibrarySectionProvider _sectionProvider = LibrarySectionProvider();
  StreamSubscription<List<LibrarySection>>? _sectionsSubscription;

  @override
  void onInit() async {
    super.onInit();
    await _loadAllData();
    await _loadLibrarySections();
    _setupRealtimeListeners();
  }

  /// Load library sections from Firestore
  /// Chỉ hiển thị các section có route được cho phép
  Future<void> _loadLibrarySections() async {
    try {
      final activeSections = await _sectionProvider.fetchActiveSections();
      sections.value = activeSections
          .where((s) => _allowedRoutes.contains(s.route))
          .toList();
    } catch (e) {
    }
  }

  /// Thiết lập listeners để lắng nghe thay đổi real-time từ DataService
  void _setupRealtimeListeners() {
    // Lắng nghe thay đổi từ tất cả các nguồn dữ liệu
    ever(DataService.instance.mealListRx, (_) {
      hasDataUpdated.value = true;
    });

    ever(DataService.instance.workoutListRx, (_) {
      hasDataUpdated.value = true;
    });

    ever(DataService.instance.mealCollectionListRx, (_) {
      hasDataUpdated.value = true;
    });

    ever(DataService.instance.collectionListRx, (_) {
      hasDataUpdated.value = true;
    });

    // Lắng nghe thay đổi library sections từ Firestore
    // Chỉ hiển thị các section có route được cho phép
    _sectionsSubscription = _sectionProvider.streamAll().listen(
      (sections) {
        final activeSections = sections
            .where((s) => s.isActive && _allowedRoutes.contains(s.route))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        this.sections.value = activeSections;
      },
      onError: (error) {
        // Xử lý lỗi gracefully (ví dụ: missing Firestore index)
        // Không làm crash app, chỉ log lỗi
        // Sections sẽ được load từ fetchActiveSections() nếu stream fail
      },
    );
  }

  @override
  void onClose() {
    _sectionsSubscription?.cancel();
    super.onClose();
  }

  // Load all data initially
  Future<void> _loadAllData() async {
    await DataService.instance.loadWorkoutCategory();
    await DataService.instance.loadWorkoutList();
    await DataService.instance.loadCollectionCategoryList();
    await DataService.instance.loadCollectionList();
    await DataService.instance.loadUserCollectionList();
    await DataService.instance.loadMealCategoryList();
    await DataService.instance.loadMealList();
    await DataService.instance.loadMealCollectionList();
  }

  // Refresh all data from Firebase (called by pull-to-refresh)
  Future<void> refreshAllData() async {
    isRefreshing.value = true;
    await _loadLibrarySections();
    try {
      await DataService.instance.reloadAllData();
      Get.snackbar(
        'Đã cập nhật',
        'Dữ liệu đã được cập nhật thành công',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật dữ liệu: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  // Refresh workout data only
  Future<void> refreshWorkoutData() async {
    isRefreshing.value = true;
    try {
      await DataService.instance.reloadWorkoutData();
    } finally {
      isRefreshing.value = false;
    }
  }

  // Refresh meal data only
  Future<void> refreshMealData() async {
    isRefreshing.value = true;
    try {
      await DataService.instance.reloadMealData();
    } finally {
      isRefreshing.value = false;
    }
  }
}
