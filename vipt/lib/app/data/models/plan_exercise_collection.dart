class PlanExerciseCollection {
  String? id;
  final DateTime date;
  final String collectionSettingID;
  final int planID;

  PlanExerciseCollection(
      {this.id,
      required this.date,
      required this.planID,
      required this.collectionSettingID});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'date': date.toString(),
      'collectionSettingID': collectionSettingID,
      'planID': planID,
    };

    return map;
  }

  factory PlanExerciseCollection.fromMap(String id, Map<String, dynamic> map) {
    // Handle date - can be string or DateTime
    DateTime date;
    if (map['date'] is DateTime) {
      date = map['date'] as DateTime;
    } else if (map['date'] is String) {
      date = DateTime.parse(map['date']);
    } else {
      date = DateTime.now();
    }

    // Handle collectionSettingID - can be object with _id or string
    String collectionSettingID;
    if (map['collectionSettingID'] is Map) {
      collectionSettingID = map['collectionSettingID']['_id']?.toString() ?? 
                           map['collectionSettingID']['id']?.toString() ?? '';
    } else {
      collectionSettingID = map['collectionSettingID']?.toString() ?? '';
    }

    return PlanExerciseCollection(
      id: id,
      planID: map['planID'] is int ? map['planID'] : (map['planID']?.toInt() ?? 0),
      date: date,
      collectionSettingID: collectionSettingID,
    );
  }

  @override
  String toString() =>
      'PlanExerciseCollection(id: $id, planID: $planID, date: $date, collectionSettingID: $collectionSettingID)';
}
