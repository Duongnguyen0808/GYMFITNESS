import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/theme/app_theme.dart';

class ThemeController extends GetxController {
  var isDarkMode = Get.isDarkMode.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = Get.isDarkMode;
  }

  void toggleTheme() {
    // Update reactive variable first for instant UI update
    isDarkMode.value = !isDarkMode.value;
    final newThemeMode = isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
    
    // Change theme synchronously
    Get.changeThemeMode(newThemeMode);
    Get.changeTheme(isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme);
    
    // Notify all listeners immediately
    update();
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}

