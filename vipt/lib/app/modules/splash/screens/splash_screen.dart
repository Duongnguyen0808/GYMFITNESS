import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/modules/splash/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({Key? key}) : super(key: key);

  // Controller phải được khởi tạo để chạy logic navigation
  final _controller = Get.find<SplashController>();

  @override
  Widget build(BuildContext context) {
    // Đảm bảo controller được khởi tạo bằng cách sử dụng nó
    // ignore: unused_local_variable
    final _ = _controller;
    
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: double.maxFinite,
      width: double.maxFinite,
      alignment: Alignment.center,
      child: Image.asset(
        GIFAssetString.logoAnimation,
        height: 80,
      ),
    );
  }
}
