import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/library_section_provider_api.dart';
import 'package:vipt/app/data/models/library_section.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';
import 'package:vipt/app/routes/pages.dart';

/// Custom painter để vẽ viền nét đứt
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 8,
    this.dashSpace = 4,
    this.borderRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    final path = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = dashWidth;
        path.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AdminLibrarySectionForm extends StatefulWidget {
  final LibrarySection? section;

  const AdminLibrarySectionForm({Key? key, this.section}) : super(key: key);

  @override
  State<AdminLibrarySectionForm> createState() =>
      _AdminLibrarySectionFormState();
}

class _AdminLibrarySectionFormState extends State<AdminLibrarySectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _routeController = TextEditingController();
  final _orderController = TextEditingController();
  final _provider = LibrarySectionProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingData = true;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;
  bool _isActive = true;

  // Danh sách các route hoạt động cho Library Section
  // Chỉ giữ lại 3 route đã test hoạt động
  static final List<Map<String, String>> _availableRoutes = [
    {'name': '📋 Danh mục bài tập', 'route': Routes.workoutCategory},
    {
      'name': '📂 Danh mục bộ luyện tập',
      'route': Routes.workoutCollectionCategory
    },
    {'name': '🍽️ Danh mục món ăn', 'route': Routes.dishCategory},
  ];
  String? _selectedRoute;

  @override
  void initState() {
    super.initState();
    if (widget.section != null) {
      _titleController.text = widget.section!.title;
      _descriptionController.text = widget.section!.description;
      _routeController.text = widget.section!.route;
      _orderController.text = widget.section!.order.toString();
      _isActive = widget.section!.isActive;
      _imageUrl =
          widget.section!.asset.isNotEmpty ? widget.section!.asset : null;
      // Chỉ set _selectedRoute nếu route tồn tại trong danh sách
      final existingRoute = widget.section!.route;
      final routeExists =
          _availableRoutes.any((r) => r['route'] == existingRoute);
      _selectedRoute = routeExists ? existingRoute : null;
    } else {
      _orderController.text = '0';
    }
    setState(() => _isLoadingData = false);
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
    _routeController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  // Xóa ảnh đã chọn
  void _clearImage() {
    setState(() {
      _selectedImageFile = null;
      _imageBytes = null;
      _imageUrl = null;
    });
  }

  // Kiểm tra có ảnh hay không
  bool get _hasImage => _imageUrl != null || _imageBytes != null;

  // Widget chọn ảnh
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            const Text(
              'Ảnh đại diện',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Image container
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: _hasImage ? null : Colors.grey.shade50,
              border: Border.all(
                color: _hasImage ? Colors.grey.shade300 : Colors.grey.shade400,
                width: _hasImage ? 1 : 2,
                style: _hasImage ? BorderStyle.solid : BorderStyle.none,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _hasImage ? _buildImagePreview() : _buildImagePlaceholder(),
          ),
        ),

        // Action buttons
        if (_hasImage) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Đổi ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _clearImage,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Xóa ảnh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],

        // Helper text
        const SizedBox(height: 8),
        Text(
          'Nhấn vào vùng trên để chọn ảnh. Định dạng: JPG, PNG, GIF.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Widget preview ảnh đã chọn
  Widget _buildImagePreview() {
    return Stack(
      children: [
        // Ảnh
        ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: double.infinity,
            height: 200,
            child: _imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: _imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.red, size: 48),
                    ),
                  )
                : kIsWeb
                    ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                    : Image.file(
                        File(_selectedImageFile!.path),
                        fit: BoxFit.cover,
                      ),
          ),
        ),

        // Overlay hover
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Nhấn để đổi ảnh',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Badge trạng thái
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _imageUrl != null ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _imageUrl != null ? Icons.cloud_done : Icons.cloud_upload,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  _imageUrl != null ? 'Đã lưu' : 'Chưa upload',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget placeholder khi chưa có ảnh
  Widget _buildImagePlaceholder() {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: Colors.grey.shade400,
        strokeWidth: 2,
        dashWidth: 8,
        dashSpace: 4,
        borderRadius: 12,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nhấn để chọn ảnh',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'hoặc kéo thả ảnh vào đây',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _imageUrl;

      // Upload ảnh mới nếu có
      if (_selectedImageFile != null && _imageBytes != null) {
        final extension = _selectedImageFile!.name.split('.').last;
        finalImageUrl = await _storageService.uploadImageBytes(
          _imageBytes!,
          'library_sections',
          extension,
        );
      }

      final order = int.tryParse(_orderController.text) ?? 0;
      final route = _selectedRoute ?? '';

      final section = LibrarySection(
        widget.section?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        asset: finalImageUrl ?? '',
        route: route,
        order: order,
        isActive: _isActive,
      );

      if (widget.section == null) {
        await _provider.add(section);
      } else {
        await _provider.update(widget.section!.id!, section);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.section == null
                ? 'Đã thêm thành công'
                : 'Đã cập nhật thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section == null
            ? 'Thêm phần Thư viện'
            : 'Chỉnh sửa phần Thư viện'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview and picker
              _buildImagePicker(),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Bài tập',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(),
                  hintText:
                      'Ví dụ: Tra cứu thông tin chi tiết của một bài tập cụ thể',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Route dropdown - chọn màn hình điều hướng
              DropdownButtonFormField<String>(
                value: _selectedRoute,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Màn hình điều hướng *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(),
                  helperText:
                      'Chọn màn hình sẽ mở khi người dùng nhấn vào mục này',
                ),
                selectedItemBuilder: (BuildContext context) {
                  return _availableRoutes.map((route) => Text(
                    route['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  )).toList();
                },
                items: _availableRoutes.map((route) {
                  return DropdownMenuItem(
                    value: route['route'],
                    child: Text(route['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoute = value;
                    if (value != null) {
                      _routeController.text = value;
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn màn hình điều hướng';
                  }
                  return null;
                },
              ),

              // Hiển thị route đã chọn (chỉ đọc)
              if (_selectedRoute != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Route: $_selectedRoute',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Order
              TextFormField(
                controller: _orderController,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự hiển thị *',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập thứ tự';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Vui lòng nhập số hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Is Active
              SwitchListTile(
                title: const Text('Kích hoạt'),
                subtitle: const Text('Hiển thị phần này trong Thư viện'),
                value: _isActive,
                onChanged: (value) {
                  setState(() => _isActive = value);
                },
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text(
                        'Lưu',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
