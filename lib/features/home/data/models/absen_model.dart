import 'package:hive/hive.dart';

// Manual adapter

@HiveType(typeId: 0)
class AbsenModel extends HiveObject {
  @HiveField(0)
  final String checkinIn;

  @HiveField(1)
  final String checkinTolerance;

  @HiveField(2)
  final String breakIn;

  @HiveField(3)
  final String breakOut;

  @HiveField(4)
  final String checkoutTolerance;

  @HiveField(5)
  final String checkoutOut;

  AbsenModel({
    required this.checkinIn,
    required this.checkinTolerance,
    required this.breakIn,
    required this.breakOut,
    required this.checkoutTolerance,
    required this.checkoutOut,
  });

  factory AbsenModel.fromJson(Map<String, dynamic> json) {
    return AbsenModel(
      checkinIn: json['masuk_jam'] ?? '',
      checkinTolerance: json['masuk_toleransi'] ?? '',
      breakIn: json['istirahat_jam'] ?? '',
      breakOut: json['istirahat_batas'] ?? '',
      checkoutTolerance: json['pulang_toleransi'] ?? '',
      checkoutOut: json['pulang_jam'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'masuk_jam': checkinIn,
      'masuk_toleransi': checkinTolerance,
      'istirahat_jam': breakIn,
      'istirahat_batas': breakOut,
      'pulang_toleransi': checkoutTolerance,
      'pulang_jam': checkoutOut,
    };
  }
}

class AbsenModelAdapter extends TypeAdapter<AbsenModel> {
  @override
  final int typeId = 0;

  @override
  AbsenModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AbsenModel(
      checkinIn: fields[0] as String,
      checkinTolerance: fields[1] as String,
      breakIn: fields[2] as String,
      breakOut: fields[3] as String,
      checkoutTolerance: fields[4] as String,
      checkoutOut: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AbsenModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.checkinIn)
      ..writeByte(1)
      ..write(obj.checkinTolerance)
      ..writeByte(2)
      ..write(obj.breakIn)
      ..writeByte(3)
      ..write(obj.breakOut)
      ..writeByte(4)
      ..write(obj.checkoutTolerance)
      ..writeByte(5)
      ..write(obj.checkoutOut);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AbsenModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
