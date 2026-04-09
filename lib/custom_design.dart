import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final String? label; 
  final IconData? icon; 
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.label,
    this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          labelText: label ?? hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const CustomButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(onPressed: onPressed, child: Text(text)),
    );
  }
}