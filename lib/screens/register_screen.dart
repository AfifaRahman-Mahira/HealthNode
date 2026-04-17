import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // রোল সেভ করার জন্য
import '../custom_design.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  String selectedRole = 'Patient';
  final List<String> roles = ['Patient', 'Pharmacist', 'Rider', 'Admin'];
  bool isLoading = false;

  // রেজিস্ট্রেশন ফাংশন
  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // ১. ভ্যালিডেশন চেক
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showError("সবগুলো ঘর পূরণ করো!");
      return;
    }
    if (password.length < 6) {
      showError("পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে!");
      return;
    }
    if (!email.contains('@')) {
      showError("সঠিক ইমেইল এড্রেস দাও!");
      return;
    }

    setState(() => isLoading = true);

    try {
      // ২. ফায়ারবেস অথেন্টিকেশন
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // ৩. ফায়ারস্টোরে ইউজারের রোল সেভ করা
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'name': name,
            'email': email,
            'role': selectedRole,
            'createdAt': DateTime.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("রেজিস্ট্রেশন সফল হয়েছে!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // সফল হলে আগের পেজে ফিরে যাবে
      }
    } on FirebaseAuthException catch (e) {
      // ৪০০ এরর হলে এখানে মেসেজ আসবে
      showError(e.message ?? "ফায়ারবেস এরর হয়েছে");
    } catch (e) {
      showError("একটি অজানা ভুল হয়েছে: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
              hint: "Full Name",
              label: "Name",
              controller: nameController,
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              hint: "example@gmail.com",
              label: "Email",
              controller: emailController,
              icon: Icons.email,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              hint: "******",
              label: "Password",
              controller: passwordController,
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 20),

            // রোল সিলেক্টর
            DropdownButtonFormField<String>(
              value: selectedRole,
              decoration: const InputDecoration(
                labelText: "Select Role",
                border: OutlineInputBorder(),
              ),
              items: roles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) => setState(() => selectedRole = val!),
            ),

            const SizedBox(height: 30),

            isLoading
                ? const CircularProgressIndicator()
                : CustomButton(text: "REGISTER NOW", onPressed: registerUser),
          ],
        ),
      ),
    );
  }
}
