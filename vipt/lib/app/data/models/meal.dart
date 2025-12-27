import 'package:vipt/app/data/models/base_model.dart';
import 'package:vipt/app/data/models/component.dart';

class Meal extends BaseModel implements Component {
  final String name;
  final String asset;
  final int cookTime;
  final Map<String, String> ingreIDToAmount;
  final List<String> steps;
  final List<String> categoryIDs;

  Meal({
    required String id,
    required this.name,
    required this.asset,
    required this.cookTime,
    required this.ingreIDToAmount,
    required this.steps,
    required this.categoryIDs,
  }) : super(id);

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'asset': asset,
      'cookTime': cookTime,
      'ingreIDToAmount': ingreIDToAmount,
      'steps': steps,
      'categoryIDs': categoryIDs,
    };
  }

  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    // Xử lý ingreIDToAmount - có thể null hoặc không phải Map
    // MongoDB Map được serialize thành object với keys là strings
    Map<String, String> ingreMap = {};
    if (map['ingreIDToAmount'] != null) {
      try {
        if (map['ingreIDToAmount'] is Map) {
          final rawMap = map['ingreIDToAmount'] as Map;
          ingreMap = Map<String, String>.fromEntries(
            rawMap.entries.map((entry) {
              // Key có thể là ObjectId (từ MongoDB) hoặc string
              String keyStr;
              if (entry.key is Map) {
                // Nếu key là object (ObjectId), lấy _id hoặc toString
                keyStr = entry.key['_id']?.toString() ?? 
                         entry.key['id']?.toString() ?? 
                         entry.key.toString();
              } else {
                keyStr = entry.key.toString();
              }
              // Value luôn là string
              final valueStr = entry.value?.toString() ?? '';
              return MapEntry(keyStr, valueStr);
            }),
          );
        } else {
          // ingreIDToAmount không phải Map - bỏ qua
        }
      } catch (e) {
        // Nếu parse lỗi, dùng map rỗng
        ingreMap = {};
      }
    } else {
      // ingreIDToAmount null hoặc missing - bỏ qua
    }

    // Xử lý steps - có thể null hoặc không phải List
    List<String> stepsList = [];
    if (map['steps'] != null) {
      try {
        if (map['steps'] is List) {
          stepsList = List<String>.from(
            (map['steps'] as List).map((e) => e.toString()),
          );
        }
      } catch (e) {
        // Nếu parse lỗi, dùng list rỗng
        stepsList = [];
      }
    }

    // Xử lý categoryIDs - có thể null hoặc không phải List
    // categoryIDs có thể là array of ObjectId (từ MongoDB) hoặc array of strings
    List<String> categoryList = [];
    if (map['categoryIDs'] != null) {
      try {
        if (map['categoryIDs'] is List) {
          categoryList = (map['categoryIDs'] as List).map((e) {
            // Nếu là object (ObjectId từ MongoDB), lấy _id hoặc toString
            if (e is Map) {
              return e['_id']?.toString() ?? e['id']?.toString() ?? e.toString();
            }
            // Nếu là string hoặc ObjectId, convert sang string
            return e.toString();
          }).toList();
        }
      } catch (e) {
        // Nếu parse lỗi, dùng list rỗng
        categoryList = [];
      }
    }

    return Meal(
      id: id,
      name: map['name']?.toString() ?? '',
      asset: map['asset']?.toString() ?? '',
      cookTime: (map['cookTime'] is num)
          ? (map['cookTime'] as num).toInt()
          : int.tryParse(map['cookTime']?.toString() ?? '0') ?? 0,
      ingreIDToAmount: ingreMap,
      steps: stepsList,
      categoryIDs: categoryList,
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
