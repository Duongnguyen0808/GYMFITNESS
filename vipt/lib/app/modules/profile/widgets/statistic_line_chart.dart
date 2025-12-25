import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:vipt/app/core/values/colors.dart';

class StatisticLineChart extends StatelessWidget {
  final Map<DateTime, double> values;

  final String? title;
  final String? description;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? borderColor;
  final List<Color>? gradient;
  final Function()? onPressHandler;
  final DateTimeRange dateRange;

  final Color? descriptionColor;
  const StatisticLineChart(
      {Key? key,
      required this.values,
      this.foregroundColor,
      this.backgroundColor,
      this.title,
      this.titleColor,
      this.description,
      this.descriptionColor,
      this.borderColor,
      this.gradient,
      this.onPressHandler,
      required this.dateRange})
      : super(key: key);

  // Cache calculations để tránh tính lại mỗi lần build
  double get _maximum {
    if (values.isEmpty) return 1.0;
    final intValues = values.values.toList();
    return (intValues.reduce(max) + 1).toDouble();
  }

  double get _minimum {
    if (values.isEmpty) return 0.0;
    final intValues = values.values.toList();
    return (intValues.reduce(min) - 1).toDouble();
  }

  int get _dateDiff {
    DateTime startDate = DateTime(
        dateRange.start.year, dateRange.start.month, dateRange.start.day);
    DateTime endDate =
        DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);

    if (startDate.compareTo(endDate) == 0) {
      startDate = startDate.subtract(const Duration(days: 1));
    }
    return endDate.difference(startDate).inDays;
  }

  @override
  Widget build(BuildContext context) {
    DateTime startDate = DateTime(
        dateRange.start.year, dateRange.start.month, dateRange.start.day);
    DateTime endDate =
        DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);

    if (startDate.compareTo(endDate) == 0) {
      startDate = startDate.subtract(const Duration(days: 1));
    }

    final dateDiff = _dateDiff;
    final maximum = _maximum;
    final minimum = _minimum;
    final gradientColors =
        gradient ?? AppColor.weightTrackingGradientColors;

    Widget getBotomTitles(double value, TitleMeta meta) {
      TextStyle? style = Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontSize: 14,
          color: foregroundColor ?? AppColor.weightTrackingForegroundColor);
      Widget text;
      String dateFormatStart =
          '${startDate.day}/${startDate.month}/${startDate.year}';
      String dateFormatEnd = '${endDate.day}/${endDate.month}/${endDate.year}';

      if (value.toInt() == 0) {
        text = Text(dateFormatStart, style: style);
      } else if (value.toInt() == dateDiff) {
        text = Text(dateFormatEnd, style: style);
      } else {
        text = Text('', style: style);
      }
      return Padding(padding: const EdgeInsets.only(top: 16), child: text);
    }

    Widget getLeftTitles(double value, TitleMeta meta) {
      TextStyle? style = Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: foregroundColor ?? AppColor.weightTrackingForegroundColor);
      Widget text;
      if (value == maximum ||
          value.toInt() == maximum ~/ 2 ||
          value == minimum) {
        text = Text(value.toStringAsFixed(0), style: style);
        if (value < 0) {
          text = Text(
            '',
            style: style,
          );
        }
      } else {
        text = Text('', style: style);
      }
      return Padding(padding: const EdgeInsets.only(left: 8), child: text);
    }

    List<FlSpot> getFlSpot() {
      List<FlSpot> results = [];

      if (values.isNotEmpty) {
        values.forEach((k, v) {
          try {
            double x = k.difference(startDate).inDays.toDouble();
            double y = v.toDouble();

            results.add(
              FlSpot(x, y),
            );
          } catch (e) {
          }
        });
      } else {
        results.add(const FlSpot(0, 0));
        results.add(FlSpot(endDate.difference(startDate).inDays.toDouble(), 0));
      }
      results.sort((a, b) => a.x.compareTo(b.x));
      return results;
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: backgroundColor ?? AppColor.weightTrackingBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                  color: titleColor ??
                                      AppColor.weightTrackingTitleColor),
                        ),
                      if (title != null)
                        const SizedBox(
                          height: 4,
                        ),
                      if (description != null)
                        Text(
                          description!,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    color: descriptionColor ??
                                        AppColor.weightTrackingDescriptionColor,
                                  ),
                        ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    child: InkWell(
                      onTap: onPressHandler,
                      borderRadius: BorderRadius.circular(5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.date_range_rounded,
                          color: titleColor ??
                              AppColor.weightTrackingDescriptionColor,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 36,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 36,
                  ),
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 38,
                            interval: 1,
                            getTitlesWidget: getBotomTitles,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maximum > 0 ? maximum / 2 : 1,
                            getTitlesWidget: getLeftTitles,
                            reservedSize: 38,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: borderColor ??
                                  AppColor.weightTrackingBorderColor,
                              width: 1)),
                      minX: 0,
                      maxX: _dateDiff.toDouble(),
                      minY: minimum,
                      maxY: maximum,
                      lineTouchData: LineTouchData(
                        enabled: false, // Disable touch để tăng performance
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: getFlSpot(),
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: gradientColors
                                  .map((color) => color.withOpacity(0.3))
                                  .toList(),
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
