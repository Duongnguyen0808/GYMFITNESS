import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/data/services/auth_service.dart';
import 'package:vipt/app/modules/admin/admin_manage_screen.dart';
import 'package:vipt/app/routes/pages.dart';

class AdminScreenSimple extends StatefulWidget {
  const AdminScreenSimple({Key? key}) : super(key: key);

  @override
  State<AdminScreenSimple> createState() => _AdminScreenSimpleState();
}

class _AdminScreenSimpleState extends State<AdminScreenSimple> {
  @override
  void initState() {
    super.initState();
    // Check if user is already signed in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (!AuthService.instance.isLogin) {
          Get.offAllNamed(Routes.adminLogin);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not authenticated, show loading
    if (!AuthService.instance.isLogin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show management screen
    return const AdminManageScreen();
  }
}
