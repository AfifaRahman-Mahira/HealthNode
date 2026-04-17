import 'package:flutter/material.dart';
import '../widgets/custom_design.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(hint: "Name", label: "Full Name", controller: nameController, icon: Icons.person),
            const SizedBox(height: 20),
            CustomButton(text: "REGISTER", onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}