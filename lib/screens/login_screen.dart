import 'package:flutter/material.dart';
import '../widgets/custom_design.dart'; 
import '../services/auth_service.dart';
import 'main_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _login() async {
    String? role = await _authService.loginUser(emailController.text, passwordController.text);
    if (role != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainWrapper()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Failed!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.health_and_safety, size: 80, color: Color(0xFF2193b0)),
              const Text("HealthNode Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              CustomTextField(hint: "Email", controller: emailController, icon: Icons.email_outlined),
              const SizedBox(height: 15),
              CustomTextField(hint: "Password", controller: passwordController, icon: Icons.lock_outline, isPassword: true),
              const SizedBox(height: 30),
              CustomButton(text: "LOGIN", onPressed: _login),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Create New Account"),
              )
            ],
          ),
        ),
      ),
    );
  }
}