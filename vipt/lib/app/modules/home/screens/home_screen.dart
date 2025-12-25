import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:vipt/app/modules/daily_plan/screens/daily_plan_screen.dart';
import 'package:vipt/app/modules/home/home_controller.dart';
import 'package:vipt/app/modules/library/screens/library_screen.dart';
import 'package:vipt/app/modules/profile/screens/profile_screen.dart';
import 'package:vipt/app/modules/workout_plan/screens/workout_plan_screen.dart';
import 'package:vipt/app/global_widgets/floating_chat_button.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final _controller = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PersistentTabView(
          context,
          controller: _controller.tabController,
          screens: _buildScreens(),
          items: _navBarsItems(context),
          backgroundColor: Colors.white,
          handleAndroidBackButtonPress: true,
          resizeToAvoidBottomInset: true,
          stateManagement: true,
          hideNavigationBarWhenKeyboardAppears: true,
          navBarStyle: NavBarStyle.style9,
        ),
        FloatingChatButton(),
      ],
    );
  }

  List<Widget> _buildScreens() {
    return [
      WorkoutPlanScreen(),
      DailyPlanScreen(),
      LibraryScreen(),
      ProfileScreen(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems(context) {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.home),
        title: ("Lộ trình"),
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.check_box_outlined),
        title: ("Kế hoạch"),
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      // PersistentBottomNavBarItem(
      //   icon: const Icon(Icons.directions_run_rounded),
      //   title: ("Chạy bộ"),
      //   activeColorPrimary: Theme.of(context).primaryColor,
      //   inactiveColorPrimary: CupertinoColors.systemGrey,
      // ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.local_library_outlined),
        title: ("Thư viện"),
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person),
        title: ("Cá nhân"),
        activeColorPrimary: Theme.of(context).primaryColor,
        inactiveColorPrimary: CupertinoColors.systemGrey,
      ),
    ];
  }
}
