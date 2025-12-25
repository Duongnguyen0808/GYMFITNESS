import 'package:vipt/app/data/models/base_model.dart';
import 'package:vipt/app/data/models/collection_setting.dart';
import 'package:vipt/app/enums/app_enums.dart';
import 'package:vipt/app/enums/enum_serialize.dart';

class ViPTUser extends BaseModel {
  String name;
  Gender gender;
  DateTime dateOfBirth;
  num currentWeight;
  num currentHeight;
  num goalWeight;
  WeightUnit weightUnit;
  HeightUnit heightUnit;
  List<Hobby>? hobbies;
  Diet? diet;
  List<BadHabit>? badHabits;
  List<ProteinSource>? proteinSources;
  List<PhyscialLimitaion>? limits;
  SleepTime? sleepTime;
  DailyWater? dailyWater;
  MainGoal? mainGoal;
  BodyType? bodyType;
  Experience? experience;
  TypicalDay? typicalDay;
  ActiveFrequency activeFrequency;
  CollectionSetting collectionSetting;

  ViPTUser({
    required String id,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.currentWeight,
    required this.currentHeight,
    required this.goalWeight,
    required this.weightUnit,
    required this.heightUnit,
    required this.hobbies,
    required this.diet,
    required this.badHabits,
    required this.proteinSources,
    required this.limits,
    required this.sleepTime,
    required this.dailyWater,
    required this.mainGoal,
    required this.bodyType,
    required this.experience,
    required this.typicalDay,
    required this.activeFrequency,
    required this.collectionSetting,
  }) : super(id);

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender.toStr(),
      'dateOfBirth': dateOfBirth.toIso8601String(), // Chuyển DateTime thành String ISO
      'currentWeight': currentWeight,
      'currentHeight': currentHeight,
      'goalWeight': goalWeight,
      'weightUnit': weightUnit.toStr(),
      'heightUnit': heightUnit.toStr(),
      'hobbies': hobbies?.map((e) => e.toStr()).toList() ?? [],
      'diet': diet?.toStr() ?? '',
      'badHabits': badHabits?.map((e) => e.toStr()).toList() ?? [],
      'proteinSources': proteinSources?.map((e) => e.toStr()).toList() ?? [],
      'limits': limits?.map((e) => e.toStr()).toList() ?? [],
      'sleepTime': sleepTime?.toStr() ?? '',
      'dailyWater': dailyWater?.toStr() ?? '',
      'mainGoal': mainGoal?.toStr() ?? '',
      'bodyType': bodyType?.toStr() ?? '',
      'experience': experience?.toStr() ?? '',
      'typicalDay': typicalDay?.toStr() ?? '',
      'activeFrequency': activeFrequency.toStr(),
      'collectionSetting': collectionSetting.toMap(),
    };
  }

  factory ViPTUser.fromMap(Map<String, dynamic> data) {
    // Xử lý null safety cho các trường có thể null
    Iterable hobbies = data['hobbies'] ?? [];
    Iterable limits = data['limits'] ?? [];
    Iterable badHabits = data['badHabits'] ?? [];
    Iterable proteinSources = data['proteinSources'] ?? [];

    // Xử lý dateOfBirth - có thể là DateTime, String ISO, hoặc Timestamp
    DateTime dateOfBirth;
    if (data['dateOfBirth'] is DateTime) {
      dateOfBirth = data['dateOfBirth'] as DateTime;
    } else if (data['dateOfBirth'] is String) {
      dateOfBirth = DateTime.parse(data['dateOfBirth']);
    } else if (data['dateOfBirth'] != null) {
      // Handle Firestore Timestamp hoặc MongoDB Date
      try {
        if (data['dateOfBirth'].toString().contains('Timestamp')) {
          dateOfBirth = (data['dateOfBirth'] as dynamic).toDate();
        } else {
          dateOfBirth = DateTime.parse(data['dateOfBirth'].toString());
        }
      } catch (e) {
        dateOfBirth = DateTime.now();
      }
    } else {
      dateOfBirth = DateTime.now();
    }

    // Xử lý id - có thể là _id (MongoDB) hoặc id
    final userId = data['_id'] ?? data['id'] ?? '';

    return ViPTUser(
      id: userId,
      name: data['name'] ?? '',
      gender: GenderFormat.fromStr(data['gender']?.toString() ?? 'other'),
      dateOfBirth: dateOfBirth,
      currentWeight: (data['currentWeight'] ?? 70) as num,
      currentHeight: (data['currentHeight'] ?? 170) as num,
      goalWeight: (data['goalWeight'] ?? 65) as num,
      weightUnit: WeightUnitFormat.fromStr(data['weightUnit']?.toString() ?? 'kg'),
      heightUnit: HeightUnitFormat.fromStr(data['heightUnit']?.toString() ?? 'cm'),
      hobbies: List<Hobby>.from(hobbies.isEmpty
          ? [Hobby.none]
          : hobbies.map((x) => HobbyFormat.fromStr(x?.toString() ?? ''))),
      diet: DietFormat.fromStr(data['diet']?.toString() ?? ''),
      badHabits: List<BadHabit>.from(badHabits.isEmpty
          ? [BadHabit.none]
          : badHabits.map((x) => BadHabitFormat.fromStr(x?.toString() ?? ''))),
      proteinSources: List<ProteinSource>.from(proteinSources.isEmpty
          ? [ProteinSource.none]
          : proteinSources.map((x) => ProteinSourceFormat.fromStr(x?.toString() ?? ''))),
      limits: List<PhyscialLimitaion>.from(limits.isEmpty
          ? [PhyscialLimitaion.none]
          : limits.map((x) => PhyscialLimitationFormat.fromStr(x?.toString() ?? ''))),
      sleepTime: SleepTimeFormat.fromStr(data['sleepTime']?.toString() ?? ''),
      dailyWater: DailyWaterFormat.fromStr(data['dailyWater']?.toString() ?? ''),
      mainGoal: MainGoalFormat.fromStr(data['mainGoal']?.toString() ?? ''),
      bodyType: BodyTypeFormat.fromStr(data['bodyType']?.toString() ?? ''),
      experience: ExperienceFormat.fromStr(data['experience']?.toString() ?? ''),
      typicalDay: TypicalDayFormat.fromStr(data['typicalDay']?.toString() ?? ''),
      activeFrequency: ActiveFrequencyFormat.fromStr(
        data['activeFrequency']?.toString() ?? 'average',
      ),
      collectionSetting: CollectionSetting.fromMap(data['collectionSetting'] ?? {}),
    );
  }
}
