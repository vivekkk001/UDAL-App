import 'package:hive/hive.dart';
import '../models/pickup_log.dart';

class DBService {
  static const String boxName = 'pickup_logs';

  Future<void> insertPickup(PickupLog log) async {
    final box = await Hive.openBox<PickupLog>(boxName);
    await box.add(log);
    await box.close();
  }

  Future<List<PickupLog>> getAllPickups() async {
    final box = await Hive.openBox<PickupLog>(boxName);
    final allLogs = box.values.toList();
    await box.close();
    return allLogs;
  }

  Future<void> clearAll() async {
    final box = await Hive.openBox<PickupLog>(boxName);
    await box.clear();
    await box.close();
  }
}
