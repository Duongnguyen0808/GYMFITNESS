import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vipt/app/data/providers/plan_meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/plan_meal_provider_api.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/models/plan_meal_collection.dart';
import 'package:vipt/app/data/models/plan_meal.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/core/controllers/theme_controller.dart';
import 'admin_meal_plan_meal_form.dart';

class AdminMealPlanManage extends StatefulWidget {
  const AdminMealPlanManage({Key? key}) : super(key: key);

  @override
  State<AdminMealPlanManage> createState() => _AdminMealPlanManageState();
}

class _AdminMealPlanManageState extends State<AdminMealPlanManage> {
  final PlanMealCollectionProvider _collectionProvider =
      PlanMealCollectionProvider();
  final PlanMealProvider _mealProvider = PlanMealProvider();
  final MealProvider _mealDetailProvider = MealProvider();

  List<PlanMealCollection> _collections = [];
  Map<String, List<PlanMeal>> _collectionMeals = {};
  Map<String, Meal> _meals = {};
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
      await _loadMeals();
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

  Future<void> _loadMeals() async {
    try {
      final meals = await _mealDetailProvider.fetchAll();
      _meals = {for (var m in meals) m.id ?? '': m};
    } catch (e) {
      _meals = {};
    }
  }

  Future<void> _loadDefaultCollections() async {
    try {
      final allCollections = await _collectionProvider.fetchAll();
      _collections = allCollections.where((c) => c.planID == 0).toList();
      _collections.sort((a, b) => a.date.compareTo(b.date));

      _collectionMeals.clear();

      for (var collection in _collections) {
        final collectionId = collection.id;
        if (collectionId != null && collectionId.isNotEmpty) {
          try {
            final meals = await _mealProvider.fetchByListID(collectionId);
            _collectionMeals[collectionId] = meals.isNotEmpty ? meals : <PlanMeal>[];
          } catch (e) {
            // Nếu có lỗi, gán danh sách rỗng
            _collectionMeals[collectionId] = <PlanMeal>[];
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải danh sách món ăn: $e', isError: true);
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

  Future<void> _deleteCollection(PlanMealCollection collection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa danh sách món ăn cho ngày ${_formatDate(collection.date)}?'),
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
          final meals = _collectionMeals[collection.id!] ?? [];
          for (var meal in meals) {
            if (meal.id != null && meal.id!.isNotEmpty) {
              await _mealProvider.delete(meal.id!);
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

  void _showMealDetails(
      PlanMealCollection collection, List<PlanMeal> meals) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết món ăn - ${_formatDate(collection.date)}'),
        content: SizedBox(
          width: double.maxFinite,
          child: meals.isEmpty
              ? const Text('Chưa có món ăn nào')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final planMeal = meals[index];
                    final meal = _meals[planMeal.mealID];

                    return ListTile(
                      leading: meal?.asset.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                meal!.asset,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.restaurant);
                                },
                              ),
                            )
                          : const Icon(Icons.restaurant),
                      title: Text(meal?.name ?? 'Món ăn ${index + 1}'),
                      subtitle: meal != null
                          ? Text('Thời gian nấu: ${meal.cookTime} phút')
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
                          '${_collections.length} danh sách món ăn',
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
                                    const AdminMealPlanMealForm(),
                              ),
                            );
                            if (result == true) {
                              await _loadDefaultCollections();
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm món ăn'),
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
                                  Icon(Icons.restaurant,
                                      size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có danh sách món ăn nào',
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
                                final meals = (collection.id != null && collection.id!.isNotEmpty)
                                    ? (_collectionMeals[collection.id!] ?? <PlanMeal>[])
                                    : <PlanMeal>[];

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
                                      child: meals.isNotEmpty &&
                                              meals.first.mealID.isNotEmpty &&
                                              _meals.containsKey(meals.first.mealID) &&
                                              _meals[meals.first.mealID]?.asset.isNotEmpty == true
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                _meals[meals.first.mealID]!.asset,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context,
                                                    error, stackTrace) {
                                                  return Icon(
                                                    Icons.restaurant,
                                                    color: Colors
                                                        .grey.shade600,
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              Icons.restaurant,
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
                                      '${meals.length} món ăn',
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
                                                    AdminMealPlanMealForm(
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
                                          onPressed: collection.id != null &&
                                                  collection.id!.isNotEmpty
                                              ? () =>
                                                  _deleteCollection(collection)
                                              : null,
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.visibility,
                                              size: 20),
                                          color: Colors.grey.shade600,
                                          onPressed: () {
                                            _showMealDetails(
                                                collection, meals);
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

