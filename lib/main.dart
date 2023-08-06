import 'package:cattle_care/home_screen.dart';
import 'package:cattle_care/ml_service.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MLService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cattle Care',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home:  HomeScreen(),
    );
  }
}
