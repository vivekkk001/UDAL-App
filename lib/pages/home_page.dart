import 'package:flutter/material.dart';
import '../models/pickup_log.dart';
import '../services/db_service.dart';
import 'sync_page.dart';

class HomePage extends StatelessWidget {
  final db = DBService();

  @override
  Widget build(BuildContext context) {
    final workerCtrl = TextEditingController();
    final houseCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text("Add Pickup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: workerCtrl,
              decoration: InputDecoration(labelText: 'Worker ID'),
            ),
            TextField(
              controller: houseCtrl,
              decoration: InputDecoration(labelText: 'Household ID'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("Save Pickup"),
              onPressed: () async {
                final log = PickupLog(
                  workerId: workerCtrl.text,
                  householdId: houseCtrl.text,
                  photoUrl: 'dummy/photo.jpg',
                  timestamp: DateTime.now(),
                  lat: 12.9716,
                  lng: 77.5946,
                  synced: false, 
                );

                await db.insertPickup(log);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Saved!")));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text("View Logs"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SyncPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
