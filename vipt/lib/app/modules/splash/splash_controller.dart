import 'dart:async';

import 'package:get/get.dart';
import 'package:vipt/app/data/services/app_start_service.dart';
import 'package:vipt/app/data/services/auth_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() async {
    super.onInit();
    await AppStartService.instance.initService();
    await Future.delayed(const Duration(seconds: 3), () {});
    await _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (AuthService.instance.isLogin &&
        await AuthService.instance.isHasData()) {
      // KHÔNG clear dữ liệu khi đăng nhập lại - dữ liệu sẽ được filter theo userID
      await DataService.instance.loadUserData();
      
      // Load dữ liệu ban đầu trước khi vào home screen
      await _loadInitialData();
      
      // Bắt đầu lắng nghe real-time streams sau khi đăng nhập thành công
      DataService.instance.startListeningToStreams();
      DataService.instance.startListeningToUserCollections();
      
      Get.offAllNamed(Routes.home);
    } else {
      Get.offAllNamed(Routes.auth);
    }
  }
  
  /// Load dữ liệu ban đầu để đảm bảo màn hình chính có dữ liệu hiển thị
  Future<void> _loadInitialData() async {
    try {
      // Load dữ liệu song song để tăng tốc độ
      await Future.wait<void>([
        DataService.instance.loadWorkoutCategory(),
        DataService.instance.loadWorkoutList(),
        DataService.instance.loadMealCategoryList(),
        DataService.instance.loadMealList(),
        DataService.instance.loadCollectionCategoryList(),
        DataService.instance.loadCollectionList(),
        DataService.instance.loadMealCollectionList(),
      ]);
      print('✅ Đã load dữ liệu ban đầu thành công');
    } catch (e) {
      print('⚠️ Lỗi khi load dữ liệu ban đầu: $e');
      // Tiếp tục vào home screen ngay cả khi có lỗi
    }
  }
}
