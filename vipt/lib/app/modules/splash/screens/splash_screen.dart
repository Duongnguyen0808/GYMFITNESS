import 'package:flutter/material.dart';
import 'package:vipt/app/core/values/asset_strings.dart';

class SplashScreen extends StatelessWidget {
  SplashScreen({Key? key}) : super(key: key);

  // Controller is initialized via binding, accessed where needed
  // final _controller = Get.find<SplashController>();

  @override
  Widget build(BuildContext context) {
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
