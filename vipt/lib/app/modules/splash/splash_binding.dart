import 'package:get/get.dart';
import 'package:vipt/app/modules/splash/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Dùng put thay vì lazyPut để đảm bảo controller được khởi tạo ngay
    Get.put<SplashController>(SplashController());
  }
}
