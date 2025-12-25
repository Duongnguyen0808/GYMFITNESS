import 'package:vipt/app/data/models/tracker.dart';

class WaterTracker extends Tracker {
  int waterVolume;
  String? userID;

  WaterTracker({int? id, required DateTime date, required this.waterVolume, this.userID})
      : super(id: id, date: date);

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'date': date.toString(),
      'waterVolume': waterVolume,
    };

    if (super.id != null) {
      map['id'] = super.id;
    }
    
    if (userID != null) {
      map['userID'] = userID;
    }

    return map;
  }

  factory WaterTracker.fromMap(Map<String, dynamic> map) {
    return WaterTracker(
        id: map['id'] ?? 0,
        waterVolume: map['waterVolume'] ?? 0,
        date: DateTime.parse(map['date']),
        userID: map['userID']);
  }

  @override
  String toString() =>
      'WaterTracker(id: ${super.id} date: ${super.date} waterVolume: $waterVolume)';
}
