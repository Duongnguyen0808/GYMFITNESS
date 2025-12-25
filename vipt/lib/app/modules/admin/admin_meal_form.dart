import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/providers/meal_category_provider_api.dart';
import 'package:vipt/app/data/providers/ingredient_provider_api.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/ingredient.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';
import 'package:vipt/app/core/values/asset_strings.dart';

class AdminMealForm extends StatefulWidget {
  final Meal? meal;

  const AdminMealForm({Key? key, this.meal}) : super(key: key);

  @override
  State<AdminMealForm> createState() => _AdminMealFormState();
}

class _AdminMealFormState extends State<AdminMealForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _assetController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _stepsController = TextEditingController();
  final _provider = MealProvider();
  final _categoryProvider = MealCategoryProvider();
  final _ingredientProvider = IngredientProvider();
  final _storageService = CloudinaryService.instance;
  final _imagePicker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingData = true;
  XFile? _selectedImageFile;
  String? _imageUrl;
  Uint8List? _imageBytes;

  // Data for dropdowns
  List<Category> _categories = [];
  List<Ingredient> _ingredients = [];

  // Selected values
  List<String> _selectedCategoryIds = [];
  List<IngredientEntry> _ingredientEntries = [];

  @override
  void initState() {
    super.initState();
    if (widget.meal != null) {
      _nameController.text = widget.meal!.name;
      _assetController.text = widget.meal!.asset;
      _cookTimeController.text = widget.meal!.cookTime.toString();
      _stepsController.text = widget.meal!.steps.join('\n');
      _selectedCategoryIds = List.from(widget.meal!.categoryIDs);
      _ingredientEntries = widget.meal!.ingreIDToAmount.entries
          .map((e) => IngredientEntry(ingredientId: e.key, amount: e.value))
          .toList();
      _imageUrl = widget.meal!.asset.isNotEmpty ? widget.meal!.asset : null;
    }
    // Delay loading dropdown data until navigation animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDropdownData();
    });
  }

  Future<void> _loadDropdownData() async {
    try {
      final allCategories = await _categoryProvider.fetchAll();
      final allIngredients = await _ingredientProvider.fetchAll();

      // Loại bỏ duplicate category IDs (giữ lại category đầu tiên nếu có trùng)
      final seenCategoryIds = <String>{};
      _categories = allCategories.where((cat) {
        if (seenCategoryIds.contains(cat.id)) {
          return false;
        }
        seenCategoryIds.add(cat.id!);
        return true;
      }).toList();

      // Loại bỏ duplicate ingredient IDs (giữ lại ingredient đầu tiên nếu có trùng)
      final seenIngredientIds = <String>{};
      _ingredients = allIngredients.where((ing) {
        if (seenIngredientIds.contains(ing.id)) {
          return false;
        }
        seenIngredientIds.add(ing.id!);
        return true;
      }).toList();

      // Sau khi load xong, xóa các entries không hợp lệ
      _removeInvalidIngredientEntries();
      _removeInvalidCategoryIds();

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
    }
  }

  /// Xóa các ingredient entries có ID không tồn tại trong danh sách ingredients
  void _removeInvalidIngredientEntries() {
    if (_ingredients.isEmpty || _ingredientEntries.isEmpty) return;

    final validIngredientIds = _ingredients.map((ing) => ing.id).toSet();
    final removedCount = _ingredientEntries.length;

    _ingredientEntries.removeWhere((entry) {
      return entry.ingredientId.isEmpty ||
          !validIngredientIds.contains(entry.ingredientId);
    });

    final removed = removedCount - _ingredientEntries.length;

    if (removed > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa $removed nguyên liệu không tồn tại khỏi món ăn này.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Xóa các category IDs không tồn tại trong danh sách categories
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
            'Đã xóa $removed danh mục không tồn tại khỏi món ăn này.',
          ),
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

  @override
  void dispose() {
    _nameController.dispose();
    _assetController.dispose();
    _cookTimeController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredientEntries.add(IngredientEntry(ingredientId: '', amount: ''));
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredientEntries.removeAt(index);
    });
  }

  String _getCategoryName(String id) {
    final cat = _categories.firstWhere(
      (c) => c.id == id,
      orElse: () =>
          Category('', name: 'Unknown', asset: '', parentCategoryID: null),
    );
    return cat.name;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final steps = _stepsController.text
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();

      String assetUrl = '';

      // Upload image if selected
      if (_selectedImageFile != null) {
        final folder = 'meals';
        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          if (!mounted) return;
          assetUrl = await _storageService.uploadImageBytes(bytes, folder);
        } else {
          if (!mounted) return;
          assetUrl = await _storageService.uploadImage(
              File(_selectedImageFile!.path), folder);
        }
        if (!mounted) return;
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        // Reject Firebase Storage URLs - require Cloudinary or new upload
        if (_imageUrl!.contains('firebasestorage.googleapis.com')) {
          throw Exception(
              'Ảnh từ Firebase Storage không được hỗ trợ. Vui lòng upload ảnh mới lên Cloudinary.');
        }
        // Only allow Cloudinary URLs
        if (!_imageUrl!.contains('cloudinary.com')) {
          throw Exception(
              'Chỉ hỗ trợ ảnh từ Cloudinary. Vui lòng upload ảnh mới.');
        }
        assetUrl = _imageUrl!;
      } else {
        throw Exception('Vui lòng chọn ảnh cho món ăn');
      }

      // Convert ingredient entries to map
      final ingreMap = <String, String>{};
      for (var entry in _ingredientEntries) {
        if (entry.ingredientId.isNotEmpty && entry.amount.isNotEmpty) {
          ingreMap[entry.ingredientId] = entry.amount;
        }
      }

      final meal = Meal(
        id: widget.meal?.id ?? '',
        name: _nameController.text.trim(),
        asset: assetUrl,
        cookTime: int.parse(_cookTimeController.text),
        ingreIDToAmount: ingreMap,
        steps: steps,
        categoryIDs: _selectedCategoryIds,
      );

      if (widget.meal != null &&
          widget.meal!.id != null &&
          widget.meal!.id!.isNotEmpty) {
        await _provider.update(widget.meal!.id!, meal);
      } else {
        await _provider.add(meal);
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
        title: Text(widget.meal == null ? 'Thêm món ăn' : 'Sửa món ăn'),
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
                    // ===== IMAGE PREVIEW (FIX #1: BoxFit.contain) =====
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                        child: _selectedImageFile != null && _imageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit
                                      .contain, // Changed from cover to contain
                                  width: double.infinity,
                                ),
                              )
                            : _imageUrl != null && _imageUrl!.isNotEmpty
                                ? (_imageUrl!.contains(
                                        'firebasestorage.googleapis.com')
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          JPGAssetString.meal,
                                          fit: BoxFit
                                              .contain, // Changed from cover to contain
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: _imageUrl!,
                                          fit: BoxFit
                                              .contain, // Changed from cover to contain
                                          width: double.infinity,
                                          placeholder: (context, url) =>
                                              const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                            JPGAssetString.meal,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ))
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

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên món ăn *',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),

                    // Cook time field
                    TextFormField(
                      controller: _cookTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Thời gian nấu (phút) *',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Vui lòng nhập thời gian' : null,
                    ),
                    const SizedBox(height: 16),

                    // Steps field
                    TextFormField(
                      controller: _stepsController,
                      decoration: const InputDecoration(
                        labelText: 'Các bước (mỗi bước một dòng) *',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold),
                        hintText: '1. Bước đầu tiên\n2. Bước thứ hai\n...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Vui lòng nhập các bước' : null,
                    ),
                    const SizedBox(height: 24),

                    // ===== CATEGORIES MULTI-SELECT (FIX #2) =====
                    _buildCategoriesSection(),
                    const SizedBox(height: 24),

                    // ===== INGREDIENTS TABLE (FIX #2) =====
                    _buildIngredientsSection(),
                    const SizedBox(height: 32),

                    // ===== SAVE BUTTON (FIX #3: Add visible text) =====
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
                            : (widget.meal == null
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

  // ===== CATEGORIES MULTI-SELECT WIDGET =====
  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Danh mục món ăn',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
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
                      .where((id) => _categories.any(
                          (c) => c.id == id)) // Chỉ hiển thị categories hợp lệ
                      .map((id) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Chip(
                      label: Text(_getCategoryName(id), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
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
                  // Tạo danh sách items không có duplicate
                  final availableCategories = _categories
                      .where((c) =>
                          c.id != null &&
                          c.id!.isNotEmpty &&
                          !_selectedCategoryIds.contains(c.id))
                      .fold<Map<String, Category>>({}, (map, c) {
                        // Loại bỏ duplicate IDs - chỉ giữ lại category đầu tiên
                        if (!map.containsKey(c.id)) {
                          map[c.id!] = c;
                        }
                        return map;
                      })
                      .values
                      .toList();

                  return DropdownButtonFormField<String>(
                    key: ValueKey(
                        'category_dropdown_${_categories.length}_${_selectedCategoryIds.length}'), // Force rebuild khi thay đổi
                    value: null, // Đảm bảo không có value được set
                    decoration: const InputDecoration(
                      labelText: 'Thêm danh mục',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    hint: Text('Chọn danh mục để thêm', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                    dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
                    items: availableCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
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

  // ===== INGREDIENTS TABLE WIDGET =====
  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Nguyên liệu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade700 : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 3,
                      child: Text('Nguyên liệu',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      flex: 2,
                      child: Text('Số lượng',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 40), // Space for delete button
                  ],
                ),
              ),
              const Divider(height: 1),
              // Ingredient rows
              if (_ingredientEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chưa có nguyên liệu. Nhấn "Thêm" để thêm nguyên liệu.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredientEntries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildIngredientRow(index);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientRow(int index) {
    final entry = _ingredientEntries[index];

    // Kiểm tra xem ingredientId có tồn tại trong _ingredients không
    final isValidIngredientId = entry.ingredientId.isNotEmpty &&
        _ingredients.any((ing) => ing.id == entry.ingredientId);

    // Chỉ set value nếu ingredientId hợp lệ và có trong danh sách
    // (Sau khi _removeInvalidIngredientEntries() chạy, tất cả entries đều hợp lệ)
    final dropdownValue = isValidIngredientId ? entry.ingredientId : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Ingredient dropdown
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: dropdownValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              hint: Text('Chọn nguyên liệu', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
              isExpanded: true,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
              dropdownColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
              selectedItemBuilder: (BuildContext context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return _ingredients.map((ing) => Text(
                  '${ing.name} (${ing.kcal} kcal)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                )).toList();
              },
              items: _ingredients.map((ing) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return DropdownMenuItem(
                  value: ing.id,
                  child: Text(
                    '${ing.name} (${ing.kcal} kcal)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _ingredientEntries[index].ingredientId = value ?? '';
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Amount input
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: entry.amount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                hintText: 'VD: 100g',
              ),
              onChanged: (value) {
                _ingredientEntries[index].amount = value;
              },
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeIngredient(index),
            tooltip: 'Xóa nguyên liệu',
          ),
        ],
      ),
    );
  }
}

// Helper class for ingredient entries
class IngredientEntry {
  String ingredientId;
  String amount;

  IngredientEntry({required this.ingredientId, required this.amount});
}
