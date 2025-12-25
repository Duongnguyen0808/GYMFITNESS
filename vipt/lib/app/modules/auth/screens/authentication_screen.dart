import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:page_view_indicators/circle_page_indicator.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/modules/auth/screens/email_authentication_screen.dart';

class AuthenticationScreen extends StatelessWidget {
  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);

  AuthenticationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          PageView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            onPageChanged: (index) {
              _currentPageNotifier.value = index;
            },
            controller: _pageController,
            children: [
              // Build phần giới thiệu - trang 1
              // actionOnPress là hàm sẽ chạy khi ấn nút "Bắt đầu"
              _buildIntroduction(
                context,
                actionOnPressed: _nextPage,
              ),

              // Build phần các nút ấn để xác thực tài khoản - trang 2
              _buildAuthentication(
                context,
                authWithEmailFunc: _authWithEmail,
              ),
            ],
          ),
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CirclePageIndicator(
                itemCount: 2,
                currentPageNotifier: _currentPageNotifier,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _authWithEmail() {
    Get.to(() => const EmailAuthenticationScreen());
  }
}

// ********************** PHẦN BUILD CÁC THÀNH PHẦN **********************

// Hàm build phần giới thiệu
Widget _buildIntroduction(context, {required Function() actionOnPressed}) {
  return Container(
    padding: AppDecoration.screenPadding,
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              PNGAssetString.logo,
              height: 25,
            ),
            const SizedBox(
              width: 12,
            ),
            Text(
              'Xin chào, tôi là '.tr,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'ViPT'.tr,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor),
            ),
          ],
        ),
        Expanded(
          child: Image.asset(
            GIFAssetString.introduction,
            fit: BoxFit.fitHeight,
          ),
        ),
        Text(
          'Hãy cùng nhau luyện tập nào!'.tr,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          'Tôi sẽ giúp bạn có thể đạt được các mục tiêu thông qua lộ trình cụ thể.'
              .tr,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: 20,
        ),
        Container(
          color: Colors.transparent,
          width: double.maxFinite,
          height: 46,
          child: ElevatedButton(
            onPressed: actionOnPressed,
            child: Text('Bắt đầu'.tr,
                style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
        const SizedBox(
          height: 18,
        ),
      ],
    ),
  );
}

// Hàm build phần xác thực
Widget _buildAuthentication(context,
    {required Function() authWithEmailFunc}) {
  return Container(
    padding: AppDecoration.screenPadding,
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              PNGAssetString.logo,
              height: 25,
            ),
          ],
        ),
        Expanded(
          child: Image.asset(
            GIFAssetString.introduction_2,
            fit: BoxFit.fitHeight,
          ),
        ),
        Text(
          'Trước hết hãy đăng nhập tài khoản!'.tr,
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          'Việc đăng nhập này sẽ giúp lưu lại tiến trình tập luyện và dinh dưỡng của bạn.'
              .tr,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(
          height: 20,
        ),
        _buildSignInWithEmailButton(
          context,
          onPressed: authWithEmailFunc,
        ),
        const SizedBox(
          height: 18,
        ),
      ],
    ),
  );
}

// Hàm build nút truy cập với Email
Widget _buildSignInWithEmailButton(context, {required Function() onPressed}) {
  return Container(
    color: Colors.transparent,
    width: double.maxFinite,
    height: 40,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColor.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Icon(
              Icons.email_outlined,
              color: AppColor.buttonForegroundColor,
              size: 20,
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              'Truy cập bằng Email'.tr,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  fontSize: 14, color: AppColor.buttonForegroundColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}
