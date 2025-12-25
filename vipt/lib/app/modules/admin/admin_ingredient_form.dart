import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/ingredient_provider_api.dart';
import 'package:vipt/app/data/models/ingredient.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';
import 'package:vipt/app/core/values/asset_strings.dart';

class AdminIngredientForm extends StatefulWidget {
  final Ingredient? ingredient;

  const AdminIngredientForm({Key? key, this.ingredient}) : super(key: key);

  @override
  State<AdminIngredientForm> createState() => _AdminIngredientFormState();
}

class _AdminIngredientFormState extends State<AdminIngredientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _kcalController = TextEditingController();
  final _fatController = TextEditingController();
  final _carbsController = TextEditingController();
  final _proteinController = TextEditingController();
  final _provider = IngredientProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.ingredient != null) {
      _nameController.text = widget.ingredient!.name;
      _kcalController.text = widget.ingredient!.kcal.toString();
      _fatController.text = widget.ingredient!.fat.toString();
      _carbsController.text = widget.ingredient!.carbs.toString();
      _proteinController.text = widget.ingredient!.protein.toString();
      _imageUrl = widget.ingredient!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _kcalController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageFile = image;
            _imageBytes = bytes;
            _imageUrl = null;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String? imageUrlToSave;

      // Upload image if selected
      if (_selectedImageFile != null) {
        const folder = 'ingredients';
        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          if (!mounted) return;
          imageUrlToSave =
              await _storageService.uploadImageBytes(bytes, folder);
        } else {
          if (!mounted) return;
          imageUrlToSave = await _storageService.uploadImage(
              File(_selectedImageFile!.path), folder);
        }
        if (!mounted) return;
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        // Reject Firebase Storage URLs - require Cloudinary or new upload
        if (_imageUrl!.contains('firebasestorage.googleapis.com')) {
          throw Exception(
              'Ảnh từ Firebase Storage không được hỗ trợ. Vui lòng upload ảnh mới lên Cloudinary.');
        }
        imageUrlToSave = _imageUrl;
      }

      final ingredient = Ingredient(
        id: widget.ingredient?.id ?? '',
        name: _nameController.text.trim(),
        kcal: num.parse(_kcalController.text),
        fat: num.parse(_fatController.text),
        carbs: num.parse(_carbsController.text),
        protein: num.parse(_proteinController.text),
        imageUrl: imageUrlToSave,
      );

      if (widget.ingredient != null &&
          widget.ingredient!.id != null &&
          widget.ingredient!.id!.isNotEmpty) {
        await _provider.update(widget.ingredient!.id!, ingredient);
      } else {
        await _provider.add(ingredient);
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
        title: Text(
            widget.ingredient == null ? 'Thêm nguyên liệu' : 'Sửa nguyên liệu'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image picker for ingredient
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: _selectedImageFile != null && _imageBytes != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                  onPressed: _pickImage,
                                  tooltip: 'Đổi ảnh',
                                ),
                              ),
                            ),
                          ],
                        )
                      : _imageUrl != null && _imageUrl!.isNotEmpty
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _imageUrl!.contains(
                                          'firebasestorage.googleapis.com')
                                      ? Image.asset(
                                          JPGAssetString.meal,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: _imageUrl!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                          height: double.infinity,
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error,
                                                  size: 48,
                                                  color: Colors.red.shade400),
                                              const SizedBox(height: 8),
                                              Text('Không tải được ảnh',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.red.shade600)),
                                            ],
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.white, size: 20),
                                      onPressed: _pickImage,
                                      tooltip: 'Đổi ảnh',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate,
                                    size: 48, color: Colors.orange.shade400),
                                const SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh nguyên liệu',
                                    style: TextStyle(
                                        color: Colors.orange.shade600)),
                                const SizedBox(height: 4),
                                Text('(Không bắt buộc)',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên nguyên liệu *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kcalController,
                decoration: const InputDecoration(
                  labelText: 'Calories (kcal) *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập calories' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(
                  labelText: 'Fat (g) *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập fat' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(
                  labelText: 'Carbs (g) *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập carbs' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(
                  labelText: 'Protein (g) *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v?.isEmpty ?? true ? 'Vui lòng nhập protein' : null,
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
                      : (widget.ingredient == null
                          ? 'Thêm nguyên liệu'
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
