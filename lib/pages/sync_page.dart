import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../models/pickup_log.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_keys.dart'; // ensure this exports googleMapsApiKey

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
    final box = await Hive.openBox<PickupLog>('pickup_logs');
    final unsynced = box.values.where((log) => !log.synced).toList();

    for (var log in unsynced) {
      try {
        final url =
            'https://maps.googleapis.com/maps/api/geocode/json?latlng=${log.lat},${log.lng}&key=$googleMapsApiKey';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && data['results'].isNotEmpty) {
            log.address = data['results'][0]['formatted_address'];
          } else {
            log.address = 'Unknown Address';
            print("❗ Google returned status: ${data['status']}");
          }
        } else {
          log.address = 'Error: HTTP ${response.statusCode}';
          print("❗ HTTP error: ${response.statusCode}");
        }

        log.synced = true;
        await log.save();
      } catch (e) {
        print("❗ Exception during sync: $e");
        log.address = 'Error Fetching Address';
        log.synced = true;
        await log.save();
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Mock Sync Complete")));

    _refreshLogs();
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
          TextButton(
            child: Text("Delete Synced", style: TextStyle(color: const Color.fromARGB(255, 50, 45, 117))),
            onPressed: () async {
              await db.deleteSynced();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Deleted all synced pickups")),
              );
              _refreshLogs();
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
            itemBuilder: (_, i) {
              final log = logs[i];
              final imageNote = (log.synced && log.photoUrl.isNotEmpty)
                  ? " ( ✅ Image Uploaded)"
                  : "";

              return ListTile(
                leading: Icon(Icons.local_shipping),
                title: Text("House Number: ${log.householdId}"),
                subtitle: Text(
                  "Date and Time: ${log.timestamp}\n"
                  "Latitude: ${log.lat}, Longitude: ${log.lng}\n"
                  "Address: ${log.address ?? 'No address (yet)'}\n$imageNote",
                  style: TextStyle(fontSize: 12),
                ),
                trailing: log.synced
                    ? Icon(Icons.cloud_done, color: Colors.green)
                    : Icon(Icons.cloud_off, color: Colors.red),
              );
            },
          );
        },
      ),
    );
  }
}
