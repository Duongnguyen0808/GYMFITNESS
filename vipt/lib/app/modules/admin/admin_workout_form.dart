import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/providers/workout_category_provider_api.dart';
import 'package:vipt/app/data/providers/workout_equipment_provider_api.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/workout_equipment.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';

class AdminWorkoutForm extends StatefulWidget {
  final Workout? workout;

  const AdminWorkoutForm({Key? key, this.workout}) : super(key: key);

  @override
  State<AdminWorkoutForm> createState() => _AdminWorkoutFormState();
}

class _AdminWorkoutFormState extends State<AdminWorkoutForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _animationController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _hintsController = TextEditingController();
  final _breathingController = TextEditingController();
  final _metValueController = TextEditingController();
  final _categoryIdsController = TextEditingController();
  final _equipmentIdsController = TextEditingController();

  final _provider = WorkoutProvider();
  final _categoryProvider = WorkoutCategoryProvider();
  final _equipmentProvider = WorkoutEquipmentProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  XFile? _selectedThumbnailFile;
  XFile? _selectedAnimationFile;
  XFile? _selectedMuscleFocusFile;
  String? _thumbnailUrl;
  String? _animationUrl;
  String? _muscleFocusUrl;
  Uint8List? _thumbnailBytes;
  Uint8List? _animationBytes;
  Uint8List? _muscleFocusBytes;

  List<Category> _categories = [];
  List<WorkoutEquipment> _equipments = [];
  List<String> _selectedCategoryIds = [];
  List<String> _selectedEquipmentIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.workout != null) {
      _nameController.text = widget.workout!.name;
      _animationController.text = widget.workout!.animation;
      _thumbnailController.text = widget.workout!.thumbnail;
      _hintsController.text = widget.workout!.hints;
      _breathingController.text = widget.workout!.breathing;
      _metValueController.text = widget.workout!.metValue.toString();
      _thumbnailUrl = widget.workout!.thumbnail.isNotEmpty
          ? widget.workout!.thumbnail
          : null;
      _animationUrl = widget.workout!.animation.isNotEmpty
          ? widget.workout!.animation
          : null;
      _muscleFocusUrl = widget.workout!.muscleFocusAsset.isNotEmpty
          ? widget.workout!.muscleFocusAsset
          : null;
      _selectedCategoryIds = List.from(widget.workout!.categoryIDs);
      _selectedEquipmentIds = List.from(widget.workout!.equipmentIDs);
    }
    // Delay loading dropdown data until navigation animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      final allCategories = await _categoryProvider.fetchAll();
      final allEquipments = await _equipmentProvider.fetchAll();

      // Loại bỏ duplicate category IDs
      final seenCategoryIds = <String>{};
      _categories = allCategories.where((cat) {
        if (seenCategoryIds.contains(cat.id)) {
          return false;
        }
        seenCategoryIds.add(cat.id!);
        return true;
      }).toList();

      // Loại bỏ duplicate equipment IDs
      final seenEquipmentIds = <String>{};
      _equipments = allEquipments.where((eq) {
        if (seenEquipmentIds.contains(eq.id)) {
          return false;
        }
        seenEquipmentIds.add(eq.id!);
        return true;
      }).toList();

      // Xóa các IDs không hợp lệ
      _removeInvalidCategoryIds();
      _removeInvalidEquipmentIds();

      setState(() {});
    } catch (e) {
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
          content:
              Text('Đã xóa $removed danh mục không tồn tại khỏi bài tập này.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Xóa các equipment IDs không tồn tại
  void _removeInvalidEquipmentIds() {
    if (_equipments.isEmpty || _selectedEquipmentIds.isEmpty) return;

    final validEquipmentIds = _equipments.map((e) => e.id).toSet();
    final removedCount = _selectedEquipmentIds.length;

    _selectedEquipmentIds.removeWhere((id) {
      return id.isEmpty || !validEquipmentIds.contains(id);
    });

    final removed = removedCount - _selectedEquipmentIds.length;

    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Đã xóa $removed thiết bị không tồn tại khỏi bài tập này.'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedThumbnailFile = image;
            _thumbnailBytes = bytes;
            _thumbnailUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAnimation() async {
    try {
      final XFile? file = await _imagePicker.pickMedia();
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedAnimationFile = file;
          _animationBytes = bytes;
          _animationUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi chọn video: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickMuscleFocusImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedMuscleFocusFile = image;
          _muscleFocusBytes = bytes;
          _muscleFocusUrl = null;
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
    _nameController.dispose();
    _animationController.dispose();
    _thumbnailController.dispose();
    _hintsController.dispose();
    _breathingController.dispose();
    _metValueController.dispose();
    _categoryIdsController.dispose();
    _equipmentIdsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String thumbnailUrl = '';
      String animationUrl = '';

      // Upload thumbnail if selected
      if (_selectedThumbnailFile != null) {
        final folder = 'workouts/thumbnails';
        if (kIsWeb) {
          if (!mounted) return;
          thumbnailUrl =
              await _storageService.uploadImageBytes(_thumbnailBytes!, folder);
        } else {
          if (!mounted) return;
          thumbnailUrl = await _storageService.uploadImage(
              File(_selectedThumbnailFile!.path), folder);
        }
        if (!mounted) return;
      } else if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty) {
        thumbnailUrl = _thumbnailUrl!;
      } else {
        throw Exception('Vui lòng chọn ảnh đại diện cho bài tập');
      }

      // Upload animation if selected
      if (_selectedAnimationFile != null) {
        final folder = 'workouts/animations';
        // Detect if file is video based on extension or mime type
        String? fileExtension;
        bool isVideo = false;

        // Try to get extension from name first (works on web)
        if (_selectedAnimationFile!.name.isNotEmpty) {
          final nameParts = _selectedAnimationFile!.name.split('.');
          if (nameParts.length > 1) {
            fileExtension = nameParts.last.toLowerCase();
          }
        }
        // Fallback to path extension (works on mobile)
        if (fileExtension == null && _selectedAnimationFile!.path.isNotEmpty) {
          final pathParts = _selectedAnimationFile!.path.split('.');
          if (pathParts.length > 1) {
            fileExtension = pathParts.last.toLowerCase();
          }
        }

        // Check mime type if available
        if (_selectedAnimationFile!.mimeType != null) {
          isVideo = _selectedAnimationFile!.mimeType!.startsWith('video/');
        } else if (fileExtension != null) {
          // Fallback to extension check
          isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', 'm4v']
              .contains(fileExtension);
        }

        if (kIsWeb) {
          if (!mounted) return;
          if (isVideo) {
            animationUrl = await _storageService.uploadVideoBytes(
                _animationBytes!, folder, fileExtension);
          } else {
            animationUrl = await _storageService.uploadImageBytes(
                _animationBytes!, folder, fileExtension);
          }
        } else {
          if (!mounted) return;
          if (isVideo) {
            animationUrl = await _storageService.uploadVideo(
                File(_selectedAnimationFile!.path), folder);
          } else {
            animationUrl = await _storageService.uploadImage(
                File(_selectedAnimationFile!.path), folder);
          }
        }
        if (!mounted) return;
      } else if (_animationUrl != null && _animationUrl!.isNotEmpty) {
        animationUrl = _animationUrl!;
      } else {
        throw Exception('Vui lòng chọn video/animation cho bài tập');
      }

      // Upload muscle focus image if selected
      String muscleFocusAssetUrl = '';
      if (_selectedMuscleFocusFile != null) {
        final folder = 'workouts/muscle_focus';
        if (kIsWeb) {
          muscleFocusAssetUrl = await _storageService.uploadImageBytes(
              _muscleFocusBytes!, folder);
        } else {
          muscleFocusAssetUrl = await _storageService.uploadImage(
              File(_selectedMuscleFocusFile!.path), folder);
        }
        // Update URL after successful upload
        _muscleFocusUrl = muscleFocusAssetUrl;
      } else if (_muscleFocusUrl != null && _muscleFocusUrl!.isNotEmpty) {
        muscleFocusAssetUrl = _muscleFocusUrl!;
      }

      // Sử dụng selected IDs thay vì parse từ text
      final categoryIDs =
          _selectedCategoryIds.where((id) => id.isNotEmpty).toList();
      final equipmentIDs =
          _selectedEquipmentIds.where((id) => id.isNotEmpty).toList();

      final workout = Workout(
        widget.workout?.id,
        name: _nameController.text.trim(),
        animation: animationUrl,
        thumbnail: thumbnailUrl,
        hints: _hintsController.text.trim(),
        breathing: _breathingController.text.trim(),
        muscleFocusAsset: muscleFocusAssetUrl,
        categoryIDs: categoryIDs,
        metValue: double.tryParse(_metValueController.text) ?? 0.0,
        equipmentIDs: equipmentIDs,
      );

      if (widget.workout != null &&
          widget.workout!.id != null &&
          widget.workout!.id!.isNotEmpty) {
        await _provider.update(widget.workout!.id!, workout);
      } else {
        await _provider.add(workout);
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
        title: Text(widget.workout == null ? 'Thêm bài tập' : 'Sửa bài tập'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thumbnail Preview
              const Text('Ảnh đại diện:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickThumbnail,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: _selectedThumbnailFile != null &&
                          _thumbnailBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_thumbnailBytes!,
                              fit: BoxFit.contain, width: double.infinity),
                        )
                      : _thumbnailUrl != null && _thumbnailUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: _thumbnailUrl!,
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
              const SizedBox(height: 24),

              // Animation/Video Preview
              const Text('Video/Animation:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAnimation,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: _selectedAnimationFile != null &&
                          _animationBytes != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.video_library,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Đã chọn: ${_selectedAnimationFile!.name}',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        )
                      : _animationUrl != null && _animationUrl!.isNotEmpty
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library,
                                    size: 48, color: Colors.blue),
                                const SizedBox(height: 8),
                                Text('Video hiện tại',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.video_library,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Nhấn để chọn video/animation',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tên bài tập *',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hintsController,
                decoration: const InputDecoration(
                  labelText: 'Gợi ý',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: 'Các gợi ý khi thực hiện bài tập',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breathingController,
                decoration: const InputDecoration(
                  labelText: 'Hướng dẫn hít thở',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: 'Cách hít thở khi thực hiện',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Muscle Focus Image Preview
              const Text('Asset hình ảnh nhóm cơ:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickMuscleFocusImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: _selectedMuscleFocusFile != null &&
                          _muscleFocusBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_muscleFocusBytes!,
                              fit: BoxFit.contain, width: double.infinity),
                        )
                      : _muscleFocusUrl != null && _muscleFocusUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: _muscleFocusUrl!,
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
                                Icon(Icons.fitness_center,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh nhóm cơ',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _metValueController,
                decoration: const InputDecoration(
                  labelText: 'Giá trị MET *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: 'Ví dụ: 3.5',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Vui lòng nhập giá trị MET';
                  if (double.tryParse(v!) == null)
                    return 'Giá trị không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // ===== CATEGORIES MULTI-SELECT =====
              _buildCategoriesSection(),
              const SizedBox(height: 24),
              // ===== EQUIPMENT MULTI-SELECT =====
              _buildEquipmentSection(),
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
                      : (widget.workout == null
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
              'Danh mục bài tập',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
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
                      label: Text(cat.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                      deleteIcon: Icon(Icons.close, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                      onDeleted: () {
                        setState(() {
                          _selectedCategoryIds.remove(id);
                        });
                      },
                      backgroundColor: isDark ? Colors.blue.shade800.withOpacity(0.6) : Colors.blue.shade100,
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
                    hint: Text('Chọn danh mục để thêm', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                    items: availableCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
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

  // ===== EQUIPMENT MULTI-SELECT WIDGET =====
  Widget _buildEquipmentSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Thiết bị',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected equipment chips
              if (_selectedEquipmentIds.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedEquipmentIds
                      .where((id) => _equipments.any((e) => e.id == id))
                      .map((id) {
                    final eq = _equipments.firstWhere((e) => e.id == id);
                    return Chip(
                      label: Text(eq.name),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedEquipmentIds.remove(id);
                        });
                      },
                      backgroundColor: Colors.green.shade100,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Add equipment dropdown
              Builder(
                builder: (context) {
                  final availableEquipments = _equipments
                      .where((e) =>
                          e.id != null &&
                          e.id!.isNotEmpty &&
                          !_selectedEquipmentIds.contains(e.id))
                      .fold<Map<String, WorkoutEquipment>>({}, (map, e) {
                        if (!map.containsKey(e.id)) {
                          map[e.id!] = e;
                        }
                        return map;
                      })
                      .values
                      .toList();

                  return DropdownButtonFormField<String>(
                    key: ValueKey(
                        'equipment_dropdown_${_equipments.length}_${_selectedEquipmentIds.length}'),
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Thêm thiết bị',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Chọn thiết bị để thêm', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
                    items: availableEquipments
                        .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                            ))
                        .toList(),
                    onChanged: availableEquipments.isEmpty
                        ? null
                        : (value) {
                            if (value != null &&
                                !_selectedEquipmentIds.contains(value) &&
                                availableEquipments.any((e) => e.id == value)) {
                              setState(() {
                                _selectedEquipmentIds.add(value);
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
