import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pickup_log.dart';
import '../services/db_service.dart';
import 'sync_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String workerId;
  
  const HomePage({super.key, required this.workerId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = DBService();
  final workerCtrl = TextEditingController();
  final houseCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  XFile? _pickedImage;

  double? lat;
  double? lng;
  String? selectedPaymentMethod;
  String? paymentStatus;
  bool showPaymentOptions = false;
  bool showQRCode = false;
  bool showCashForm = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill worker ID and make it read-only
    workerCtrl.text = widget.workerId;
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 16, right: 16),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 50, left: 16, right: 16),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied'),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 50, left: 16, right: 16),
          ),
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
    ).showSnackBar(const SnackBar(content: Text("📍 Location fetched!")));
  }

  void _checkPaymentStatus() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("No Pending Payments")));
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedPaymentMethod = 'UPI';
                    showQRCode = true;
                    showCashForm = false;
                  });
                },
                child: const Text('UPI Payment'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedPaymentMethod = 'CASH';
                    showCashForm = true;
                    showQRCode = false;
                  });
                },
                child: const Text('Cash Payment'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _savePickup() async {
    final log = PickupLog(
      workerId: workerCtrl.text,
      householdId: houseCtrl.text,
      photoUrl: _pickedImage?.path ?? '',
      timestamp: DateTime.now(),
      lat: lat ?? 0.0,
      lng: lng ?? 0.0,
      paymentMethod: selectedPaymentMethod ?? '',
      paymentStatus: paymentStatus ?? 'Pending Payment',
      paymentAmount: amountCtrl.text,
    );

    await db.insertPickup(log);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Pickup Saved ✅")));

    // Reset form (except worker ID)
    setState(() {
      houseCtrl.clear();
      amountCtrl.clear();
      lat = null;
      lng = null;
      _pickedImage = null;
      selectedPaymentMethod = null;
      paymentStatus = null;
      showPaymentOptions = false;
      showQRCode = false;
      showCashForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Pickup"),
        actions: [
          // Worker ID display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.workerId,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker ID Field (Read-only)
              TextField(
                controller: workerCtrl,
                decoration: InputDecoration(
                  labelText: 'Worker ID',
                  suffixIcon: Icon(Icons.lock, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                enabled: false, // Make it read-only
              ),
              TextField(
                controller: houseCtrl,
                decoration: const InputDecoration(labelText: 'Household ID'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _checkPaymentStatus,
                child: const Text("Payment Status"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _showPaymentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Payment"),
              ),
              
              // UPI QR Code Section
              if (showQRCode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('UPI Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // Placeholder for QR Code - replace with your QR code image
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 100),
                              Text('QR Code Here'),
                              Text('(Replace with your QR)', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Wait for customer to complete payment'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                paymentStatus = 'Payment Received';
                                showQRCode = false;
                              });
                            },
                            child: const Text('Payment Received'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                paymentStatus = 'Pending Payment';
                                showQRCode = false;
                              });
                            },
                            child: const Text('Pending Payment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Cash Payment Section
              if (showCashForm) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('Cash Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Enter Amount',
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                paymentStatus = 'Payment Received';
                                showCashForm = false;
                              });
                            },
                            child: const Text('Payment Received'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                paymentStatus = 'Pending Payment';
                                showCashForm = false;
                              });
                            },
                            child: const Text('Pending Payment'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Payment Status Display
              if (paymentStatus != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: paymentStatus == 'Payment Received' ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: $paymentStatus',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: paymentStatus == 'Payment Received' ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _getLocation,
                    child: const Text("Get Location"),
                  ),
                  const SizedBox(width: 12),
                  if (lat != null && lng != null)
                    Text("📍 $lat, $lng", style: const TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text("Take Photo"),
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
                      const SnackBar(content: Text("No image selected.")),
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
                child: const Text("Save Pickup"),
                onPressed: () async {
                  if (lat == null || lng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please get location first")),
                    );
                    return;
                  }

                  _savePickup();
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text("View Logs"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SyncPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    workerCtrl.dispose();
    houseCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }
}