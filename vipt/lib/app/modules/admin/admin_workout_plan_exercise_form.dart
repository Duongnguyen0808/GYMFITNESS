import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/providers/plan_exercise_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_exercise_provider_api.dart';
import 'package:vipt/app/data/providers/plan_exercise_collection_setting_provider_api.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/plan_exercise_collection.dart';
import 'package:vipt/app/data/models/plan_exercise.dart';
import 'package:vipt/app/data/models/plan_exercise_collection_setting.dart';

class AdminWorkoutPlanExerciseForm extends StatefulWidget {
  final PlanExerciseCollection? collection;

  const AdminWorkoutPlanExerciseForm({Key? key, this.collection})
      : super(key: key);

  @override
  State<AdminWorkoutPlanExerciseForm> createState() =>
      _AdminWorkoutPlanExerciseFormState();
}

class _AdminWorkoutPlanExerciseFormState
    extends State<AdminWorkoutPlanExerciseForm> {
  final _formKey = GlobalKey<FormState>();
  final _roundController = TextEditingController();
  final _exerciseTimeController = TextEditingController();
  final _numOfWorkoutController = TextEditingController();

  final _workoutProvider = WorkoutProvider();
  final _collectionProvider = PlanExerciseCollectionProvider();
  final _exerciseProvider = PlanExerciseProvider();
  final _settingProvider = PlanExerciseCollectionSettingProvider();

  bool _isLoading = false;
  DateTime? _selectedDate;
  List<Workout> _workouts = [];
  List<String> _selectedExerciseIds = [];
  PlanExerciseCollectionSetting? _currentSetting;

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _selectedDate = widget.collection!.date;
      _loadCollectionData();
    } else {
      _selectedDate = DateTime.now();
      _roundController.text = '3';
      _exerciseTimeController.text = '45';
      _numOfWorkoutController.text = '10';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadCollectionData() async {
    if (widget.collection == null || widget.collection!.id == null) return;
    
    try {
      final exercises = await _exerciseProvider.fetchByListID(widget.collection!.id!);
      _selectedExerciseIds = exercises.map((e) => e.exerciseID).toList();
      
      final collectionSettingID = widget.collection!.collectionSettingID;
      if (collectionSettingID.isNotEmpty) {
        final setting = await _settingProvider.fetch(collectionSettingID);
        if (setting != null) {
          _currentSetting = setting;
          _roundController.text = setting.round.toString();
          _exerciseTimeController.text = setting.exerciseTime.toString();
          _numOfWorkoutController.text = setting.numOfWorkoutPerRound.toString();
        }
      }
      
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      final allWorkouts = await _workoutProvider.fetchAll();

      final seenWorkoutIds = <String>{};
      _workouts = allWorkouts.where((w) {
        if (seenWorkoutIds.contains(w.id)) {
          return false;
        }
        seenWorkoutIds.add(w.id!);
        return true;
      }).toList();

      _removeInvalidExerciseIds();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeInvalidExerciseIds() {
    if (_workouts.isEmpty || _selectedExerciseIds.isEmpty) return;

    final validWorkoutIds = _workouts.map((w) => w.id).toSet();
    final removedCount = _selectedExerciseIds.length;

    _selectedExerciseIds.removeWhere((id) {
      return id.isEmpty || !validWorkoutIds.contains(id);
    });

    final removed = removedCount - _selectedExerciseIds.length;

    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa $removed bài tập không tồn tại.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _roundController.dispose();
    _exerciseTimeController.dispose();
    _numOfWorkoutController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedExerciseIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ít nhất một bài tập'), backgroundColor: Colors.red),
        );
        return;
      }

      PlanExerciseCollectionSetting setting;
      if (_currentSetting != null && widget.collection != null && _currentSetting!.id != null && _currentSetting!.id!.isNotEmpty) {
        setting = PlanExerciseCollectionSetting(
          id: _currentSetting!.id,
          round: int.parse(_roundController.text),
          exerciseTime: int.parse(_exerciseTimeController.text),
          numOfWorkoutPerRound: int.parse(_numOfWorkoutController.text),
        );
        await _settingProvider.update(_currentSetting!.id!, setting);
      } else {
        setting = PlanExerciseCollectionSetting(
          round: int.parse(_roundController.text),
          exerciseTime: int.parse(_exerciseTimeController.text),
          numOfWorkoutPerRound: int.parse(_numOfWorkoutController.text),
        );
        setting = await _settingProvider.add(setting);
        if (setting.id == null || setting.id!.isEmpty) {
          throw Exception('Không thể tạo setting. Vui lòng thử lại.');
        }
      }

      final settingID = setting.id;
      if (settingID == null || settingID.isEmpty) {
        throw Exception('Setting ID không hợp lệ');
      }

      PlanExerciseCollection collection;
      if (widget.collection != null && widget.collection!.id != null && widget.collection!.id!.isNotEmpty) {
        collection = PlanExerciseCollection(
          id: widget.collection!.id,
          planID: 0,
          date: _selectedDate!,
          collectionSettingID: settingID,
        );
        await _collectionProvider.update(widget.collection!.id!, collection);
        
        final existingExercises = await _exerciseProvider.fetchByListID(widget.collection!.id!);
        for (var exercise in existingExercises) {
          if (exercise.id != null && exercise.id!.isNotEmpty) {
            await _exerciseProvider.delete(exercise.id!);
          }
        }
      } else {
        collection = PlanExerciseCollection(
          planID: 0,
          date: _selectedDate!,
          collectionSettingID: settingID,
        );
        collection = await _collectionProvider.add(collection);
        if (collection.id == null || collection.id!.isEmpty) {
          throw Exception('Không thể tạo collection. Vui lòng thử lại.');
        }
      }

      final collectionID = collection.id;
      if (collectionID == null || collectionID.isEmpty) {
        throw Exception('Collection ID không hợp lệ');
      }

      for (var exerciseId in _selectedExerciseIds) {
        if (exerciseId.isNotEmpty) {
          final exercise = PlanExercise(
            exerciseID: exerciseId,
            listID: collectionID,
          );
          await _exerciseProvider.add(exercise);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection == null
            ? 'Thêm bài tập cho ngày'
            : 'Sửa bài tập'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Chọn ngày',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roundController,
                      decoration: const InputDecoration(
                        labelText: 'Số hiệp *',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        hintText: '3',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập số hiệp';
                        if (int.tryParse(v) == null) return 'Vui lòng nhập số hợp lệ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _exerciseTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian (giây) *',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        hintText: '45',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Vui lòng nhập thời gian';
                        if (int.tryParse(v) == null) return 'Vui lòng nhập số hợp lệ';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _numOfWorkoutController,
                decoration: const InputDecoration(
                  labelText: 'Số bài tập mỗi hiệp *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: '10',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập số bài tập';
                  if (int.tryParse(v) == null) return 'Vui lòng nhập số hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildExercisesSection(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isLoading
                      ? 'Đang lưu...'
                      : (widget.collection == null
                          ? 'Thêm bài tập'
                          : 'Lưu thay đổi'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Bài tập',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedExerciseIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedExerciseIds
                      .where((id) => _workouts.any((w) => w.id == id))
                      .map((id) {
                    final workout = _workouts.firstWhere((w) => w.id == id);
                    return Chip(
                      label: Text(workout.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87)),
                      deleteIcon: Icon(Icons.close,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black54),
                      onDeleted: () {
                        setState(() {
                          _selectedExerciseIds.remove(id);
                        });
                      },
                      backgroundColor: isDark
                          ? Colors.purple.shade800.withOpacity(0.6)
                          : Colors.purple.shade100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Builder(
                builder: (context) {
                  final availableWorkouts = _workouts
                      .where((w) =>
                          w.id != null &&
                          w.id!.isNotEmpty &&
                          !_selectedExerciseIds.contains(w.id))
                      .fold<Map<String, Workout>>({}, (map, w) {
                        if (!map.containsKey(w.id)) {
                          map[w.id!] = w;
                        }
                        return map;
                      })
                      .values
                      .toList();

                  return DropdownButtonFormField<String>(
                    key: ValueKey(
                        'exercise_dropdown_${_workouts.length}_${_selectedExerciseIds.length}'),
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Thêm bài tập',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Chọn bài tập để thêm',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600)),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600),
                    dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                    items: availableWorkouts
                        .map((w) => DropdownMenuItem(
                              value: w.id,
                              child: Text(w.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                            ))
                        .toList(),
                    onChanged: availableWorkouts.isEmpty
                        ? null
                        : (value) {
                            if (value != null &&
                                !_selectedExerciseIds.contains(value) &&
                                availableWorkouts.any((w) => w.id == value)) {
                              setState(() {
                                _selectedExerciseIds.add(value);
                              });
                            }
                          },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
