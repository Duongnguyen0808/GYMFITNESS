class PlanMeal {
  String? id;
  final String mealID;
  final String listID;

  PlanMeal({this.id, required this.mealID, required this.listID});

  @override
  String toString() => 'PlanMeal(id: $id, mealID: $mealID, listID: $listID)';

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'mealID': mealID,
      'listID': listID,
    };

    return map;
  }

  factory PlanMeal.fromMap(String id, Map<String, dynamic> map) {
    return PlanMeal(
      id: id,
      mealID: map['mealID'] ?? '',
      listID: map['listID']?.toString() ?? '',
    );
  }
}
