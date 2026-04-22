import 'package:flutter/material.dart';

class PharmacyHome extends StatelessWidget {
  const PharmacyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacy Home"),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text("Welcome to Pharmacy Owner Dashboard"),
      ),
    );
  }
}