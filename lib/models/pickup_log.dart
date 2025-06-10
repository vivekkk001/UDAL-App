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

  @HiveField(9)
  String? paymentMethod; 

  @HiveField(10)
  String? paymentStatus;

  @HiveField(11)
  String? paymentAmount; 


  PickupLog({
    required this.workerId,
    required this.householdId,
    required this.photoUrl,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.paymentAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    this.address,
    this.confirmedByHousehold = false,
    this.synced = false,
  });
}
