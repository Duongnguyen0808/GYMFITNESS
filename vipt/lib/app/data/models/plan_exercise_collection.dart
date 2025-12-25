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
    return PlanExerciseCollection(
      id: id,
      planID: map['planID']?.toInt() ?? 0,
      date: DateTime.parse(map['date']),
      collectionSettingID: map['collectionSettingID']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'PlanExerciseCollection(id: $id, planID: $planID, date: $date, collectionSettingID: $collectionSettingID)';
}
