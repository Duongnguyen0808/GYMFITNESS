import 'package:vipt/app/data/models/base_model.dart';
import 'package:vipt/app/data/models/component.dart';

class Workout extends BaseModel implements Component {
  final String name;
  final String animation;
  final String thumbnail;
  final String hints;
  final String breathing;
  final String muscleFocusAsset;
  final List<String> categoryIDs;
  final num metValue;
  final List<String> equipmentIDs;

  Workout(
    String? id, {
    required this.name,
    required this.animation,
    required this.thumbnail,
    required this.hints,
    required this.breathing,
    required this.muscleFocusAsset,
    required this.categoryIDs,
    required this.metValue,
    required this.equipmentIDs,
  }) : super(id);

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'animation': animation,
      'thumbnail': thumbnail,
      'hints': hints,
      'breathing': breathing,
      'muscleFocusAsset': muscleFocusAsset,
      'categoryIDs': categoryIDs,
      'metValue': metValue,
      'equipmentIDs': equipmentIDs,
    };
  }

  factory Workout.fromMap(String id, Map<String, dynamic> map) {
    // Xử lý categoryIDs: có thể là array of strings hoặc array of objects (populated)
    List<String> parseCategoryIDs(dynamic categories) {
      if (categories == null) return [];
      if (categories is List) {
        return categories.map((e) {
          if (e is String) return e;
          if (e is Map) return (e['_id'] ?? e['id'] ?? '').toString();
          return e.toString();
        }).where((id) => id.isNotEmpty).toList();
      }
      return [];
    }

    // Xử lý equipmentIDs: có thể là array of strings hoặc array of objects (populated)
    List<String> parseEquipmentIDs(dynamic equipment) {
      if (equipment == null) return [];
      if (equipment is List) {
        return equipment.map((e) {
          if (e is String) return e;
          if (e is Map) return (e['_id'] ?? e['id'] ?? '').toString();
          return e.toString();
        }).where((id) => id.isNotEmpty).toList();
      }
      return [];
    }

    return Workout(
      id,
      name: map['name'] ?? '',
      animation: map['animation'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      hints: map['hints'] ?? '',
      breathing: map['breathing'] ?? '',
      muscleFocusAsset: map['muscleFocusAsset'] ?? '',
      categoryIDs: parseCategoryIDs(map['categoryIDs']),
      metValue: map['metValue'] ?? 0,
      equipmentIDs: parseEquipmentIDs(map['equipmentIDs']),
    );
  }

  @override
  int countLeaf() {
    return 1;
  }

  @override
  bool isComposite() {
    return false;
  }
}
