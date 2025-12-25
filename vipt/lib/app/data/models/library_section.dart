import 'package:vipt/app/data/models/base_model.dart';

class LibrarySection extends BaseModel {
  final String title;
  final String description;
  final String asset;
  final String route; // Route name để navigate
  final int order; // Thứ tự hiển thị
  final bool isActive; // Bật/tắt section

  LibrarySection(
    String? id, {
    required this.title,
    required this.description,
    required this.asset,
    required this.route,
    required this.order,
    required this.isActive,
  }) : super(id);

  @override
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'asset': asset,
      'route': route,
      'order': order,
      'isActive': isActive,
    };
  }

  factory LibrarySection.fromMap(String id, Map<String, dynamic> data) {
    return LibrarySection(
      id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      asset: data['asset'] ?? '',
      route: data['route'] ?? '',
      order: data['order']?.toInt() ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  LibrarySection copyWith({
    String? id,
    String? title,
    String? description,
    String? asset,
    String? route,
    int? order,
    bool? isActive,
  }) {
    return LibrarySection(
      id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      asset: asset ?? this.asset,
      route: route ?? this.route,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }
}










