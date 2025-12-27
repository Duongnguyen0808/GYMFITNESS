import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/utilities/utils.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/others/tab_refesh_controller.dart';
import 'package:vipt/app/data/providers/exercise_nutrition_route_provider.dart';
import 'package:vipt/app/data/providers/user_provider_api.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/global_widgets/custom_confirmation_dialog.dart';
import 'package:vipt/app/modules/workout_plan/widgets/input_dialog.dart';
import 'package:vipt/app/routes/pages.dart';

class SettingController extends GetxController {
  @override
  Future<void> onInit() async {
    await DataService.instance.loadUserData();
    super.onInit();
  }

  Future<void> changeBasicInforamtion() async {
    await showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return CustomConfirmationDialog(
          label: 'Bạn thực sự muốn thay đổi thông tin ban đầu?',
          content:
              'Tiến trình hiện tại sẽ bị thiết lập lại từ đầu và sẽ không được lưu lại',
          labelCancel: 'Hủy bỏ',
          labelOk: 'Xác nhận',
          onCancel: () {
            Navigator.of(context).pop();
          },
          onOk: () async {
            await Get.toNamed(Routes.setupInfoQuestion);
            Get.back();
          },
          buttonsAlignment: MainAxisAlignment.spaceEvenly,
        );
      },
    );
  }

  Future<void> changeWeightGoal() async {
    await showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return CustomConfirmationDialog(
          label: 'Bạn thực sự muốn thay đổi mục tiêu cân nặng?',
          content:
              'Tiến trình hiện tại sẽ bị thiết lập lại từ đầu và sẽ không được lưu lại',
          labelCancel: 'Hủy bỏ',
          labelOk: 'Xác nhận',
          onCancel: () {
            Navigator.of(context).pop();
          },
          onOk: () async {
            Get.back();
            await _showInputWeightDialog();
          },
          buttonsAlignment: MainAxisAlignment.spaceEvenly,
        );
      },
    );
  }

  Future<void> updateWeightGoal(String goalWeightStr) async {
    UIUtils.showLoadingDialog();
    int? newWeight = int.tryParse(goalWeightStr);
    if (newWeight == null) {
      await showDialog(
        context: Get.context!,
        builder: (BuildContext context) {
          return CustomConfirmationDialog(
            icon: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Icon(Icons.error_rounded,
                  color: AppColor.errorColor, size: 48),
            ),
            label: 'Đã xảy ra lỗi',
            content: 'Giá trị cân nặng không đúng định dạng',
            showOkButton: false,
            labelCancel: 'Đóng',
            onCancel: () {
              Navigator.of(context).pop();
            },
            buttonsAlignment: MainAxisAlignment.center,
            buttonFactorOnMaxWidth: double.infinity,
          );
        },
      );
      return;
    }

    final _userInfo = DataService.currentUser;
    if (_userInfo != null) {
      _userInfo.goalWeight = newWeight;
      await UserProvider().update(_userInfo.id ?? '', _userInfo);

      await DataService.instance.loadUserData();
      
      // Sử dụng recommendation API để tạo lại lộ trình
      try {
        final apiService = ApiService.instance;
        
        // Generate plan recommendation với mục tiêu mới
        final recommendation = await apiService.generatePlanRecommendation();
        
        // Create plan from recommendation
        await apiService.createPlanFromRecommendation(
          planLengthInDays: recommendation['planLengthInDays'] as int,
          dailyGoalCalories: recommendation['dailyGoalCalories'] as num,
          dailyIntakeCalories: recommendation['dailyIntakeCalories'] as num,
          dailyOuttakeCalories: recommendation['dailyOuttakeCalories'] as num,
          recommendedExerciseIDs: (recommendation['recommendedExerciseIDs'] as List)
              .map((e) => e.toString())
              .toList(),
          recommendedMealIDs: (recommendation['recommendedMealIDs'] as List)
              .map((e) => e.toString())
              .toList(),
          startDate: recommendation['startDate'] != null 
              ? DateTime.parse(recommendation['startDate'])
              : DateTime.now(),
          endDate: recommendation['endDate'] != null
              ? DateTime.parse(recommendation['endDate'])
              : null,
        );
      } catch (e) {
        print('❌ Lỗi khi tạo lại lộ trình từ recommendation: $e');
        // Fallback về phương thức cũ nếu recommendation API fail
        await ExerciseNutritionRouteProvider().resetRoute();
      }
    }

    _markRelevantTabToUpdate();
    UIUtils.hideLoadingDialog();

    Get.offAllNamed(Routes.home);
  }

  void _markRelevantTabToUpdate() {
    if (!RefeshTabController.instance.isProfileTabNeedToUpdate) {
      RefeshTabController.instance.toggleProfileTabUpdate();
    }
  }

  Future<void> _showInputWeightDialog() async {
    return await showDialog(
        context: Get.context!,
        builder: (_) {
          return InputDialog(
              title: 'Nhập mục tiêu cân nặng',
              weightEditingController: TextEditingController(
                  text: DataService.currentUser!.goalWeight.toString()),
              logWeight: updateWeightGoal);
        });
  }

  Future<void> viewRecommendation() async {
    await Get.toNamed(Routes.recommendationPreview);
  }
}
