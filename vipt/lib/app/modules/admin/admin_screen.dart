import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/modules/admin/admin_controller.dart';

class AdminScreen extends StatelessWidget {
  AdminScreen({Key? key}) : super(key: key);

  final AdminController _controller = Get.put(AdminController());

  @override
  Widget build(BuildContext context) {
    // Responsive width for web
    double maxWidth = MediaQuery.of(context).size.width > 800 ? 800 : double.infinity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ViPT Admin - Import Dữ liệu mẫu'),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload, size: 48, color: Colors.blue.shade700),
                    const SizedBox(height: 8),
                    Text(
                      'Import Dữ liệu Mẫu',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn loại dữ liệu để import vào Firestore',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Import All Button
            Obx(() {
              bool isAnyLoading = _controller.isLoadingIngredients.value ||
                  _controller.isLoadingMeals.value ||
                  _controller.isLoadingEquipment.value ||
                  _controller.isLoadingCategories.value;

              return ElevatedButton.icon(
                onPressed: isAnyLoading ? null : () => _controller.importAllData(),
                icon: const Icon(Icons.cloud_done, size: 28),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'IMPORT TẤT CẢ DỮ LIỆU',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            
            Text(
              'Hoặc import từng loại:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Individual Import Buttons
            _buildImportCard(
              context: context,
              title: 'Nguyên liệu (Ingredients)',
              description: '~60+ nguyên liệu với thông tin dinh dưỡng',
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              isLoading: _controller.isLoadingIngredients,
              onPressed: () => _controller.importIngredients(),
            ),
            const SizedBox(height: 12),

            _buildImportCard(
              context: context,
              title: 'Món ăn (Meals)',
              description: '15+ công thức món ăn chi tiết',
              icon: Icons.fastfood,
              color: Colors.red,
              isLoading: _controller.isLoadingMeals,
              onPressed: () => _controller.importMeals(),
            ),
            const SizedBox(height: 12),

            _buildImportCard(
              context: context,
              title: 'Thiết bị tập luyện',
              description: '13 loại thiết bị (Dumbbell, Barbell...)',
              icon: Icons.fitness_center,
              color: Colors.purple,
              isLoading: _controller.isLoadingEquipment,
              onPressed: () => _controller.importEquipment(),
            ),
            const SizedBox(height: 12),

            _buildImportCard(
              context: context,
              title: 'Danh mục bài tập',
              description: 'Các danh mục workout collection',
              icon: Icons.category,
              color: Colors.blue,
              isLoading: _controller.isLoadingCategories,
              onPressed: () => _controller.importCategories(),
            ),
            const SizedBox(height: 24),

            // Warning Note
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Lưu ý: Chỉ import 1 lần. Không import trùng lặp!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildImportCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required RxBool isLoading,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() => isLoading.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.arrow_forward_ios, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

