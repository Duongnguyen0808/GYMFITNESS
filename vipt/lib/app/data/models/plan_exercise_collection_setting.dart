import 'package:vipt/app/data/models/collection_setting.dart';

class PlanExerciseCollectionSetting extends CollectionSetting {
  String? id;

  PlanExerciseCollectionSetting({
    this.id,
    required int round,
    required int numOfWorkoutPerRound,
    required int exerciseTime,
  }) : super(
          round: round,
          numOfWorkoutPerRound: numOfWorkoutPerRound,
          exerciseTime: exerciseTime,
        );

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'round': round,
      'numOfWorkoutPerRound': numOfWorkoutPerRound,
      'isStartWithWarmUp': isStartWithWarmUp,
      'isShuffle': isShuffle,
      'exerciseTime': exerciseTime,
      'transitionTime': transitionTime,
      'restTime': restTime,
      'restFrequency': restFrequency,
    };

    return map;
  }

  factory PlanExerciseCollectionSetting.fromMap(
      String id, Map<String, dynamic> map) {
    final setting = PlanExerciseCollectionSetting(
      id: id,
      round: map['round']?.toInt() ?? 3,
      numOfWorkoutPerRound: map['numOfWorkoutPerRound']?.toInt() ?? 10,
      exerciseTime: map['exerciseTime']?.toInt() ?? 45,
    );

    setting.isStartWithWarmUp = map['isStartWithWarmUp'] ?? false;
    setting.isShuffle = map['isShuffle'] ?? false;
    setting.transitionTime = map['transitionTime']?.toInt() ?? 10;
    setting.restTime = map['restTime']?.toInt() ?? 30;
    setting.restFrequency = map['restFrequency']?.toInt() ?? 3;

    return setting;
  }
}
