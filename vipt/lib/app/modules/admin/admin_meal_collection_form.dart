import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/models/meal_collection.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';

class AdminMealCollectionForm extends StatefulWidget {
  final MealCollection? collection;

  const AdminMealCollectionForm({Key? key, this.collection}) : super(key: key);

  @override
  State<AdminMealCollectionForm> createState() =>
      _AdminMealCollectionFormState();
}

class _AdminMealCollectionFormState extends State<AdminMealCollectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();
  final _assetController = TextEditingController();
  final _dateToMealIdController = TextEditingController();

  final _provider = MealCollectionProvider();
  final _mealProvider = MealProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;

  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    if (widget.collection != null) {
      _titleController.text = widget.collection!.title;
      _descriptionController.text = widget.collection!.description;
      _noteController.text = widget.collection!.note;
      _assetController.text = widget.collection!.asset;
      _dateToMealIdController.text = widget.collection!.dateToMealID.entries
          .map((e) => '${e.key}:${e.value.join(',')}')
          .join('; ');
      _imageUrl =
          widget.collection!.asset.isNotEmpty ? widget.collection!.asset : null;
    }
    // Delay loading dropdown data until navigation animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      _meals = await _mealProvider.fetchAll();
      setState(() {});
    } catch (e) {
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
    _noteController.dispose();
    _assetController.dispose();
    _dateToMealIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String assetUrl = '';

      // Upload image if selected
      if (_selectedImageFile != null) {
        final folder = 'meal_collections';
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
        throw Exception('Vui lòng chọn ảnh cho bộ dinh dưỡng');
      }

      // Parse dateToMealID: format "date1:meal1,meal2; date2:meal3,meal4"
      final dateToMealID = <String, List<String>>{};
      final entries = _dateToMealIdController.text.split(';');
      for (var entry in entries) {
        final parts = entry.trim().split(':');
        if (parts.length == 2) {
          final date = parts[0].trim();
          final mealIds = parts[1]
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (date.isNotEmpty && mealIds.isNotEmpty) {
            dateToMealID[date] = mealIds;
          }
        }
      }

      final collection = MealCollection(
        id: widget.collection?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        note: _noteController.text.trim(),
        asset: assetUrl,
        dateToMealID: dateToMealID,
      );

      if (widget.collection != null &&
          widget.collection!.id != null &&
          widget.collection!.id!.isNotEmpty) {
        await _provider.update(widget.collection!.id!, collection);
      } else {
        await _provider.add(collection);
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
        title: Text(widget.collection == null
            ? 'Thêm bộ dinh dưỡng'
            : 'Sửa bộ dinh dưỡng'),
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
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
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
                  hintText: 'Mô tả về bộ dinh dưỡng này',
                ),
                maxLines: 4,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập mô tả' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: 'Các ghi chú bổ sung',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateToMealIdController,
                decoration: const InputDecoration(
                  labelText: 'Lịch ăn (format: ngày:meal1,meal2; ngày:meal3)',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  hintText: 'Ví dụ: 1:meal1,meal2; 2:meal3,meal4',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              if (_meals.isNotEmpty) ...[
                const Text('Danh sách món ăn:',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _meals.map((meal) {
                    return Chip(
                      label: Text(meal.name),
                      avatar: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(meal.name[0].toUpperCase()),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
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
                          ? 'Thêm bộ dinh dưỡng'
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
