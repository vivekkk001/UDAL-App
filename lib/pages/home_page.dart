import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/pickup_log.dart';
import '../services/db_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_card.dart';
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final db = DBService();
  final workerCtrl = TextEditingController();
  final houseCtrl = TextEditingController();
  final amountCtrl = TextEditingController();
  final FocusNode _houseFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();
  XFile? _pickedImage;

  double? lat;
  double? lng;
  String? selectedPaymentMethod;
  String? paymentStatus;
  bool showPaymentOptions = false;
  bool showQRCode = false;
  bool showCashForm = false;
  bool _isLocationLoading = false;
  bool _isSaving = false;
  bool _paymentStatusChecked = false; // New state for payment status check

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    workerCtrl.text = widget.workerId;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _houseFocusNode.dispose();
    _amountFocusNode.dispose();
    _slideController.dispose();
    workerCtrl.dispose();
    houseCtrl.dispose();
    amountCtrl.dispose();
    super.dispose();
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.errorRed),
              const SizedBox(width: 8),
              const Text('Confirm Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Location services are disabled', StatusType.error);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied', StatusType.error);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
          'Location permission permanently denied',
          StatusType.error,
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

      _showSnackBar('📍 Location captured successfully!', StatusType.success);
    } catch (e) {
      _showSnackBar('Failed to get location: $e', StatusType.error);
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  // New method for checking payment status
  void _checkPaymentStatus() {
    setState(() {
      _paymentStatusChecked = true;
    });
    _showSnackBar('Payment Complete', StatusType.info);
  }

  void _showSnackBar(String message, StatusType type) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case StatusType.success:
        backgroundColor = AppTheme.successGreen;
        icon = Icons.check_circle;
        break;
      case StatusType.error:
        backgroundColor = AppTheme.errorRed;
        icon = Icons.error;
        break;
      case StatusType.warning:
        backgroundColor = AppTheme.accentGold;
        icon = Icons.warning;
        break;
      case StatusType.info:
        backgroundColor = AppTheme.primaryGreen;
        icon = Icons.info;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Payment Method',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'UPI Payment',
              icon: Icons.qr_code,
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  selectedPaymentMethod = 'UPI';
                  showQRCode = true;
                  showCashForm = false;
                });
                _slideController.forward();
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Cash Payment',
              icon: Icons.payments,
              onPressed: () {
                // Changed from isPrimary: false to default primary styling
                Navigator.pop(context);
                setState(() {
                  selectedPaymentMethod = 'CASH';
                  showCashForm = true;
                  showQRCode = false;
                });
                _slideController.forward();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
      _showSnackBar('📸 Photo captured successfully!', StatusType.success);
    }
  }

  void _savePickup() async {
    if (lat == null || lng == null) {
      _showSnackBar('Please capture location first', StatusType.error);
      return;
    }

    if (houseCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter Household ID', StatusType.error);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final log = PickupLog(
        workerId: workerCtrl.text,
        householdId: houseCtrl.text,
        photoUrl: _pickedImage?.path ?? '',
        timestamp: DateTime.now(),
        lat: lat!,
        lng: lng!,
        paymentMethod: selectedPaymentMethod ?? 'Pending',
        paymentStatus: paymentStatus ?? 'Pending Payment',
        paymentAmount: amountCtrl.text.isEmpty ? '0' : amountCtrl.text,
      );

      await db.insertPickup(log);

      _showSnackBar('✅ Pickup saved successfully!', StatusType.success);

      // Reset form
      _resetForm();
    } catch (e) {
      _showSnackBar('Failed to save pickup: $e', StatusType.error);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _resetForm() {
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
      _paymentStatusChecked = false; // Reset payment status check
    });
    _slideController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Pickup'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF20B2AA), // Light Sea Green
                Color(0xFF008B8B), // Dark Cyan
              ],
              stops: [0.0, 1.0],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.workerId,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF008B8B), // Dark Cyan - continues from AppBar
              Color(0xFF006666), // Darker Teal
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Pickup Entry',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Fill in the details below',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Basic Information Card
                      _buildBasicInfoCard(),

                      const SizedBox(height: 20),

                      // Location Card
                      _buildLocationCard(),

                      const SizedBox(height: 20),

                      // Photo Card
                      _buildPhotoCard(),

                      const SizedBox(height: 20),

                      // Payment Card
                      _buildPaymentCard(),

                      const SizedBox(height: 20),

                      // Payment Forms
                      if (showQRCode || showCashForm)
                        SlideTransition(
                          position: _slideAnimation,
                          child: showQRCode
                              ? _buildUPIForm()
                              : _buildCashForm(),
                        ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Worker ID',
              controller: workerCtrl,
              prefixIcon: Icons.badge,
              enabled: false,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Household ID',
              hintText: 'Enter household identifier',
              controller: houseCtrl,
              focusNode: _houseFocusNode,
              prefixIcon: Icons.home,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: _paymentStatusChecked
                  ? 'Payment Complete'
                  : 'Check Payment Status',
              icon: _paymentStatusChecked ? Icons.check_circle : Icons.payment,
              onPressed: _paymentStatusChecked ? null : _checkPaymentStatus,
              backgroundColor: _paymentStatusChecked
                  ? AppTheme.successGreen
                  : AppTheme.accentGold,
              textColor: _paymentStatusChecked ? Colors.white : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Location',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lat != null && lng != null)
              StatusCard(
                title: 'Location Captured',
                message:
                    'Lat: ${lat!.toStringAsFixed(6)}, Lng: ${lng!.toStringAsFixed(6)}',
                type: StatusType.success,
                icon: Icons.gps_fixed,
              )
            else
              StatusCard(
                title: 'Location Required',
                message:
                    'Tap the button below to capture your current location',
                type: StatusType.warning,
                icon: Icons.gps_not_fixed,
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: lat != null && lng != null
                  ? 'Update Location'
                  : 'Capture Location',
              icon: Icons.my_location,
              onPressed: _getLocation,
              isLoading: _isLocationLoading,
              backgroundColor: lat != null && lng != null
                  ? AppTheme.successGreen
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Photo Documentation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pickedImage != null)
              Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successGreen,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                          : Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatusCard(
                    title: 'Photo Captured',
                    message: 'Photo ready for upload',
                    type: StatusType.success,
                  ),
                ],
              )
            else
              StatusCard(
                title: 'Photo Required',
                message: 'Take a photo to document the pickup',
                type: StatusType.warning,
                icon: Icons.camera_alt,
              ),
            const SizedBox(height: 16),
            CustomButton(
              text: _pickedImage != null ? 'Retake Photo' : 'Take Photo',
              icon: Icons.camera_alt,
              onPressed: _takePhoto,
              backgroundColor: _pickedImage != null
                  ? AppTheme.successGreen
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Payment',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (paymentStatus != null)
              StatusCard(
                title: 'Payment Status',
                message: '$selectedPaymentMethod - $paymentStatus',
                type: paymentStatus == 'Payment Received'
                    ? StatusType.success
                    : StatusType.warning,
              )
            else
              StatusCard(
                title: 'Payment Pending',
                message: 'Select a payment method to proceed',
                type: StatusType.info,
                icon: Icons.payment,
              ),
            const SizedBox(height: 16),
            // Updated Select Payment Method button
            CustomButton(
              text: paymentStatus == 'Payment Received'
                  ? 'Payment Received'
                  : 'Select Payment Method',
              icon: paymentStatus == 'Payment Received'
                  ? Icons.check_circle
                  : Icons.payment,
              onPressed: paymentStatus == 'Payment Received'
                  ? null
                  : _showPaymentDialog, // Disable if payment received
              backgroundColor: paymentStatus == 'Payment Received'
                  ? AppTheme.successGreen
                  : null, // Green when payment received
              textColor: paymentStatus == 'Payment Received'
                  ? Colors.white
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          children: [
            Text(
              'UPI Payment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Amount',
              hintText: 'Enter payment amount',
              controller: amountCtrl,
              focusNode: _amountFocusNode,
              prefixIcon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              width: 180, // Reduced size
              height: 180, // Reduced size
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 80,
                    color: AppTheme.primaryGreen,
                  ), // Reduced size
                  const SizedBox(height: 8),
                  Text(
                    'QR Code Here',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Wait for customer to complete payment',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Received',
                    icon: Icons.check,
                    onPressed: () {
                      setState(() {
                        paymentStatus = 'Payment Received';
                        showQRCode = false;
                      });
                      _slideController.reverse();
                      _houseFocusNode.unfocus(); // Unfocus when done
                    },
                    backgroundColor: AppTheme.successGreen,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                Expanded(
                  child: CustomButton(
                    text: 'Pending',
                    icon: Icons.schedule,
                    onPressed: () {
                      setState(() {
                        paymentStatus = 'Pending Payment';
                        showQRCode = false;
                      });
                      _slideController.reverse();
                      _houseFocusNode.unfocus(); // Unfocus when done
                    },
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16), // Reduced padding
        child: Column(
          children: [
            Text(
              'Cash Payment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Amount',
              hintText: 'Enter payment amount',
              controller: amountCtrl,
              focusNode: _amountFocusNode,
              prefixIcon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Received',
                    icon: Icons.check,
                    onPressed: () {
                      setState(() {
                        paymentStatus = 'Payment Received';
                        showCashForm = false;
                      });
                      _slideController.reverse();
                      _houseFocusNode.unfocus(); // Unfocus when done
                    },
                    backgroundColor: AppTheme.successGreen,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8), // Reduced spacing
                Expanded(
                  child: CustomButton(
                    text: 'Pending',
                    icon: Icons.schedule,
                    onPressed: () {
                      setState(() {
                        paymentStatus = 'Pending Payment';
                        showCashForm = false;
                      });
                      _slideController.reverse();
                      _houseFocusNode.unfocus(); // Unfocus when done
                    },
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Save Pickup',
          icon: Icons.save,
          onPressed: _savePickup,
          isLoading: _isSaving,
          backgroundColor: AppTheme.successGreen,
          textColor: Colors.white,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'View All Pickups',
          icon: Icons.list,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncPage()),
            );
          },
          isPrimary: false,
        ),
      ],
    );
  }
}
