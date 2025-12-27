import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/services/auth_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/routes/pages.dart';

class AuthenticationController extends GetxController {
  Future<void> handleSignInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final dynamic result = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      if (result != null) {
        if (result is! String) {
          _handleSignInSucess(result);
        } else {
          _handleSignInFail(result);
        }
      }
    } catch (e) {
      _handleSignInFail(e.toString());
    }
  }

  Future<void> handleSignUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Chỉ gửi email và password, backend sẽ tự động tạo các giá trị mặc định
      final dynamic result = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        // Các field khác không cần gửi, backend sẽ tự động tạo giá trị mặc định
      );

      if (result != null && result is! String) {
        // Chuyển đến trang nhập OTP để xác thực email
        Get.snackbar(
          'Đăng ký thành công',
          'Vui lòng kiểm tra email để lấy mã xác thực',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColor.secondaryColor.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.toNamed(Routes.otpVerification, arguments: {'email': email});
      } else {
        _handleSignInFail(result?.toString() ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      _handleSignInFail(e.toString());
    }
  }

  Future<bool> _checkUserExistence(String userId) async {
    return await AuthService.instance.checkIfUserExist(userId);
  }

  void _handleSignInSucess(Map<String, dynamic> result) async {
    // result chứa { user: {...}, token: "..." }
    final user = result['user'];
    if (user == null) {
      _handleSignInFail('Không lấy được thông tin user');
      return;
    }

    final userId = user['_id'] ?? user['id'] ?? '';
    if (userId.isEmpty) {
      _handleSignInFail('Không lấy được user ID');
      return;
    }

    // Check if user has profile data
    bool isExist = await _checkUserExistence(userId);
    if (!isExist) {
      Get.offAllNamed(Routes.setupInfoIntro);
    } else {
      await DataService.instance.loadUserData();

      // Bắt đầu lắng nghe real-time streams sau khi đăng nhập thành công
      DataService.instance.startListeningToStreams();
      DataService.instance.startListeningToUserCollections();

      Get.offAllNamed(Routes.home);
    }
  }

  void _handleSignInFail(String message) {
    Get.snackbar(
      'Lỗi đăng nhập',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColor.errorColor.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
