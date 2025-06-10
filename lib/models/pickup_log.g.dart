// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pickup_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PickupLogAdapter extends TypeAdapter<PickupLog> {
  @override
  final int typeId = 0;

  @override
  PickupLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PickupLog(
  workerId: fields[0] as String,
  householdId: fields[1] as String,
  photoUrl: fields[2] as String,
  timestamp: fields[3] as DateTime,
  lat: fields[4] as double,
  lng: fields[5] as double,
  paymentAmount: fields[6] as String,        // Added
  paymentMethod: fields[7] as String,        // Added
  paymentStatus: fields[8] as String,        // Added
  address: fields[9] as String?,             // Added (optional)
  confirmedByHousehold: fields[10] as bool,  // Moved from index 6
  synced: fields[11] as bool,                // Moved from index 7
);
  }

  @override
  void write(BinaryWriter writer, PickupLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.workerId)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.photoUrl)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.lat)
      ..writeByte(5)
      ..write(obj.lng)
      ..writeByte(6)
      ..write(obj.confirmedByHousehold)
      ..writeByte(7)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickupLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
