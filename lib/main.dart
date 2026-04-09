import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase শুরু করার জন্য
  runApp(const HealthNode());
}

class HealthNode extends StatelessWidget {
  const HealthNode({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthNode',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Poppins', // SRS অনুযায়ী প্রফেশনাল লুকের জন্য
      ),
      home: const SplashScreen(),
    );
  }
}