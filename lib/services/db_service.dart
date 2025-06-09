import 'package:hive/hive.dart';
import '../models/pickup_log.dart';

class DBService {
  static const String boxName = 'pickup_logs';
  Box<PickupLog>? _box;

  Future<Box<PickupLog>> get box async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<PickupLog>(boxName);
    return _box!;
  }

  Future<void> insertPickup(PickupLog log) async {
    final b = await box;
    await b.add(log);
    // don't close here
  }

  Future<List<PickupLog>> getAllPickups() async {
    final b = await box;
    return b.values.toList();
  }

  Future<void> clearAll() async {
    final b = await box;
    await b.clear();
  }

  Future<void> deleteSynced() async {
    final b = await box; // reuse the getter that opens the box once
    final keysToDelete = b.keys.where((key) {
      final log = b.get(key);
      return log != null && log.synced;
    }).toList();

    await b.deleteAll(keysToDelete);
  }
}
