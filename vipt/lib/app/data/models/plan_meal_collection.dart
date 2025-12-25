class PlanMealCollection {
  String? id;
  final DateTime date;
  double mealRatio;
  final int planID;

  PlanMealCollection(
      {this.id,
      required this.date,
      required this.mealRatio,
      required this.planID});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'date': date.toString(),
      'planID': planID,
      'mealRatio': mealRatio,
    };

    return map;
  }

  factory PlanMealCollection.fromMap(String id, Map<String, dynamic> map) {
    return PlanMealCollection(
      id: id,
      planID: map['planID']?.toInt() ?? 0,
      date: DateTime.parse(map['date']),
      mealRatio: map['mealRatio']?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'PlanMealCollection(id: $id, date: $date, mealRatio: $mealRatio)';
}
