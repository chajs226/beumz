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
  @HiveField(5)
  String name; // 기록 시점의 습관 이름
  @HiveField(6)
  String icon; // 기록 시점의 습관 아이콘

  RecordModel({
    required this.date,
    required this.habitId,
    required this.status,
    required this.emotion,
    required this.memo,
    this.name = '',
    this.icon = '',
  });
} 