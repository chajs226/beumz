import 'package:hive/hive.dart';
part 'daily_emotion_model.g.dart';

@HiveType(typeId: 2)
class DailyEmotionModel extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  String emotion;

  DailyEmotionModel({
    required this.date,
    required this.emotion,
  });
} 