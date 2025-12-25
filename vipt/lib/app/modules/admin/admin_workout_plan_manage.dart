import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vipt/app/data/providers/plan_exercise_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_exercise_provider_api.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/models/plan_exercise_collection.dart';
import 'package:vipt/app/data/models/plan_exercise.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/core/controllers/theme_controller.dart';
import 'admin_workout_plan_exercise_form.dart';

class AdminWorkoutPlanManage extends StatefulWidget {
  const AdminWorkoutPlanManage({Key? key}) : super(key: key);

  @override
  State<AdminWorkoutPlanManage> createState() => _AdminWorkoutPlanManageState();
}

class _AdminWorkoutPlanManageState extends State<AdminWorkoutPlanManage> {
  final PlanExerciseCollectionProvider _collectionProvider =
      PlanExerciseCollectionProvider();
  final PlanExerciseProvider _exerciseProvider = PlanExerciseProvider();
  final WorkoutProvider _workoutProvider = WorkoutProvider();

  List<PlanExerciseCollection> _collections = [];
  Map<String, List<PlanExercise>> _collectionExercises = {};
  Map<String, Workout> _workouts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      await _loadWorkouts();
      await _loadDefaultCollections();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadWorkouts() async {
    try {
      final workouts = await _workoutProvider.fetchAll();
      _workouts = {for (var w in workouts) w.id ?? '': w};
    } catch (e) {
      _workouts = {};
    }
  }

  Future<void> _loadDefaultCollections() async {
    try {
      final allCollections = await _collectionProvider.fetchAll();
      _collections = allCollections.where((c) => c.planID == 0).toList();
      _collections.sort((a, b) => a.date.compareTo(b.date));

      _collectionExercises.clear();

      for (var collection in _collections) {
        if (collection.id != null && collection.id!.isNotEmpty) {
          try {
            final exercises =
                await _exerciseProvider.fetchByListID(collection.id!);
            _collectionExercises[collection.id!] = exercises;
          } catch (e) {
            _collectionExercises[collection.id!] = [];
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải danh sách bài tập: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  Future<void> _deleteCollection(PlanExerciseCollection collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa danh sách bài tập cho ngày ${_formatDate(collection.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (collection.id != null && collection.id!.isNotEmpty) {
          final exercises = _collectionExercises[collection.id!] ?? [];
          for (var exercise in exercises) {
            if (exercise.id != null && exercise.id!.isNotEmpty) {
              await _exerciseProvider.delete(exercise.id!);
            }
          }
          await _collectionProvider.delete(collection.id!);
          await _loadDefaultCollections();
          _showSnackbar('Đã xóa thành công');
        }
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  void _showExerciseDetails(
      PlanExerciseCollection collection, List<PlanExercise> exercises) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết bài tập - ${_formatDate(collection.date)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: exercises.isEmpty
              ? const Text('Chưa có bài tập nào')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final workout = _workouts[exercise.exerciseID];

                    return ListTile(
                      leading: workout?.thumbnail.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                workout!.thumbnail,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.fitness_center);
                                },
                              ),
                            )
                          : const Icon(Icons.fitness_center),
                      title: Text(workout?.name ?? 'Bài tập ${index + 1}'),
                      subtitle: workout != null
                          ? Text('MET: ${workout.metValue}')
                          : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : null;

    return Obx(() {
      final isDark = themeController?.isDarkMode.value ??
          (Theme.of(context).brightness == Brightness.dark);

      return Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_collections.length} danh sách bài tập',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AdminWorkoutPlanExerciseForm(),
                              ),
                            );
                            if (result == true) {
                              await _loadDefaultCollections();
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm bài tập'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadDefaultCollections,
                      child: _collections.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.fitness_center,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có danh sách bài tập nào',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _collections.length,
                              itemBuilder: (context, index) {
                                final collection = _collections[index];
                                final exercises =
                                    _collectionExercises[collection.id] ?? [];

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: isDark ? 4 : 2,
                                  shadowColor: isDark
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    leading: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade300,
                                      ),
                                      child: exercises.isNotEmpty &&
                                              exercises
                                                  .first.exerciseID.isNotEmpty
                                          ? _workouts[exercises
                                                          .first.exerciseID]
                                                      ?.thumbnail
                                                      .isNotEmpty ==
                                                  true
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    _workouts[exercises
                                                            .first.exerciseID]!
                                                        .thumbnail,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        Icons.fitness_center,
                                                        color: Colors
                                                            .grey.shade600,
                                                      );
                                                    },
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.fitness_center,
                                                  color: Colors.grey.shade600,
                                                )
                                          : Icon(
                                              Icons.fitness_center,
                                              color: Colors.grey.shade600,
                                            ),
                                    ),
                                    title: Text(
                                      _formatDate(collection.date),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.grey.shade900,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${exercises.length} bài tập',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit, size: 20),
                                          color: Colors.blue.shade600,
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminWorkoutPlanExerciseForm(
                                                  collection: collection,
                                                ),
                                              ),
                                            );
                                            if (result == true) {
                                              await _loadDefaultCollections();
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          color: Colors.red.shade600,
                                          onPressed: collection.id != null
                                              ? () =>
                                                  _deleteCollection(collection)
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.visibility,
                                              size: 20),
                                          color: Colors.grey.shade600,
                                          onPressed: () {
                                            _showExerciseDetails(
                                                collection, exercises);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      );
    });
  }
}
