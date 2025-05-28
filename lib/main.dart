import 'package:fire_prevent_system/pages/dashboard_page.dart';
import 'package:fire_prevent_system/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const MyApp());
}

// void main() {
//   final raw = '2025-05-28T21_47_43';
//   try {
//     final time = DateFormat("yyyy-MM-dd'T'HH_mm_ss").parse(raw);
//     print('✅ Parsed successfully: $time');
//   } catch (e) {
//     print('❌ Error: $e');
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire Alert System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: DashboardPage(),
    );
  }
}
