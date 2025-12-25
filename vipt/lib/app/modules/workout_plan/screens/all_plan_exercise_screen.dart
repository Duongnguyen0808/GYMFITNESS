import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/values/colors.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/global_widgets/app_bar_icon_button.dart';
import 'package:vipt/app/modules/workout_collection/widgets/exercise_in_collection_tile.dart';
import 'package:vipt/app/modules/workout_plan/workout_plan_controller.dart';

class AllPlanExerciseScreen extends StatelessWidget {
  final List<WorkoutCollection> workoutCollectionList;
  final Function(WorkoutCollection) elementOnPress;
  final DateTime startDate;
  const AllPlanExerciseScreen(
      {Key? key,
      required this.startDate,
      required this.workoutCollectionList,
      required this.elementOnPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.only(top: 48),
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                AppBarIconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  iconData: Icons.close,
                  hero: '',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'DANH SÁCH BÀI LUYỆN TẬP',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              children: _buildCollectionList(
                context,
                startDate: startDate,
                workoutCollectionList: workoutCollectionList,
                elementOnPress: elementOnPress,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _buildCollectionList(context,
      {required DateTime startDate,
      required List<WorkoutCollection> workoutCollectionList,
      required Function(WorkoutCollection) elementOnPress}) {
    List<Widget> results = [];

    // Nhóm collections theo ngày từ controller
    final controller = Get.find<WorkoutPlanController>();
    Map<DateTime, List<WorkoutCollection>> collectionsByDate = {};
    
    // Lấy collections từ controller để có thông tin ngày chính xác
    final allCollections = controller.planExerciseCollection;
    
    // Tạo map từ collection ID sang WorkoutCollection
    final collectionMap = <String, WorkoutCollection>{};
    for (var col in workoutCollectionList) {
      collectionMap[col.id ?? ''] = col;
    }
    
    // Nhóm theo ngày
    for (var planCol in allCollections) {
      final workoutCol = collectionMap[planCol.id ?? ''];
      if (workoutCol != null) {
        final dateKey = DateUtils.dateOnly(planCol.date);
        if (!collectionsByDate.containsKey(dateKey)) {
          collectionsByDate[dateKey] = [];
        }
        collectionsByDate[dateKey]!.add(workoutCol);
      }
    }
    
    // Sắp xếp theo ngày
    final sortedDates = collectionsByDate.keys.toList()..sort();
    
    int dayNumber = 1;
    for (var date in sortedDates) {
      final dayCollections = collectionsByDate[date]!;
      
      // Thêm day indicator
      Widget dayIndicator = Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Divider(
                thickness: 1,
                color: AppColor.textFieldUnderlineColor,
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'NGÀY $dayNumber',
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColor.textColor.withOpacity(
                          AppColor.subTextOpacity,
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Divider(
                thickness: 1,
                color: AppColor.textFieldUnderlineColor,
              ),
            ),
          ],
        ),
      );
      
      results.add(dayIndicator);
      
      // Thêm các collections của ngày đó
      for (int i = 0; i < dayCollections.length; i++) {
        WorkoutCollection collection = dayCollections[i];
        String cateList = DataService.instance.collectionCateList
            .where((item) => collection.categoryIDs.contains(item.id))
            .map((e) => e.name)
            .toString()
            .replaceAll(RegExp(r'\(|\)'), '');

        Widget collectionToWidget = Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExerciseInCollectionTile(
              asset: collection.asset == ''
                  ? JPGAssetString.userWorkoutCollection
                  : collection.asset,
              title: collection.title,
              description: cateList,
              onPressed: () {
                elementOnPress(collection);
              }),
        );

        results.add(collectionToWidget);
      }
      
      dayNumber++;
    }

    return results;
  }
}
