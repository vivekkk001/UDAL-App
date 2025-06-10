import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pickup_log.dart';
import '../services/db_service.dart';
import 'sync_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = DBService();
  final workerCtrl = TextEditingController();
  final houseCtrl = TextEditingController();
  XFile? _pickedImage;

  double? lat;
  double? lng;

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location permission denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      lat = position.latitude;
      lng = position.longitude;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("📍 Location fetched!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Pickup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: workerCtrl,
                decoration: InputDecoration(labelText: 'Worker ID'),
              ),
              TextField(
                controller: houseCtrl,
                decoration: InputDecoration(labelText: 'Household ID'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _getLocation,
                    child: Text("Get Location"),
                  ),
                  SizedBox(width: 12),
                  if (lat != null && lng != null)
                    Text("📍 $lat, $lng", style: TextStyle(fontSize: 12)),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Take Photo"),
                onPressed: () async {
                  final picker = ImagePicker();

                  final image = await picker.pickImage(
                    source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
                  );

                  if (image != null) {
                    setState(() {
                      _pickedImage = image;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("No image selected.")),
                    );
                  }
                },
              ),
              if (_pickedImage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: kIsWeb
                      ? Image.network(_pickedImage!.path, height: 100)
                      : Image.file(File(_pickedImage!.path), height: 100),
                ),

              ElevatedButton(
                child: Text("Save Pickup"),
                onPressed: () async {
                  if (lat == null || lng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please get location first")),
                    );
                    return;
                  }

                  final log = PickupLog(
                    workerId: workerCtrl.text,
                    householdId: houseCtrl.text,
                    photoUrl: _pickedImage?.path ?? '',
                    timestamp: DateTime.now(),
                    lat: lat ?? 0.0,
                    lng: lng ?? 0.0,
                  );

                  await db.insertPickup(log);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Pickup Saved ✅")));

                  // Reset form
                  setState(() {
                    workerCtrl.clear();
                    houseCtrl.clear();
                    lat = null;
                    lng = null;
                    _pickedImage = null;
                  });
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
      ),
    );
  }
}
