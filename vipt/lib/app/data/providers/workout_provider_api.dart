import 'dart:async';
import 'package:vipt/app/core/values/values.dart';
import 'package:vipt/app/data/models/workout.dart';
import 'package:vipt/app/data/providers/firestoration.dart';
import 'package:vipt/app/data/services/api_service.dart';
import 'package:vipt/app/data/services/cloudinary_service.dart';

class WorkoutProvider implements Firestoration<String, Workout> {
  final _apiService = ApiService.instance;
  final _cloudinaryService = CloudinaryService.instance;

  /// Stream để lắng nghe thay đổi real-time
  Stream<List<Workout>> streamAll() {
    // TODO: Implement WebSocket stream
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await fetchAll();
    }).asyncMap((future) => future);
  }

  @override
  Future<Workout> add(Workout obj) async {
    final workout = await _apiService.createWorkout(obj);
    obj.id = workout.id;
    return obj;
  }

  @override
  String get collectionPath => AppValue.workoutsPath;

  @override
  Future<String> delete(String id) async {
    await _apiService.deleteWorkout(id);
    return id;
  }

  @override
  Future<Workout> fetch(String id) async {
    try {
      return await _apiService.getWorkout(id);
    } catch (e) {
      throw Exception('Workout with id $id does not exist: $e');
    }
  }

  @override
  Future<List<Workout>> fetchAll() async {
    try {
      return await _apiService.getWorkouts();
    } catch (e) {
      print('❌ Error fetching workouts: $e');
      return [];
    }
  }

  @override
  Future<Workout> update(String id, Workout obj) async {
    final workout = await _apiService.updateWorkout(id, obj);
    obj.id = workout.id;
    return obj;
  }

  /// Generate Cloudinary URL for workout assets
  /// [name] - workout name (e.g., 'Windmill')
  /// [type] - asset type ('animation', 'thumbnail', or 'muscle_focus')
  /// [extension] - file extension (e.g., 'mp4', 'jpg', 'png')
  String generateLink(String name, String type, String extension) {
    // Normalize name: replace spaces with underscores and convert to lowercase
    final normalizedName = name.toLowerCase().replaceAll(' ', '_');
    
    // Determine folder based on type
    String folder;
    switch (type) {
      case 'animation':
        folder = 'workouts/animations';
        break;
      case 'thumbnail':
        folder = 'workouts/thumbnails';
        break;
      case 'muscle_focus':
        folder = 'workouts/muscle_focus';
        break;
      default:
        folder = 'workouts';
    }
    
    // Construct public ID
    final publicId = '$folder/$normalizedName.$extension';
    
    // Use video URL for video extensions, image URL for others
    final isVideo = extension.toLowerCase() == 'mp4' || 
                    extension.toLowerCase() == 'mov' || 
                    extension.toLowerCase() == 'webm';
    
    if (isVideo) {
      return '${_cloudinaryService.videoUrl}/$publicId';
    } else {
      return '${_cloudinaryService.imageUrl}/$publicId';
    }
  }
}


