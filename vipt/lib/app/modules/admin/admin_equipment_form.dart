import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/workout_equipment_provider_api.dart';
import 'package:vipt/app/data/models/workout_equipment.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';

class AdminEquipmentForm extends StatefulWidget {
  final WorkoutEquipment? equipment;

  const AdminEquipmentForm({Key? key, this.equipment}) : super(key: key);

  @override
  State<AdminEquipmentForm> createState() => _AdminEquipmentFormState();
}

class _AdminEquipmentFormState extends State<AdminEquipmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _imageLinkController = TextEditingController();
  final _provider = WorkoutEquipmentProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _nameController.text = widget.equipment!.name;
      _imageLinkController.text = widget.equipment!.imageLink;
      _imageUrl = widget.equipment!.imageLink.isNotEmpty ? widget.equipment!.imageLink : null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
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
          SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageLinkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      String imageLink = '';
      
      // Upload image if selected
      if (_selectedImageFile != null) {
        final folder = 'equipment';
        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          if (!mounted) return;
          imageLink = await _storageService.uploadImageBytes(bytes, folder);
        } else {
          if (!mounted) return;
          imageLink = await _storageService.uploadImage(File(_selectedImageFile!.path), folder);
        }
        if (!mounted) return;
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        imageLink = _imageUrl!;
      } else {
        throw Exception('Vui lòng chọn ảnh cho thiết bị');
      }

      final equipment = WorkoutEquipment(
        widget.equipment?.id,
        name: _nameController.text.trim(),
        imageLink: imageLink,
      );

      if (widget.equipment != null && widget.equipment!.id != null && widget.equipment!.id!.isNotEmpty) {
        await _provider.update(widget.equipment!.id!, equipment);
      } else {
        await _provider.add(equipment);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lưu thành công!'), backgroundColor: Colors.green),
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
        title: Text(widget.equipment == null ? 'Thêm thiết bị' : 'Sửa thiết bị'),
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
                          child: Image.memory(_imageBytes!, fit: BoxFit.contain, width: double.infinity),
                        )
                      : _imageUrl != null && _imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text('Nhấn để chọn ảnh', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thiết bị *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  _isLoading 
                      ? 'Đang lưu...' 
                      : (widget.equipment == null ? 'Thêm thiết bị' : 'Lưu thay đổi'),
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

