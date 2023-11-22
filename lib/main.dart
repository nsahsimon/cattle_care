import 'package:cattle_care/home_screen.dart';
import 'package:cattle_care/ml_service.dart';
import 'package:cattle_care/select_feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_opencv_plugin/flutter_opencv_plugin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Opencv().initialize();
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
      home:  SelectAppFeature(),
    );
  }
}
