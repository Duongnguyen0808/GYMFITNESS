import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_provider_api.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/plan_meal_collection.dart';
import 'package:vipt/app/data/models/plan_meal.dart';

class AdminMealPlanMealForm extends StatefulWidget {
  final PlanMealCollection? collection;

  const AdminMealPlanMealForm({Key? key, this.collection}) : super(key: key);

  @override
  State<AdminMealPlanMealForm> createState() => _AdminMealPlanMealFormState();
}

class _AdminMealPlanMealFormState extends State<AdminMealPlanMealForm> {
  final _formKey = GlobalKey<FormState>();
  final _mealRatioController = TextEditingController();

  final _mealProvider = MealProvider();
  final _collectionProvider = PlanMealCollectionProvider();
  final _planMealProvider = PlanMealProvider();

  bool _isLoading = false;
  DateTime? _selectedDate;
  List<Meal> _meals = [];
  List<String> _selectedMealIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _selectedDate = widget.collection!.date;
      _mealRatioController.text = widget.collection!.mealRatio.toString();
      _loadCollectionData();
    } else {
      _selectedDate = DateTime.now();
      _mealRatioController.text = '1.0';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadCollectionData() async {
    if (widget.collection == null || widget.collection!.id == null || widget.collection!.id!.isEmpty) return;

    try {
      final planMeals =
          await _planMealProvider.fetchByListID(widget.collection!.id!);
      _selectedMealIds = planMeals.map((e) => e.mealID).toList();

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải dữ liệu: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      final allMeals = await _mealProvider.fetchAll();

      final seenMealIds = <String>{};
      _meals = allMeals.where((m) {
        if (seenMealIds.contains(m.id)) {
          return false;
        }
        seenMealIds.add(m.id ?? '');
        return true;
      }).toList();

      _removeInvalidMealIds();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi tải dữ liệu: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeInvalidMealIds() {
    if (_meals.isEmpty || _selectedMealIds.isEmpty) return;

    final validMealIds = _meals.map((m) => m.id).toSet();
    final removedCount = _selectedMealIds.length;

    _selectedMealIds.removeWhere((id) {
      return id.isEmpty || !validMealIds.contains(id);
    });

    final removed = removedCount - _selectedMealIds.length;

    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa $removed món ăn không tồn tại.'),
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
    _mealRatioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng chọn ngày'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_selectedMealIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vui lòng chọn ít nhất một món ăn'),
                backgroundColor: Colors.red),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final mealRatio = double.parse(_mealRatioController.text);

      PlanMealCollection collection;

      // Sử dụng method mới để tạo/update cùng lúc với meals
      if (widget.collection != null &&
          widget.collection!.id != null &&
          widget.collection!.id!.isNotEmpty) {
        // Update existing collection
        collection = await _collectionProvider.updateWithMeals(
          id: widget.collection!.id!,
          date: _selectedDate!,
          planID: 0,
          mealRatio: mealRatio,
          mealIDs: _selectedMealIds,
        );
      } else {
        // Create new collection
        collection = await _collectionProvider.createWithMeals(
          date: _selectedDate!,
          planID: 0,
          mealRatio: mealRatio,
          mealIDs: _selectedMealIds,
        );
      }

      if (collection.id == null || collection.id!.isEmpty) {
        throw Exception('Không thể tạo/cập nhật collection. Vui lòng thử lại.');
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
        title: Text(
            widget.collection == null ? 'Thêm món ăn cho ngày' : 'Sửa món ăn'),
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
              TextFormField(
                controller: _mealRatioController,
                decoration: const InputDecoration(
                  labelText: 'Tỷ lệ món ăn *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: '1.0',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập tỷ lệ';
                  if (double.tryParse(v) == null)
                    return 'Vui lòng nhập số hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildMealsSection(),
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
                          ? 'Thêm món ăn'
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

  Widget _buildMealsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.restaurant, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Món ăn',
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
              if (_selectedMealIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMealIds
                      .where((id) => _meals.any((m) => m.id == id))
                      .map((id) {
                    final meal = _meals.firstWhere((m) => m.id == id);
                    return Chip(
                      label: Text(meal.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87)),
                      deleteIcon: Icon(Icons.close,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black54),
                      onDeleted: () {
                        setState(() {
                          _selectedMealIds.remove(id);
                        });
                      },
                      backgroundColor: isDark
                          ? Colors.orange.shade800.withOpacity(0.6)
                          : Colors.orange.shade100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              Builder(
                builder: (context) {
                  final availableMeals = _meals
                      .where((m) =>
                          m.id != null &&
                          m.id!.isNotEmpty &&
                          !_selectedMealIds.contains(m.id))
                      .fold<Map<String, Meal>>({}, (map, m) {
                        if (!map.containsKey(m.id)) {
                          map[m.id!] = m;
                        }
                        return map;
                      })
                      .values
                      .toList();

                  return DropdownButtonFormField<String>(
                    key: ValueKey(
                        'meal_dropdown_${_meals.length}_${_selectedMealIds.length}'),
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Thêm món ăn',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Chọn món ăn để thêm',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600)),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600),
                    dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                    items: availableMeals
                        .map((m) => DropdownMenuItem(
                              value: m.id,
                              child: Text(m.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                            ))
                        .toList(),
                    onChanged: availableMeals.isEmpty
                        ? null
                        : (value) {
                            if (value != null &&
                                !_selectedMealIds.contains(value) &&
                                availableMeals.any((m) => m.id == value)) {
                              setState(() {
                                _selectedMealIds.add(value);
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
