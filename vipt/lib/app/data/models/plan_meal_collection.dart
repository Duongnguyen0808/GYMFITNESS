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
    // Handle date - can be string or DateTime
    DateTime date;
    if (map['date'] is DateTime) {
      date = map['date'] as DateTime;
    } else if (map['date'] is String) {
      date = DateTime.parse(map['date']);
    } else {
      date = DateTime.now();
    }

    return PlanMealCollection(
      id: id,
      planID: map['planID'] is int ? map['planID'] : (map['planID']?.toInt() ?? 0),
      date: date,
      mealRatio: map['mealRatio'] is double ? map['mealRatio'] : (map['mealRatio']?.toDouble() ?? 1.0),
    );
  }

  @override
  String toString() =>
      'PlanMealCollection(id: $id, date: $date, mealRatio: $mealRatio)';
}
