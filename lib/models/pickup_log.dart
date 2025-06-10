import 'package:hive/hive.dart';

part 'pickup_log.g.dart';

@HiveType(typeId: 0)
class PickupLog extends HiveObject {
  @HiveField(0)
  String workerId;

  @HiveField(1)
  String householdId;

  @HiveField(2)
  String photoUrl;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  double lat;

  @HiveField(5)
  double lng;

  @HiveField(6)
  bool confirmedByHousehold;

  @HiveField(7)
  bool synced;

  @HiveField(8)
  String? address;


  PickupLog({
    required this.workerId,
    required this.householdId,
    required this.photoUrl,
    required this.timestamp,
    required this.lat,
    required this.lng,
    this.address,
    this.confirmedByHousehold = false,
    this.synced = false,
  });
}
