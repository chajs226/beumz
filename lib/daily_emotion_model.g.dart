// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_emotion_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyEmotionModelAdapter extends TypeAdapter<DailyEmotionModel> {
  @override
  final int typeId = 2;

  @override
  DailyEmotionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyEmotionModel(
      date: fields[0] as DateTime,
      emotion: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyEmotionModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.emotion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyEmotionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
