// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAdapter extends TypeAdapter<Word> {
  @override
  final int typeId = 0;

  @override
  Word read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Word(
      category: fields[0] as String,
      level: fields[1] as String,
      spelling: fields[2] as String,
      meaning: fields[3] as String,
      type: fields[4] as String,
      correctAnswer: fields[5] as String?,
      options: (fields[6] as List?)?.cast<String>(),
      explanation: fields[7] as String?,
      nextReviewDate: fields[8] as DateTime,
      isScrap: fields[9] as bool,
      reviewStep: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Word obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.category)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.spelling)
      ..writeByte(3)
      ..write(obj.meaning)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.correctAnswer)
      ..writeByte(6)
      ..write(obj.options)
      ..writeByte(7)
      ..write(obj.explanation)
      ..writeByte(8)
      ..write(obj.nextReviewDate)
      ..writeByte(9)
      ..write(obj.isScrap)
      ..writeByte(10)
      ..write(obj.reviewStep);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
