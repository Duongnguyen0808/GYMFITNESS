class PlanExercise {
  String? id;
  final String exerciseID;
  final String listID;

  PlanExercise({this.id, required this.exerciseID, required this.listID});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'exerciseID': exerciseID,
      'listID': listID,
    };

    return map;
  }

  factory PlanExercise.fromMap(String id, Map<String, dynamic> map) {
    return PlanExercise(
      id: id,
      exerciseID: map['exerciseID'] ?? '',
      listID: map['listID']?.toString() ?? '',
    );
  }

  @override
  String toString() =>
      'PlanExercise(id: $id, exerciseID: $exerciseID, listID: $listID)';
}
