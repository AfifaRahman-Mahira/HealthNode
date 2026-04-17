import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        // আমি তোমার স্ক্রিনশট দেখে একদম হুবহু টাইপ করে দিয়েছি
        apiKey: "AIzaSyBWHFX56pyZCdw7xYLNv4i1hyn3JpfWKmI",
        authDomain: "healthnode-1a0cc.firebaseapp.com",
        projectId: "healthnode-1a0cc",
        storageBucket: "healthnode-1a0cc.firebasestorage.app",
        messagingSenderId: "897904520286",
        appId: "1:897904520286:web:f7cbbdf6278260fc6bd8cf",
        measurementId: "G-R8YV78JX17",
      ),
    );
    print("Firebase connected successfully!");
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthNode',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
