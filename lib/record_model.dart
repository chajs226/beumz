import 'package:hive/hive.dart';
part 'record_model.g.dart';

@HiveType(typeId: 1)
class RecordModel extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  String habitId;
  @HiveField(2)
  String status; // 'success' or 'fail'
  @HiveField(3)
  String emotion;
  @HiveField(4)
  String memo;

  RecordModel({
    required this.date,
    required this.habitId,
    required this.status,
    required this.emotion,
    required this.memo,
  });
} 