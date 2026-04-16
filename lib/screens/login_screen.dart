import 'package:flutter/material.dart';
import '../widgets/custom_design.dart'; 
import 'main_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.health_and_safety_rounded, size: 80, color: Color(0xFF2193b0)),
              const SizedBox(height: 20),
              const Text(
                "HealthNode Login", 
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))
              ),
              const SizedBox(height: 40),
              CustomTextField(
                hint: "Email", 
                label: "Email Address", 
                controller: emailController, 
                icon: Icons.email_outlined
              ),
              const SizedBox(height: 15),
              CustomTextField(
                hint: "Password", 
                label: "Password", 
                controller: passwordController, 
                icon: Icons.lock_outline, 
                isPassword: true
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: "LOGIN", 
                onPressed: () {
                  // Basic check before navigation
                  if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (_) => const MainWrapper())
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter your credentials")),
                    );
                  }
                }
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (_) => const RegisterScreen())
                ),
                child: const Text("Create New Account", style: TextStyle(color: Color(0xFF2193b0))),
              )
            ],
          ),
        ),
      ),
    );
  }
}