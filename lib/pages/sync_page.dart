import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../models/pickup_log.dart';
import 'package:hive/hive.dart';

class SyncPage extends StatefulWidget {
  @override
  _SyncPageState createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final db = DBService();
  late Future<List<PickupLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = db.getAllPickups();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logsFuture = db.getAllPickups();
    });
  }

  Future<void> _mockSync() async {
    final box = await db.box; // get the already opened box from DBService
    final unsynced = box.values.where((log) => !log.synced).toList();

    for (var log in unsynced) {
      log.synced = true;
      await log.save();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Mock Sync Complete")));

    _refreshLogs(); // Your method to reload logs and refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pickup Logs"),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            tooltip: 'Sync Now',
            onPressed: _mockSync,
          ),
          ElevatedButton(
            child: Text("Delete Synced Data"),
            onPressed: () async {
              await db.deleteSynced();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Deleted all synced pickups")),
              );
              _refreshLogs(); // refresh UI after deletion
            },
          ),
        ],
      ),
      body: FutureBuilder<List<PickupLog>>(
        future: _logsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final logs = snapshot.data!;
          if (logs.isEmpty) return Center(child: Text("No pickups found"));

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (_, i) => ListTile(
              leading: Icon(Icons.local_shipping),
              title: Text("HH: ${logs[i].householdId}"),
              subtitle: Text("At: ${logs[i].timestamp.toString()}"),
              trailing: logs[i].synced
                  ? Icon(Icons.cloud_done, color: Colors.green)
                  : Icon(Icons.cloud_off, color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
