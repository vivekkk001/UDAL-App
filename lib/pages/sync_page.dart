import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../models/pickup_log.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_card.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  _SyncPageState createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> with TickerProviderStateMixin {
  final db = DBService();
  late Future<List<PickupLog>> _logsFuture;
  bool _isSyncing = false;
  bool _isDeleting = false;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _logsFuture = db.getAllPickups();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refreshLogs() async {
    _refreshController.forward();
    setState(() {
      _logsFuture = db.getAllPickups();
    });
    await Future.delayed(const Duration(milliseconds: 500));
    _refreshController.reset();
  }

  Future<void> _mockSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final box = await Hive.openBox<PickupLog>('pickup_logs');
      final unsynced = box.values.where((log) => !log.synced).toList();

      for (var log in unsynced) {
        try {
          // Simulate API call delay
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Mock address resolution
          log.address = 'Mock Address: ${log.lat.toStringAsFixed(4)}, ${log.lng.toStringAsFixed(4)}';
          log.synced = true;
          await log.save();
        } catch (e) {
          print("❗ Exception during sync: $e");
          log.address = 'Error Fetching Address';
          log.synced = true;
          await log.save();
        }
      }

      _showSnackBar('✅ Sync completed successfully!', StatusType.success);
      _refreshLogs();
    } catch (e) {
      _showSnackBar('❌ Sync failed: $e', StatusType.error);
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _deleteSynced() async {
    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Delete Synced Records'),
          ],
        ),
        content: const Text(
          'This will permanently delete all synced pickup records. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await db.deleteSynced();
      _showSnackBar('🗑️ Synced records deleted successfully', StatusType.success);
      _refreshLogs();
    } catch (e) {
      _showSnackBar('❌ Failed to delete records: $e', StatusType.error);
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Records'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          RotationTransition(
            turns: _refreshController,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshLogs,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.backgroundLight,
            ],
            stops: [0.0, 0.2],
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
                      Icons.sync,
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
                          'Pickup Records',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage and sync your data',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Sync Now',
                      icon: Icons.cloud_upload,
                      onPressed: _mockSync,
                      isLoading: _isSyncing,
                      backgroundColor: AppTheme.accentGold,
                      textColor: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Delete Synced',
                      icon: Icons.delete_sweep,
                      onPressed: _deleteSynced,
                      isLoading: _isDeleting,
                      backgroundColor: AppTheme.errorRed,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Records List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: FutureBuilder<List<PickupLog>>(
                  future: _logsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: StatusCard(
                            title: 'Error Loading Records',
                            message: 'Failed to load pickup records: ${snapshot.error}',
                            type: StatusType.error,
                          ),
                        ),
                      );
                    }

                    final logs = snapshot.data!;
                    
                    if (logs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Pickup Records',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start by adding your first pickup record',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Summary Card
                        Container(
                          margin: const EdgeInsets.all(24),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryItem(
                                      'Total Records',
                                      logs.length.toString(),
                                      Icons.list_alt,
                                      AppTheme.primaryGreen,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppTheme.borderGrey,
                                  ),
                                  Expanded(
                                    child: _buildSummaryItem(
                                      'Synced',
                                      logs.where((log) => log.synced).length.toString(),
                                      Icons.cloud_done,
                                      AppTheme.successGreen,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppTheme.borderGrey,
                                  ),
                                  Expanded(
                                    child: _buildSummaryItem(
                                      'Pending',
                                      logs.where((log) => !log.synced).length.toString(),
                                      Icons.cloud_off,
                                      AppTheme.accentGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Records List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: logs.length,
                            itemBuilder: (context, index) {
                              final log = logs[index];
                              return _buildPickupCard(log);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPickupCard(PickupLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: log.synced 
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    log.synced ? Icons.cloud_done : Icons.cloud_off,
                    color: log.synced ? AppTheme.successGreen : AppTheme.accentGold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Household: ${log.householdId}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Worker: ${log.workerId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: log.synced 
                        ? AppTheme.successGreen
                        : AppTheme.accentGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    log.synced ? 'Synced' : 'Pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Details Grid
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.access_time,
                    'Date & Time',
                    '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} at ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.location_on,
                    'Location',
                    log.address ?? 'Lat: ${log.lat.toStringAsFixed(4)}, Lng: ${log.lng.toStringAsFixed(4)}',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.payment,
                    'Payment',
                    '${log.paymentMethod ?? 'N/A'} - ${log.paymentStatus ?? 'Pending'}',
                  ),
                  if (log.paymentAmount != null && log.paymentAmount!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.currency_rupee,
                      'Amount',
                      '₹${log.paymentAmount}',
                    ),
                  ],
                  if (log.photoUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.camera_alt,
                      'Photo',
                      'Photo attached',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}