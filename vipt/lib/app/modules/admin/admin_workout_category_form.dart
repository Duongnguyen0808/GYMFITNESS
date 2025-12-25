import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/workout_category_provider_api.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';

class AdminWorkoutCategoryForm extends StatefulWidget {
  final Category? category;

  const AdminWorkoutCategoryForm({Key? key, this.category}) : super(key: key);

  @override
  State<AdminWorkoutCategoryForm> createState() =>
      _AdminWorkoutCategoryFormState();
}

class _AdminWorkoutCategoryFormState extends State<AdminWorkoutCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _assetController = TextEditingController();
  final _provider = WorkoutCategoryProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingData = true;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;

  List<Category> _categories = [];
  String? _selectedParentCategoryId;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _assetController.text = widget.category!.asset;
      _selectedParentCategoryId = widget.category!.parentCategoryID;
      _imageUrl =
          widget.category!.asset.isNotEmpty ? widget.category!.asset : null;
    }
    // Delay loading dropdown data until navigation animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      final allCategories = await _provider.fetchAll();

      // Loại bỏ duplicate IDs và category hiện tại (nếu đang edit)
      final seenIds = <String>{};
      _categories = allCategories.where((cat) {
        if (seenIds.contains(cat.id)) {
          return false;
        }
        // Không cho phép chọn chính nó làm parent
        if (widget.category != null && cat.id == widget.category!.id) {
          return false;
        }
        seenIds.add(cat.id!);
        return true;
      }).toList();

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
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
    _nameController.dispose();
    _assetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String assetUrl = '';

      // Upload image if selected
      if (_selectedImageFile != null) {
        final folder = 'workout_categories';
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
        throw Exception('Vui lòng chọn ảnh cho danh mục bài tập');
      }

      final category = Category(
        widget.category?.id,
        name: _nameController.text.trim(),
        asset: assetUrl,
        parentCategoryID: _selectedParentCategoryId,
      );

      if (widget.category != null &&
          widget.category!.id != null &&
          widget.category!.id!.isNotEmpty) {
        await _provider.update(widget.category!.id!, category);
      } else {
        await _provider.add(category);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null
            ? 'Thêm danh mục bài tập'
            : 'Sửa danh mục bài tập'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _selectedImageFile != null && _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_imageBytes!,
                                    fit: BoxFit.contain,
                                    width: double.infinity),
                              )
                            : _imageUrl != null && _imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: _imageUrl!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (context, url) =>
                                          const Center(
                                              child:
                                                  CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 48,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text('Nhấn để chọn ảnh',
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục *',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedParentCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục cha (tùy chọn)',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                        hintText:
                            'Chọn danh mục cha hoặc để trống nếu là danh mục gốc',
                      ),
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          const Text('(Không có - danh mục gốc)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ..._categories.map((cat) => Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          )),
                        ];
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('(Không có - danh mục gốc)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedParentCategoryId = value;
                        });
                      },
                    ),
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
                            : (widget.category == null
                                ? 'Thêm danh mục'
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
}
