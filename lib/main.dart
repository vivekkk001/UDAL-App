import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/pickup_log.dart';
import 'services/db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the adapter for PickupLog
  Hive.registerAdapter(PickupLogAdapter());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final db = DBService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDAL Test DB',
      home: Scaffold(
        appBar: AppBar(title: Text('DB Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              final log = PickupLog(
                workerId: 'W123',
                householdId: 'H456',
                photoUrl: 'dummy/path.jpg',
                timestamp: DateTime.now(),
                lat: 12.91,
                lng: 74.85,
              );

              await db.insertPickup(log);
              final allLogs = await db.getAllPickups();
              for (var l in allLogs) {
                print("📦 Household: ${l.householdId} at ${l.timestamp}");
              }
            },
            child: Text('Insert & Print Logs'),
          ),
        ),
      ),
    );
  }
}
