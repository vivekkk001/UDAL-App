import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/pickup_log.dart';
import 'services/db_service.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the adapter for PickupLog
  Hive.registerAdapter(PickupLogAdapter());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UDAL Test DB',
      home: HomePage(),  
    );
  }
}
