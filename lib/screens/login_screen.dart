import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../custom_design.dart';
import 'main_wrapper.dart'; // লগইন হলে যেখানে যাবে
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // কন্ট্রোলারগুলো
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  // লগইন ফাংশন
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("সবগুলো ঘর পূরণ করুন")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ফায়ারবেস লগইন কমান্ড
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print("Login Successful!");

      // লগইন সফল হলে পরবর্তী স্ক্রিনে যাওয়া
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "লগইন ব্যর্থ হয়েছে";

      if (e.code == 'user-not-found') {
        errorMessage = "এই ইমেইলে কোনো ইউজার নেই।";
      } else if (e.code == 'wrong-password') {
        errorMessage = "পাসওয়ার্ড ভুল হয়েছে।";
      } else if (e.code == 'invalid-credential') {
        errorMessage = "ইমেইল বা পাসওয়ার্ড সঠিক নয়।";
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(
                Icons.health_and_safety_rounded,
                size: 80,
                color: Color(0xFF2193b0),
              ),
              const SizedBox(height: 20),
              const Text(
                "HealthNode Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              const SizedBox(height: 40),

              // ইমেইল ইনপুট
              CustomTextField(
                hint: "Email",
                label: "Email Address",
                controller: emailController,
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),

              // পাসওয়ার্ড ইনপুট
              CustomTextField(
                hint: "Password",
                label: "Password",
                controller: passwordController,
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),

              // লগইন বাটন
              isLoading
                  ? const CircularProgressIndicator()
                  : CustomButton(text: "LOGIN", onPressed: loginUser),

              const SizedBox(height: 10),

              // রেজিস্ট্রেশন লিঙ্ক
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
                child: const Text(
                  "Create New Account",
                  style: TextStyle(color: Color(0xFF2193b0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
