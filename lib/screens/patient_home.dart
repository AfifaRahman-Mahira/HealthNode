import 'package:flutter/material.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Home"),
        backgroundColor: const Color(0xFF2193b0),
      ),
      body: const Center(child: Text("Welcome to Patient Dashboard")),
    );
  }
}
