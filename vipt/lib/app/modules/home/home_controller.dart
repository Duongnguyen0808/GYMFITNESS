import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:vipt/app/data/others/tab_refesh_controller.dart';
import 'package:vipt/app/modules/daily_plan/daily_plan_controller.dart';
import 'package:vipt/app/modules/library/library_controller.dart';
import 'package:vipt/app/modules/profile/profile_controller.dart';
import 'package:vipt/app/modules/workout_plan/workout_plan_controller.dart';

class HomeController extends GetxController {
  static const int workoutPlanTabIndex = 0;
  static const int dailyPlanTabIndex = 1;
  static const int libraryTabIndex = 2;
  static const int profileTabIndex = 3;
  // int currentTabIndex = workoutPlanTabIndex;

  @override
  Future<void> onInit() async {
    await _initControllerForTabs();
    super.onInit();
    
    // Không cần load lại vì SplashController đã load dữ liệu ban đầu
    // Dữ liệu sẽ được cập nhật real-time qua streams
    
    tabController.addListener(() {
      switch (tabController.index) {
        case 0:
          // Reload calories và streak khi switch về plan tab để cập nhật flame
          if (RefeshTabController.instance.isPlanTabNeedToUpdate) {
            final planController = Get.find<WorkoutPlanController>();
            // Reload calories để validate và cập nhật flame
            planController.loadDailyCalories();
            RefeshTabController.instance.togglePlanTabUpdate();
          }
          break;
        case 1:
          if (RefeshTabController.instance.isDailyTabNeedToUpdate) {
            Get.find<DailyPlanController>().onInit();
            RefeshTabController.instance.toggleDailyTabUpdate();
          }
          break;
        case 2:
          if (RefeshTabController.instance.isLibraryTabNeedToUpdate) {
            Get.find<LibraryController>().onInit();
            RefeshTabController.instance.toggleLibraryTabUpdate();
          }
          break;
        case 3:
          if (RefeshTabController.instance.isProfileTabNeedToUpdate) {
            Get.find<ProfileController>().onInit();
            RefeshTabController.instance.toggleProfileTabUpdate();
          }
          break;
        default:
      }
    });
  }
  

  Future<void> _initControllerForTabs() async {
    Get.lazyPut(() => WorkoutPlanController());
    Get.lazyPut(() => DailyPlanController());
    Get.lazyPut(() => LibraryController());
    Get.lazyPut(() => ProfileController());
  }

  final PersistentTabController tabController =
      PersistentTabController(initialIndex: 0);
}
