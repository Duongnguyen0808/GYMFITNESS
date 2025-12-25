import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/workout_collection_provider_api.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/providers/workout_collection_category_provider_api.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';

class AdminWorkoutCollectionForm extends StatefulWidget {
  final WorkoutCollection? collection;

  const AdminWorkoutCollectionForm({Key? key, this.collection})
      : super(key: key);

  @override
  State<AdminWorkoutCollectionForm> createState() =>
      _AdminWorkoutCollectionFormState();
}

class _AdminWorkoutCollectionFormState
    extends State<AdminWorkoutCollectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assetController = TextEditingController();
  final _generatorIdsController = TextEditingController();
  final _categoryIdsController = TextEditingController();

  final _provider = WorkoutCollectionProvider();
  final _workoutProvider = WorkoutProvider();
  final _categoryProvider = WorkoutCollectionCategoryProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;

  List<Workout> _workouts = [];
  List<Category> _categories = [];
  List<String> _selectedGeneratorIds = [];
  List<String> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _titleController.text = widget.collection!.title;
      _descriptionController.text = widget.collection!.description;
      _assetController.text = widget.collection!.asset;
      _imageUrl =
          widget.collection!.asset.isNotEmpty ? widget.collection!.asset : null;
      _selectedGeneratorIds = List.from(widget.collection!.generatorIDs);
      _selectedCategoryIds = List.from(widget.collection!.categoryIDs);
    }
    // Delay loading dropdown data until navigation animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      final allWorkouts = await _workoutProvider.fetchAll();
      final allCategories = await _categoryProvider.fetchAll();

      // Loại bỏ duplicate workout IDs
      final seenWorkoutIds = <String>{};
      _workouts = allWorkouts.where((w) {
        if (seenWorkoutIds.contains(w.id)) {
          return false;
        }
        seenWorkoutIds.add(w.id!);
        return true;
      }).toList();

      // Loại bỏ duplicate category IDs
      final seenCategoryIds = <String>{};
      _categories = allCategories.where((c) {
        if (seenCategoryIds.contains(c.id)) {
          return false;
        }
        seenCategoryIds.add(c.id!);
        return true;
      }).toList();

      // Xóa các IDs không hợp lệ
      _removeInvalidGeneratorIds();
      _removeInvalidCategoryIds();

      setState(() {});
    } catch (e) {
    }
  }

  /// Xóa các generator IDs không tồn tại
  void _removeInvalidGeneratorIds() {
    if (_workouts.isEmpty || _selectedGeneratorIds.isEmpty) return;

    final validWorkoutIds = _workouts.map((w) => w.id).toSet();
    final removedCount = _selectedGeneratorIds.length;

    _selectedGeneratorIds.removeWhere((id) {
      return id.isEmpty || !validWorkoutIds.contains(id);
    });

    final removed = removedCount - _selectedGeneratorIds.length;

    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã xóa $removed bài tập không tồn tại khỏi bộ luyện tập này.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Xóa các category IDs không tồn tại
  void _removeInvalidCategoryIds() {
    if (_categories.isEmpty || _selectedCategoryIds.isEmpty) return;

    final validCategoryIds = _categories.map((c) => c.id).toSet();
    final removedCount = _selectedCategoryIds.length;

    _selectedCategoryIds.removeWhere((id) {
      return id.isEmpty || !validCategoryIds.contains(id);
    });

    final removed = removedCount - _selectedCategoryIds.length;

    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Đã xóa $removed danh mục không tồn tại khỏi bộ luyện tập này.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _imageBytes = bytes;
          _imageUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assetController.dispose();
    _generatorIdsController.dispose();
    _categoryIdsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String assetUrl = '';

      // Upload image if selected
      if (_selectedImageFile != null) {
        final folder = 'workout_collections';
        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          assetUrl = await _storageService.uploadImageBytes(bytes, folder);
        } else {
          assetUrl = await _storageService.uploadImage(
              File(_selectedImageFile!.path), folder);
        }
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        assetUrl = _imageUrl!;
      } else {
        throw Exception('Vui lòng chọn ảnh cho bộ luyện tập');
      }

      // Sử dụng selected IDs thay vì parse từ text
      final generatorIDs =
          _selectedGeneratorIds.where((id) => id.isNotEmpty).toList();
      final categoryIDs =
          _selectedCategoryIds.where((id) => id.isNotEmpty).toList();

      final collection = WorkoutCollection(
        widget.collection?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        asset: assetUrl,
        generatorIDs: generatorIDs,
        categoryIDs: categoryIDs,
      );

      if (widget.collection != null &&
          widget.collection!.id != null &&
          widget.collection!.id!.isNotEmpty) {
        await _provider.updateDefaultCollection(
            widget.collection!.id!, collection);
      } else {
        await _provider.addDefaultCollection(collection);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Lưu thành công!'), backgroundColor: Colors.green),
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
            ? 'Thêm bộ luyện tập'
            : 'Sửa bộ luyện tập'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Preview and Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade300),
                  ),
                  child: _selectedImageFile != null && _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!,
                              fit: BoxFit.contain, width: double.infinity),
                        )
                      : _imageUrl != null && _imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: 'Mô tả về bộ luyện tập này',
                ),
                maxLines: 4,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 24),
              // ===== WORKOUTS MULTI-SELECT =====
              _buildWorkoutsSection(),
              const SizedBox(height: 24),
              // ===== CATEGORIES MULTI-SELECT =====
              _buildCategoriesSection(),
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
                          ? 'Thêm bộ luyện tập'
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

  // ===== WORKOUTS MULTI-SELECT WIDGET =====
  Widget _buildWorkoutsSection() {
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
              // Selected workouts chips
              if (_selectedGeneratorIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedGeneratorIds
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
                          _selectedGeneratorIds.remove(id);
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
              // Add workout dropdown
              Builder(
                builder: (context) {
                  final availableWorkouts = _workouts
                      .where((w) =>
                          w.id != null &&
                          w.id!.isNotEmpty &&
                          !_selectedGeneratorIds.contains(w.id))
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
                        'workout_dropdown_${_workouts.length}_${_selectedGeneratorIds.length}'),
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
                                !_selectedGeneratorIds.contains(value) &&
                                availableWorkouts.any((w) => w.id == value)) {
                              setState(() {
                                _selectedGeneratorIds.add(value);
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

  // ===== CATEGORIES MULTI-SELECT WIDGET =====
  Widget _buildCategoriesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Danh mục',
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
              // Selected categories chips
              if (_selectedCategoryIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedCategoryIds
                      .where((id) => _categories.any((c) => c.id == id))
                      .map((id) {
                    final cat = _categories.firstWhere((c) => c.id == id);
                    return Chip(
                      label: Text(cat.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87)),
                      deleteIcon: Icon(Icons.close,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.black54),
                      onDeleted: () {
                        setState(() {
                          _selectedCategoryIds.remove(id);
                        });
                      },
                      backgroundColor: isDark
                          ? Colors.blue.shade800.withOpacity(0.6)
                          : Colors.blue.shade100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Add category dropdown
              Builder(
                builder: (context) {
                  final availableCategories = _categories
                      .where((c) =>
                          c.id != null &&
                          c.id!.isNotEmpty &&
                          !_selectedCategoryIds.contains(c.id))
                      .fold<Map<String, Category>>({}, (map, c) {
                        if (!map.containsKey(c.id)) {
                          map[c.id!] = c;
                        }
                        return map;
                      })
                      .values
                      .toList();

                  return DropdownButtonFormField<String>(
                    key: ValueKey(
                        'category_dropdown_${_categories.length}_${_selectedCategoryIds.length}'),
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Thêm danh mục',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Chọn danh mục để thêm',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600)),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600),
                    dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                    items: availableCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87)),
                            ))
                        .toList(),
                    onChanged: availableCategories.isEmpty
                        ? null
                        : (value) {
                            if (value != null &&
                                !_selectedCategoryIds.contains(value) &&
                                availableCategories.any((c) => c.id == value)) {
                              setState(() {
                                _selectedCategoryIds.add(value);
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
