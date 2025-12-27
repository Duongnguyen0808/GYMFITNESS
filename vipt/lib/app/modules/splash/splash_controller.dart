import 'dart:async';

import 'package:get/get.dart';
import 'package:vipt/app/data/services/auth_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Không dùng async ở onInit, thay vào đó gọi hàm async riêng
    _initAndNavigate();
  }

  Future<void> _initAndNavigate() async {
    try {
      // Giảm thời gian chờ splash xuống còn 1 giây
      await Future.delayed(const Duration(milliseconds: 800));
      await _navigateToNextScreen();
    } catch (e) {
      print('⚠️ Lỗi trong splash: $e');
      // Đảm bảo luôn navigate đến auth nếu có lỗi
      Get.offAllNamed(Routes.auth);
    }
  }

  Future<void> _navigateToNextScreen() async {
    // Khôi phục phiên đăng nhập từ token (nếu có)
    // Thêm timeout để tránh treo app nếu server không phản hồi
    try {
      await AuthService.instance.loadCurrentUser()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('⚠️ Timeout khi khôi phục phiên đăng nhập');
      });
    } catch (e) {
      // Nếu token không hợp lệ hoặc đã hết hạn, loadCurrentUser sẽ set _currentUser = null
      print('⚠️ Không thể khôi phục phiên đăng nhập: $e');
    }
    
    // Kiểm tra xem đã đăng nhập và có dữ liệu chưa
    bool hasData = false;
    if (AuthService.instance.isLogin) {
      try {
        hasData = await AuthService.instance.isHasData()
            .timeout(const Duration(seconds: 10), onTimeout: () => false);
      } catch (e) {
        print('⚠️ Lỗi kiểm tra dữ liệu: $e');
        hasData = false;
      }
    }
    
    if (AuthService.instance.isLogin && hasData) {
      // KHÔNG clear dữ liệu khi đăng nhập lại - dữ liệu sẽ được filter theo userID
      try {
        await DataService.instance.loadUserData();
        
        // Load dữ liệu ban đầu trước khi vào home screen
        await _loadInitialData();
        
        // Bắt đầu lắng nghe real-time streams sau khi đăng nhập thành công
        DataService.instance.startListeningToStreams();
        DataService.instance.startListeningToUserCollections();
      } catch (e) {
        print('⚠️ Lỗi load dữ liệu: $e');
      }
      
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
