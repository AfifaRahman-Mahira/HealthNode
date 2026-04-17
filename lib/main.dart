import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY", 
        appId: "YOUR_APP_ID", 
        messagingSenderId: "897904520286",
        projectId: "healthnode-1a0cc",
        storageBucket: "healthnode-1a0cc.firebasestorage.app",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primaryColor: const Color(0xFF2193b0)),
      home: const SplashScreen(), 
    );
  }
}