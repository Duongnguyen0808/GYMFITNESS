import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/modules/profile/widgets/custom_tile.dart';
import 'package:vipt/app/modules/workout/workout_controller.dart';
import 'package:vipt/app/routes/pages.dart';

class ExerciseListScreen extends StatelessWidget {
  ExerciseListScreen({Key? key}) : super(key: key);

  final _controller = Get.find<WorkoutController>();
  final Category cate = Get.arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: const Hero(
            tag: 'leadingButtonAppBar',
            child: Icon(Icons.arrow_back_ios_new_rounded),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Hero(
          tag: 'titleAppBar',
          child: Text(
            cate.name,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _controller.refreshWorkoutData();
          // Reload workouts for current category after refresh
          _controller.reloadWorkoutsForCategory(cate);
        },
        child: Obx(() => ListView.separated(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            itemBuilder: (_, index) {
              var workout = _controller.workouts[index];

              return CustomTile(
                type: 2,
                asset: workout.thumbnail,
                onPressed: () {
                  // Truyền workout ID thay vì object để màn hình detail fetch dữ liệu mới
                  Get.toNamed(Routes.exerciseDetail, arguments: workout.id);
                },
                title: workout.name,
              );
            },
            separatorBuilder: (_, index) => const Divider(
                  indent: 24,
                ),
            itemCount: _controller.workouts.length)),
      ),
    );
  }
}
