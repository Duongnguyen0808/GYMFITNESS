import 'package:vipt/app/data/models/tracker.dart';

class ExerciseTracker extends Tracker {
  int outtakeCalories;
  int sessionNumber;
  int totalTime;
  String? userID;

  ExerciseTracker({
    int? id,
    required DateTime date,
    required this.outtakeCalories,
    required this.sessionNumber,
    required this.totalTime,
    this.userID,
  }) : super(id: id, date: date);

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'date': super.date.toString(),
      'outtakeCalories': outtakeCalories,
      'sessionNumber': sessionNumber,
      'totalTime': totalTime,
    };

    if (super.id != null) {
      map['id'] = super.id;
    }
    
    if (userID != null) {
      map['userID'] = userID;
    }

    return map;
  }

  factory ExerciseTracker.fromMap(Map<String, dynamic> map) {
    return ExerciseTracker(
      id: map['id'],
      date: DateTime.parse(map['date']),
      outtakeCalories: map['outtakeCalories'] ?? 0,
      sessionNumber: map['sessionNumber']?.toInt() ?? 0,
      totalTime: map['totalTime'] ?? 0,
      userID: map['userID'],
    );
  }

  @override
  String toString() =>
      'ExerciseTracker(id: $id, date: $date, outtakeCalories: $outtakeCalories, sessionNumber: $sessionNumber, totalTime: $totalTime)';
}
