import 'dart:convert';

class CollectionSetting {
  int round;
  int numOfWorkoutPerRound;
  bool isStartWithWarmUp;
  bool isShuffle;
  int exerciseTime;
  int transitionTime;
  int restTime;
  int restFrequency;

  CollectionSetting({
    this.round = 3,
    this.numOfWorkoutPerRound = 5,
    this.isStartWithWarmUp = true,
    this.isShuffle = true,
    this.exerciseTime = 10,
    this.transitionTime = 10,
    this.restTime = 10,
    this.restFrequency = 10,
  });

  factory CollectionSetting.fromCollectionSetting(CollectionSetting set) {
    return CollectionSetting(
      round: set.round,
      exerciseTime: set.exerciseTime,
      isShuffle: set.isShuffle,
      isStartWithWarmUp: set.isStartWithWarmUp,
      numOfWorkoutPerRound: set.numOfWorkoutPerRound,
      restFrequency: set.restFrequency,
      restTime: set.restTime,
      transitionTime: set.transitionTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'round': round,
      'numOfWorkoutPerRound': numOfWorkoutPerRound,
      'isStartWithWarmUp': isStartWithWarmUp,
      'isShuffle': isShuffle,
      'exerciseTime': exerciseTime,
      'transitionTime': transitionTime,
      'restTime': restTime,
      'restFrequency': restFrequency,
    };
  }

  String toJson() => json.encode(toMap());

  factory CollectionSetting.fromJson(String source) =>
      CollectionSetting.fromMap(json.decode(source));

  @override
  String toString() {
    return 'CollectionSetting(round: $round, numOfWorkoutPerRound: $numOfWorkoutPerRound, isStartWithWarmUp: $isStartWithWarmUp, isShuffle: $isShuffle, exerciseTime: $exerciseTime, transitionTime: $transitionTime, restTime: $restTime, restFrequency: $restFrequency)';
  }

  factory CollectionSetting.fromMap(Map<String, dynamic> map) {
    return CollectionSetting(
      round: map['round']?.toInt() ?? 3,
      numOfWorkoutPerRound: map['numOfWorkoutPerRound']?.toInt() ?? 5,
      isStartWithWarmUp: map['isStartWithWarmUp'] ?? true,
      isShuffle: map['isShuffle'] ?? true,
      exerciseTime: map['exerciseTime']?.toInt() ?? 45,
      transitionTime: map['transitionTime']?.toInt() ?? 10,
      restTime: map['restTime']?.toInt() ?? 30,
      restFrequency: map['restFrequency']?.toInt() ?? 3,
    );
  }
}
