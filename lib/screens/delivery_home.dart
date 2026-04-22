import 'package:flutter/material.dart';

class DeliveryHome extends StatelessWidget {
  const DeliveryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delivery Home"),
        backgroundColor: Colors.orange,
      ),
      body: const Center(
        child: Text("Welcome to Delivery Dashboard"),
      ),
    );
  }
}