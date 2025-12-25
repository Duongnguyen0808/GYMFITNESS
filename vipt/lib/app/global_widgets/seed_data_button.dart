import 'package:flutter/material.dart';
import 'package:vipt/app/data/helpers/fake_data_helper.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:get/get.dart';
import 'package:vipt/app/modules/nutrition/nutrition_controller.dart';
import 'package:vipt/app/modules/workout/workout_controller.dart';
import 'package:vipt/app/modules/workout_collection/workout_collection_controller.dart';

/// Widget button để seed fake data
/// Thêm widget này vào màn hình Setting hoặc Admin panel
class SeedDataButton extends StatefulWidget {
  const SeedDataButton({Key? key}) : super(key: key);

  @override
  State<SeedDataButton> createState() => _SeedDataButtonState();
}

class _SeedDataButtonState extends State<SeedDataButton> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _seedData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // Kiểm tra xem đã seed chưa
      final isSeeded = await FakeDataHelper.isDataSeeded();

      if (isSeeded) {
        // Hiển thị dialog xác nhận
        final shouldReseed = await _showConfirmDialog();
        if (!shouldReseed) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Cancelled';
          });
          return;
        }
      }

      // Seed data
      await FakeDataHelper.seedAllData(force: isSeeded);

      // Reload DataService để lấy dữ liệu mới từ Firebase
      await DataService.instance.reloadAllData();

      // Refresh controllers nếu đang được sử dụng
      if (Get.isRegistered<NutritionController>()) {
        final nutritionController = Get.find<NutritionController>();
        nutritionController.initMealTree();
        nutritionController.initMealCategories();
      }

      if (Get.isRegistered<WorkoutController>()) {
        final workoutController = Get.find<WorkoutController>();
        workoutController.initWorkoutTree();
        workoutController.initWorkoutCategories();
        workoutController.initWorkoutList();
      }

      if (Get.isRegistered<WorkoutCollectionController>()) {
        final collectionController = Get.find<WorkoutCollectionController>();
        collectionController.initWorkoutCollectionTree();
        collectionController.loadCollectionCategories();
      }

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Data seeded successfully!';
      });

      // Hiển thị snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Fake data seeded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error seeding data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Reseed'),
            content: const Text(
              'Data has already been seeded. Do you want to seed again?\n\n'
              'Warning: This will add duplicate data!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reseed'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _resetSeedFlag() async {
    await FakeDataHelper.resetSeedFlag();
    setState(() {
      _statusMessage = '🔄 Seed flag reset';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seed flag reset. You can seed data again.'),
        ),
      );
    }
  }

  Future<void> _fixCategoryIds() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang fix category IDs...';
    });

    try {
      final result = await FakeDataHelper.fixAllMealCategoryIds();
      
      if (result['success'] == true) {
        // Reload DataService để lấy dữ liệu mới
        await DataService.instance.reloadAllData();
        
        // Refresh controllers
        if (Get.isRegistered<NutritionController>()) {
          final nutritionController = Get.find<NutritionController>();
          nutritionController.initMealTree();
          nutritionController.initMealCategories();
        }
        
        setState(() {
          _isLoading = false;
          _statusMessage = '✅ Fixed ${result['updated']} meals! (Skipped: ${result['skipped']}, Errors: ${result['errors']})';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Fixed ${result['updated']} meals!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = '❌ Error: ${result['error']}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Error: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    // Hiển thị dialog xác nhận
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa TẤT CẢ dữ liệu fake đã seed?\n\n'
              'Hành động này KHÔNG THỂ HOÀN TÁC!\n\n'
              'Dữ liệu sẽ bị xóa:\n'
              '• Meal Categories\n'
              '• Ingredients\n'
              '• Meals\n'
              '• Meal Collections\n'
              '• Workout Categories\n'
              '• Workout Equipment',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('XÓA TẤT CẢ'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang xóa dữ liệu...';
    });

    try {
      await FakeDataHelper.deleteAllSeededData();

      // Reload DataService để xóa cache
      await DataService.instance.reloadAllData();

      // Refresh controllers nếu đang được sử dụng
      if (Get.isRegistered<NutritionController>()) {
        final nutritionController = Get.find<NutritionController>();
        nutritionController.initMealTree();
        nutritionController.initMealCategories();
      }

      if (Get.isRegistered<WorkoutController>()) {
        final workoutController = Get.find<WorkoutController>();
        workoutController.initWorkoutTree();
        workoutController.initWorkoutCategories();
        workoutController.initWorkoutList();
      }

      if (Get.isRegistered<WorkoutCollectionController>()) {
        final collectionController = Get.find<WorkoutCollectionController>();
        collectionController.initWorkoutCollectionTree();
        collectionController.loadCollectionCategories();
      }

      setState(() {
        _isLoading = false;
        _statusMessage = '✅ Đã xóa tất cả dữ liệu!';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã xóa tất cả dữ liệu fake!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = '❌ Lỗi: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi xóa dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _seedData,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cloud_upload),
          label: Text(_isLoading ? 'Seeding...' : 'Seed Fake Data'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isLoading ? null : _resetSeedFlag,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset Seed Flag'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _fixCategoryIds,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.build, color: Colors.white),
          label: Text(_isLoading ? 'Fixing...' : '🔧 Fix Category IDs'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _isLoading ? null : _deleteAllData,
          icon: const Icon(Icons.delete_forever, size: 16),
          label: const Text('Xóa tất cả dữ liệu'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _statusMessage!,
            style: TextStyle(
              fontSize: 12,
              color: _statusMessage!.startsWith('✅')
                  ? Colors.green
                  : _statusMessage!.startsWith('❌')
                      ? Colors.red
                      : Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
}
