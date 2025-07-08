import 'package:hive/hive.dart';
part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String limitType; // 예: '주 3회 이하', '매일 금지' 등
  @HiveField(3)
  String icon; // 아이콘 이름 또는 이모지
  @HiveField(4)
  String color; // HEX 색상코드

  HabitModel({
    required this.id,
    required this.name,
    required this.limitType,
    required this.icon,
    required this.color,
  });
} 