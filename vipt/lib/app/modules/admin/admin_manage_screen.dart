import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vipt/app/data/services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vipt/app/data/providers/ingredient_provider_api.dart';
import 'package:vipt/app/data/providers/meal_provider_api.dart';
import 'package:vipt/app/data/providers/workout_equipment_provider_api.dart';
import 'package:vipt/app/data/providers/workout_collection_category_provider_api.dart';
import 'package:vipt/app/data/providers/workout_provider_api.dart';
import 'package:vipt/app/data/providers/workout_category_provider_api.dart';
import 'package:vipt/app/data/providers/workout_collection_provider_api.dart';
import 'package:vipt/app/data/providers/meal_category_provider_api.dart';
import 'package:vipt/app/data/providers/meal_collection_provider_api.dart';
import 'package:vipt/app/data/providers/library_section_provider_api.dart';
import 'package:vipt/app/data/models/ingredient.dart';
import 'package:vipt/app/data/models/meal.dart';
import 'package:vipt/app/data/models/workout_equipment.dart';
import 'package:vipt/app/data/models/category.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/models/workout_collection.dart';
import 'package:vipt/app/data/models/meal_collection.dart';
import 'package:vipt/app/data/models/library_section.dart';
import 'package:vipt/app/data/services/data_service.dart';
import 'package:vipt/app/core/values/asset_strings.dart';
import 'package:vipt/app/core/controllers/theme_controller.dart';
import 'admin_ingredient_form.dart';
import 'admin_meal_form.dart';
import 'admin_equipment_form.dart';
import 'admin_category_form.dart';
import 'admin_workout_form.dart';
import 'admin_workout_category_form.dart';
import 'admin_workout_collection_form.dart';
import 'admin_meal_category_form.dart';
import 'admin_meal_collection_form.dart';
import 'admin_library_section_form.dart';
import 'admin_workout_plan_manage.dart';
import 'admin_meal_plan_manage.dart';
import 'package:vipt/app/routes/pages.dart';

class AdminManageScreen extends StatefulWidget {
  const AdminManageScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends State<AdminManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? currentUser;
  bool _isSyncing = false;
  late ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    currentUser = AuthService.instance.currentUser;
    // Get or create theme controller
    if (Get.isRegistered<ThemeController>()) {
      _themeController = Get.find<ThemeController>();
    } else {
      _themeController = Get.put(ThemeController());
    }
  }

  void _toggleTheme() {
    _themeController.toggleTheme();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _syncAllData() async {
    if (mounted) {
      setState(() => _isSyncing = true);
    }
    try {
      await DataService.instance.reloadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã đồng bộ tất cả dữ liệu cho mobile app!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đồng bộ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = _themeController.isDarkMode.value;
      return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: Column(
        children: [
          // Header section with "Quản lý Dữ liệu" and actions
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Quản lý Dữ liệu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700, 
                        fontSize: 21,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  // Theme toggle button
                  Obx(() => Tooltip(
                    message: _themeController.isDarkMode.value ? 'Chế độ sáng' : 'Chế độ tối',
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _themeController.isDarkMode.value ? Icons.light_mode : Icons.dark_mode,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: _toggleTheme,
                        tooltip: _themeController.isDarkMode.value ? 'Chế độ sáng' : 'Chế độ tối',
                      ),
                    ),
                  )),
                  // Sync button
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: _isSyncing
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : Tooltip(
                            message: 'Đồng bộ dữ liệu cho Mobile App',
                            child: IconButton(
                              icon: const Icon(Icons.sync, color: Colors.white),
                              onPressed: _syncAllData,
                            ),
                          ),
                  ),
                  if (currentUser != null)
                    PopupMenuButton<String>(
                      offset: const Offset(0, 50),
                      child: Container(
                        margin: const EdgeInsets.only(right: 0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Text(
                                (currentUser!['email'] as String? ?? 'A').substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (currentUser!['email'] as String? ?? 'admin@admin.com').split('@')[0],
                              style: const TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 20, color: Colors.white),
                          ],
                        ),
                      ),
                      onSelected: (value) async {
                        if (value == 'logout') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Đăng xuất'),
                              content: const Text('Bạn có chắc muốn đăng xuất?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await AuthService.instance.signOut();
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(Routes.adminLogin, (route) => false);
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: const [
                              Icon(Icons.logout, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // TabBar section
          Container(
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, 
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  isScrollable: true,
                  tabs: const [
                    Tab(
                        icon: Icon(Icons.restaurant_menu, size: 20),
                        text: 'Nguyên liệu'),
                    Tab(icon: Icon(Icons.fastfood, size: 20), text: 'Món ăn'),
                    Tab(
                        icon: Icon(Icons.fitness_center, size: 20),
                        text: 'Thiết bị'),
                    Tab(
                        icon: Icon(Icons.sports_gymnastics, size: 20),
                        text: 'Bài tập'),
                    Tab(
                        icon: Icon(Icons.category_outlined, size: 20),
                        text: 'DM Bài tập'),
                    Tab(icon: Icon(Icons.restaurant, size: 20), text: 'DM Món ăn'),
                    Tab(
                        icon: Icon(Icons.library_books, size: 20),
                        text: 'Thư viện'),
                    Tab(
                        icon: Icon(Icons.list_alt, size: 20),
                        text: 'DS Bài tập'),
                    Tab(
                        icon: Icon(Icons.restaurant_menu, size: 20),
                        text: 'DS Món ăn'),
                  ],
                ),
                // Divider line to separate tab bar from content
                Container(
                  height: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
          ),
          // TabBarView content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                AdminIngredientManage(),
                AdminMealManage(),
                AdminEquipmentManage(),
                AdminWorkoutManage(),
                AdminWorkoutCategoryManage(),
                AdminMealCategoryManage(),
                AdminLibrarySectionManage(),
                const AdminWorkoutPlanManage(),
                const AdminMealPlanManage(),
              ],
            ),
          ),
        ],
      ),
      );
    });
  }
}

// Ingredient Management
class AdminIngredientManage extends StatefulWidget {
  const AdminIngredientManage({Key? key}) : super(key: key);

  @override
  State<AdminIngredientManage> createState() => _AdminIngredientManageState();
}

// Helper widget for info chips
Widget _buildInfoChip(String label, Color color, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: isDark ? color.withOpacity(0.25) : color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDark ? color.withOpacity(0.5) : color.withOpacity(0.4),
        width: 1.5,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}

class _AdminIngredientManageState extends State<AdminIngredientManage> {
  final IngredientProvider _provider = IngredientProvider();
  List<Ingredient> _ingredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _ingredients = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadMealData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _deleteIngredient(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa nguyên liệu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme controller directly for fast access
    final themeController = Get.isRegistered<ThemeController>() 
        ? Get.find<ThemeController>() 
        : null;
    
    // Use Obx for reactive theme updates - this rebuilds instantly
    return Obx(() {
      final isDark = themeController?.isDarkMode.value ?? false;
      
      return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _ingredients.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Chưa có nguyên liệu nào',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadData,
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ingredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _ingredients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isDark ? 4 : 2,
                        shadowColor: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ingredient.imageUrl != null &&
                                    ingredient.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: ingredient.imageUrl!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade400,
                                            Colors.orange.shade600
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.restaurant_menu,
                                          color: Colors.white, size: 28),
                                    ),
                                  )
                                : Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.orange.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.restaurant_menu,
                                        color: Colors.white, size: 28),
                                  ),
                          ),
                          title: Text(
                            ingredient.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, 
                                fontSize: 17,
                                color: isDark ? Colors.white : Colors.black87),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildInfoChip(
                                    '${ingredient.kcal} kcal', Colors.orange, context),
                                _buildInfoChip(
                                    '${ingredient.fat}g fat', Colors.red.shade600, context),
                                _buildInfoChip(
                                    '${ingredient.carbs}g carbs', Colors.blue.shade600, context),
                                _buildInfoChip('${ingredient.protein}g protein',
                                    Colors.green.shade600, context),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.blue.shade600,
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminIngredientForm(
                                          ingredient: ingredient),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red.shade600,
                                onPressed: ingredient.id != null &&
                                        ingredient.id!.isNotEmpty
                                    ? () => _deleteIngredient(ingredient.id!)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminIngredientForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.orange.shade600,
      ),
      );
    });
  }
}

// Meal Management
class AdminMealManage extends StatefulWidget {
  const AdminMealManage({Key? key}) : super(key: key);

  @override
  State<AdminMealManage> createState() => _AdminMealManageState();
}

class _AdminMealManageState extends State<AdminMealManage> {
  final MealProvider _provider = MealProvider();
  List<Meal> _meals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _meals = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadMealData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteMeal(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa món ăn này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.isRegistered<ThemeController>() 
        ? Get.find<ThemeController>() 
        : null;
    
    return Obx(() {
      final isDark = themeController?.isDarkMode.value ?? 
                    (Theme.of(context).brightness == Brightness.dark);
      
      return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _meals.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có món ăn nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadData,
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _meals.length,
                    itemBuilder: (context, index) {
                      final meal = _meals[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isDark ? 4 : 2,
                        shadowColor: isDark ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: meal.asset.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: meal.asset,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                      JPGAssetString.meal,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    JPGAssetString.meal,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          title: Text(
                            meal.name,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, 
                                fontSize: 17,
                                color: isDark ? Colors.white : Colors.black87),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(Icons.timer,
                                    size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${meal.cookTime} phút',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.category,
                                    size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${meal.categoryIDs.length} danh mục',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.blue.shade600,
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AdminMealForm(meal: meal)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red.shade600,
                                onPressed:
                                    meal.id != null && meal.id!.isNotEmpty
                                        ? () => _deleteMeal(meal.id!)
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMealForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.red.shade600,
      ),
      );
    });
  }
}

// Equipment Management
class AdminEquipmentManage extends StatefulWidget {
  const AdminEquipmentManage({Key? key}) : super(key: key);

  @override
  State<AdminEquipmentManage> createState() => _AdminEquipmentManageState();
}

class _AdminEquipmentManageState extends State<AdminEquipmentManage> {
  final WorkoutEquipmentProvider _provider = WorkoutEquipmentProvider();
  List<WorkoutEquipment> _equipment = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _equipment = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadWorkoutData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteEquipment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa thiết bị này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _equipment.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có thiết bị nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadData,
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _equipment.length,
                    itemBuilder: (context, index) {
                      final item = _equipment[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: item.imageLink.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: item.imageLink,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey.shade400),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.purple.shade600
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.fitness_center,
                                      color: Colors.white, size: 28),
                                ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: item.imageLink.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.image,
                                          size: 14,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          item.imageLink.length > 40
                                              ? '${item.imageLink.substring(0, 40)}...'
                                              : item.imageLink,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.blue.shade600,
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminEquipmentForm(
                                            equipment: item)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red.shade600,
                                onPressed:
                                    item.id != null && item.id!.isNotEmpty
                                        ? () => _deleteEquipment(item.id!)
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminEquipmentForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.purple.shade600,
      ),
    );
  }
}

// Category Management
class AdminCategoryManage extends StatefulWidget {
  const AdminCategoryManage({Key? key}) : super(key: key);

  @override
  State<AdminCategoryManage> createState() => _AdminCategoryManageState();
}

class _AdminCategoryManageState extends State<AdminCategoryManage> {
  final WorkoutCollectionCategoryProvider _provider =
      WorkoutCollectionCategoryProvider();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _categories = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadWorkoutData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa danh mục này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có danh mục nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loadData,
                                child: const Text('Tải lại'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: category.asset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: category.asset,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey.shade400),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade600
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.category,
                                      color: Colors.white, size: 28),
                                ),
                          title: Text(
                            category.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  category.parentCategoryID == null
                                      ? Icons.fiber_manual_record
                                      : Icons.subdirectory_arrow_right,
                                  size: 12,
                                  color: category.parentCategoryID == null
                                      ? Colors.green.shade600
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  category.parentCategoryID == null
                                      ? 'Danh mục gốc'
                                      : 'Danh mục con',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.blue.shade600,
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminCategoryForm(
                                            category: category)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red.shade600,
                                onPressed: () =>
                                    _deleteCategory(category.id ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCategoryForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }
}

// Workout Management
class AdminWorkoutManage extends StatefulWidget {
  const AdminWorkoutManage({Key? key}) : super(key: key);

  @override
  State<AdminWorkoutManage> createState() => _AdminWorkoutManageState();
}

class _AdminWorkoutManageState extends State<AdminWorkoutManage> {
  final WorkoutProvider _provider = WorkoutProvider();
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _workouts = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadWorkoutData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteWorkout(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bài tập này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _workouts.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có bài tập nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Tải lại')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final workout = _workouts[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: workout.thumbnail.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: workout.thumbnail,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2)),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey.shade400),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.teal.shade400,
                                        Colors.teal.shade600
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.sports_gymnastics,
                                      color: Colors.white, size: 28),
                                ),
                          title: Text(
                            workout.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildInfoChip(
                                    'MET: ${workout.metValue}', Colors.teal, context),
                                _buildInfoChip(
                                    '${workout.categoryIDs.length} DM',
                                    Colors.blue, context),
                                _buildInfoChip(
                                    '${workout.equipmentIDs.length} TB',
                                    Colors.purple, context),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.blue.shade600,
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AdminWorkoutForm(workout: workout)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red.shade600,
                                onPressed:
                                    workout.id != null && workout.id!.isNotEmpty
                                        ? () => _deleteWorkout(workout.id!)
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminWorkoutForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.teal.shade600,
      ),
    );
  }
}

// Workout Category Management
class AdminWorkoutCategoryManage extends StatefulWidget {
  const AdminWorkoutCategoryManage({Key? key}) : super(key: key);

  @override
  State<AdminWorkoutCategoryManage> createState() =>
      _AdminWorkoutCategoryManageState();
}

class _AdminWorkoutCategoryManageState
    extends State<AdminWorkoutCategoryManage> {
  final WorkoutCategoryProvider _provider = WorkoutCategoryProvider();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _categories = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadWorkoutData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa danh mục bài tập này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có danh mục bài tập nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Tải lại')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: category.asset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: category.asset,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.category_outlined,
                                      color: Colors.grey),
                                ),
                          title: Text(category.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Parent: ${category.parentCategoryID ?? "Gốc"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AdminWorkoutCategoryForm(
                                                category: category)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCategory(category.id ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminWorkoutCategoryForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.indigo.shade600,
      ),
    );
  }
}

// Workout Collection Management
class AdminWorkoutCollectionManage extends StatefulWidget {
  const AdminWorkoutCollectionManage({Key? key}) : super(key: key);

  @override
  State<AdminWorkoutCollectionManage> createState() =>
      _AdminWorkoutCollectionManageState();
}

class _AdminWorkoutCollectionManageState
    extends State<AdminWorkoutCollectionManage> {
  final WorkoutCollectionProvider _provider = WorkoutCollectionProvider();
  List<WorkoutCollection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _collections = await _provider.fetchAllDefaultCollection();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadWorkoutData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteCollection(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bộ luyện tập này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.deleteDefaultCollection(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _collections.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có bộ luyện tập nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Tải lại')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final collection = _collections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: collection.asset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: collection.asset,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.collections,
                                      color: Colors.grey),
                                ),
                          title: Text(collection.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${collection.generatorIDs.length} bài tập | ${collection.categoryIDs.length} danh mục'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            AdminWorkoutCollectionForm(
                                                collection: collection)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCollection(collection.id ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AdminWorkoutCollectionForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.deepOrange.shade600,
      ),
    );
  }
}

// Meal Category Management
class AdminMealCategoryManage extends StatefulWidget {
  const AdminMealCategoryManage({Key? key}) : super(key: key);

  @override
  State<AdminMealCategoryManage> createState() =>
      _AdminMealCategoryManageState();
}

class _AdminMealCategoryManageState extends State<AdminMealCategoryManage> {
  final MealCategoryProvider _provider = MealCategoryProvider();
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _categories = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadMealData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteCategory(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa danh mục món ăn này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có danh mục món ăn nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Tải lại')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: category.asset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: category.asset,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.restaurant,
                                      color: Colors.grey),
                                ),
                          title: Text(category.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Parent: ${category.parentCategoryID ?? "Gốc"}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminMealCategoryForm(
                                            category: category)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCategory(category.id ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMealCategoryForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.amber.shade700,
      ),
    );
  }
}

// Meal Collection Management
class AdminMealCollectionManage extends StatefulWidget {
  const AdminMealCollectionManage({Key? key}) : super(key: key);

  @override
  State<AdminMealCollectionManage> createState() =>
      _AdminMealCollectionManageState();
}

class _AdminMealCollectionManageState extends State<AdminMealCollectionManage> {
  final MealCollectionProvider _provider = MealCollectionProvider();
  List<MealCollection> _collections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _collections = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadMealData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteCollection(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa bộ dinh dưỡng này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _collections.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có bộ dinh dưỡng nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Tải lại')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _collections.length,
                    itemBuilder: (context, index) {
                      final collection = _collections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: collection.asset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: collection.asset,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.set_meal,
                                      color: Colors.grey),
                                ),
                          title: Text(collection.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text('${collection.dateToMealID.length} ngày'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminMealCollectionForm(
                                            collection: collection)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteCollection(collection.id ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMealCollectionForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }
}

// Library Section Management
class AdminLibrarySectionManage extends StatefulWidget {
  const AdminLibrarySectionManage({Key? key}) : super(key: key);

  @override
  State<AdminLibrarySectionManage> createState() =>
      _AdminLibrarySectionManageState();
}

class _AdminLibrarySectionManageState extends State<AdminLibrarySectionManage> {
  final LibrarySectionProvider _provider = LibrarySectionProvider();
  List<LibrarySection> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    try {
      _sections = await _provider.fetchAll();
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi tải dữ liệu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncToMobile() async {
    try {
      await DataService.instance.reloadAllData();
      _showSnackbar('✅ Đã đồng bộ dữ liệu cho mobile app');
    } catch (e) {
      _showSnackbar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  Future<void> _deleteSection(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa phần thư viện này?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _provider.delete(id);
        _showSnackbar('Đã xóa thành công');
        await _loadData();
        await _syncToMobile();
      } catch (e) {
        _showSnackbar('Lỗi xóa: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sections.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có phần thư viện nào',
                                  style:
                                      TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _loadData,
                                  child: const Text('Tải lại')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: section.asset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: section.asset,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.library_books,
                                      color: Colors.grey),
                                ),
                          title: Text(
                            section.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(section.description),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildInfoChip(
                                      'Thứ tự: ${section.order}', Colors.blue, context),
                                  _buildInfoChip(
                                    section.isActive ? 'Đang hiển thị' : 'Ẩn',
                                    section.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    context,
                                  ),
                                  _buildInfoChip(
                                      'Route: ${section.route}', Colors.purple, context),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => AdminLibrarySectionForm(
                                            section: section)),
                                  );
                                  if (result == true) {
                                    await _loadData();
                                    await _syncToMobile();
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteSection(section.id ?? ''),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminLibrarySectionForm()),
          );
          if (result == true) {
            await _loadData();
            await _syncToMobile();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Thêm mới'),
        backgroundColor: Colors.indigo.shade600,
      ),
    );
  }
}
