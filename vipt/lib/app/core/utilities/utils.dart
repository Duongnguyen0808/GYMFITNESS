import 'package:get/get.dart';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/collection_setting.dart';
import 'package:vipt/app/data/models/vipt_user.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/enums/app_enums.dart';
import 'package:vipt/app/modules/loading/screens/loading_screen.dart';

class WorkoutCollectionUtils {
  static double calculateCalo(
      {required List<Workout> workoutList,
      required CollectionSetting collectionSetting,
      required num bodyWeight}) {
    double caloValue = 0;
    workoutList.map((workout) {
      caloValue += collectionSetting.round *
          ((collectionSetting.exerciseTime / 60) *
              workout.metValue *
              bodyWeight *
              3.5) /
          200;
    }).toList();
    return caloValue;
  }

  static double calculateTime(
      {required CollectionSetting collectionSetting,
      required int workoutListLength}) {
    double timeValue = 0;

    // Kiểm tra restFrequency để tránh chia cho 0
    int restTimeValue = 0;
    if (collectionSetting.restFrequency > 0) {
      restTimeValue = ((workoutListLength % collectionSetting.restFrequency ==
                      0)
                  ? (workoutListLength ~/ collectionSetting.restFrequency) - 1
                  : workoutListLength ~/ collectionSetting.restFrequency) *
              collectionSetting.round +
          collectionSetting.round -
          1;
    }
    // Nếu restFrequency = 0, không có rest time nên restTimeValue = 0

    timeValue = (collectionSetting.round *
                workoutListLength *
                (collectionSetting.exerciseTime +
                    collectionSetting.transitionTime) +
            restTimeValue * collectionSetting.restTime) /
        60;
    return timeValue < 0 ? 0 : timeValue;
  }
}

class SessionUtils {
  static double calculateCaloOneWorkout(
      int time, num metValue, num bodyWeight) {
    double caloValue = ((time / 60) * metValue * bodyWeight * 3.5) / 200;
    return caloValue;
  }
}

class WorkoutPlanUtils {
  static num _calculateBMR(ViPTUser user) {
    WeightUnit weightUnit = user.weightUnit;
    HeightUnit heightUnit = user.heightUnit;

    num weight = weightUnit == WeightUnit.kg
        ? user.currentWeight
        : user.currentWeight * 0.45359237;
    num height = heightUnit == HeightUnit.cm
        ? user.currentHeight
        : user.currentHeight * 0.032808399;

    Gender gender = user.gender;
    int constantValue = gender == Gender.male ? 5 : -161;
    int age = DateTime.now().year - user.dateOfBirth.year;
    if (age <= 0) {
      throw Exception(
          "Invalide Date of Birth (${user.dateOfBirth}) is after now (${DateTime.now()}))");
    }

    return 10 * weight + 6.25 * height - 5 * age + constantValue;
  }

  static num _calculateTDEE(num bmr, ActiveFrequency activeFrequency) {
    num fValue = 0;
    switch (activeFrequency) {
      case ActiveFrequency.notMuch:
        fValue = 1.2;
        break;
      case ActiveFrequency.few:
        fValue = 1.375;
        break;
      case ActiveFrequency.average:
        fValue = 1.55;
        break;
      case ActiveFrequency.much:
        fValue = 1.725;
        break;
      case ActiveFrequency.soMuch:
        fValue = 1.9;
        break;
    }

    return fValue * bmr;
  }

  static num createDailyGoalCalories(ViPTUser user) {
    num dailyGoalCalories = 0;
    num bmr = _calculateBMR(user);
    num tdee = _calculateTDEE(bmr, user.activeFrequency);
    int intensity = AppValue.intensityWeight;

    if (user.currentWeight < user.goalWeight) {
      dailyGoalCalories = tdee + intensity;
    } else if (user.currentWeight > user.goalWeight) {
      dailyGoalCalories = tdee - intensity;
    } else {
      dailyGoalCalories = tdee;
    }
    return dailyGoalCalories;
  }

  /// Tính mục tiêu tiêu hao calories hàng ngày dựa trên thông tin user
  /// Công thức: Dựa trên BMR, mức độ hoạt động và mục tiêu cân nặng
  static int calculateDailyOuttakeGoal(ViPTUser user) {
    if (user.currentWeight == 0 || user.goalWeight == 0) {
      return AppValue.intensityWeight; // Mặc định 500
    }

    num bmr = _calculateBMR(user);
    num tdee = _calculateTDEE(bmr, user.activeFrequency);

    // Mục tiêu tiêu hao = phần calories cần đốt để đạt mục tiêu
    // Nếu muốn giảm cân: cần đốt nhiều hơn
    // Nếu muốn tăng cân: cần đốt ít hơn để dư calories
    // Nếu giữ cân: đốt vừa đủ

    int outtakeGoal;
    num weightDiff = user.goalWeight - user.currentWeight;

    if (weightDiff < 0) {
      // Muốn giảm cân - cần đốt nhiều hơn (20-30% TDEE)
      outtakeGoal = (tdee * 0.25).toInt();
    } else if (weightDiff > 0) {
      // Muốn tăng cân - đốt ít hơn (10-15% TDEE)
      outtakeGoal = (tdee * 0.12).toInt();
    } else {
      // Giữ cân - đốt trung bình (15-20% TDEE)
      outtakeGoal = (tdee * 0.18).toInt();
    }

    // Đảm bảo mục tiêu tối thiểu 150 và tối đa 800 calories
    outtakeGoal = outtakeGoal.clamp(150, 800);

    return outtakeGoal;
  }
}

class Converter {
  static double convertCmToFt(double data) {
    return data / 30.48;
  }

  static double convertFtToCm(double data) {
    return data * 30.48;
  }

  static double convertKgToLbs(double data) {
    return data / 0.45359237;
  }

  static double convertLbsToKg(double data) {
    return data * 0.45359237;
  }
}

class UIUtils {
  static Future<void> showLoadingDialog() async {
    return await Get.dialog(const LoadingScreen());
  }

  static void hideLoadingDialog() {
    Get.back();
  }
}
