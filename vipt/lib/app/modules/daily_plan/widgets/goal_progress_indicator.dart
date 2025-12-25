import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:vipt/app/core/values/colors.dart';

class GoalProgressIndicator extends StatelessWidget {
  final int value;
  final String unitString;
  final double radius;
  final int? goalValue;
  const GoalProgressIndicator(
      {Key? key,
      required this.value,
      required this.unitString,
      this.radius = 134,
      this.goalValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double progress = goalValue == null ? 1 : value / goalValue!;

    return CircularPercentIndicator(
      percent: progress > 1 || progress < 0 ? 1 : progress,
      radius: radius,
      lineWidth: 6,
      backgroundColor:
          AppColor.accentTextColor.withOpacity(AppColor.subTextOpacity),
      progressColor: goalValue == null
          ? AppColor.normalColor
          : value >= goalValue!
              ? AppColor.goodColor  // Đạt hoặc vượt mục tiêu: màu xanh
              : value < goalValue! - 100
                  ? AppColor.normalColor
                  : AppColor.goodColor,  // Gần mục tiêu: màu xanh
      center: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: '$value',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: AppColor.accentTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (goalValue != null) TextSpan(text: '/$goalValue'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unitString,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: AppColor.accentTextColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
