import 'package:vipt/app/data/services/data_service.dart';

class AppStartService {
  AppStartService._privateConstructor();
  static final AppStartService instance = AppStartService._privateConstructor();

  Future<void> initService() async {
    // Khởi tạo DataService với lifecycle observer
    // Firebase đã được gỡ bỏ, chuyển sang MongoDB backend
    DataService.instance.initialize();
  }
}
