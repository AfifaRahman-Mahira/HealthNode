import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_design.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController(); 
  final phoneController = TextEditingController();
  final addressController = TextEditingController(); 
  
  // Specific fields for Pharmacy and Rider
  final pharmacyNameController = TextEditingController();
  final vehicleInfoController = TextEditingController();
  
  String selectedRole = 'Patient';
  String? selectedCity = 'Dhaka'; 
  bool isLoading = false;

  void register() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all mandatory fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Create User in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 2. Prepare Base User Data
      Map<String, dynamic> userData = {
        'uid': userCredential.user!.uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'role': selectedRole,
        'city': selectedCity,
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 3. Logic for Sub-Collections (SRS Requirement)
      if (selectedRole == 'Pharmacy') {
        userData['pharmacyName'] = pharmacyNameController.text.trim();
        await FirebaseFirestore.instance.collection('pharmacies').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'pharmacyName': pharmacyNameController.text.trim(),
          'city': selectedCity,
          'isVerified': false, // Admin verify korbe pore
        });
      } else if (selectedRole == 'Rider') {
        userData['vehicleInfo'] = vehicleInfoController.text.trim();
        await FirebaseFirestore.instance.collection('riders').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': nameController.text.trim(),
          'vehicleInfo': vehicleInfoController.text.trim(),
          'isOnline': true,
        });
      }

      // 4. Final entry in main Users collection
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Registration Failed"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0, 
        backgroundColor: Colors.transparent, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent), onPressed: () => Navigator.pop(context))
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              const SizedBox(height: 20),
              CustomTextField(controller: nameController, label: "Full Name", icon: Icons.person_outline),
              CustomTextField(controller: emailController, label: "Email Address", icon: Icons.alternate_email),
              CustomTextField(controller: passwordController, label: "Password", icon: Icons.lock_outline, isPassword: true),
              
              const SizedBox(height: 20),
              const Text("Register As", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: ['Patient', 'Pharmacy', 'Rider'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => selectedRole = v!),
              ),

              const SizedBox(height: 10),
              // Dynamic Fields
              if (selectedRole == 'Pharmacy') CustomTextField(controller: pharmacyNameController, label: "Pharmacy Name", icon: Icons.local_pharmacy),
              if (selectedRole == 'Rider') CustomTextField(controller: vehicleInfoController, label: "Vehicle Info (Bike/License)", icon: Icons.directions_bike),
              
              CustomTextField(controller: phoneController, label: "Phone Number", icon: Icons.phone),
              CustomTextField(controller: addressController, label: "Full Address", icon: Icons.home),
              
              const SizedBox(height: 40),
              isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : CustomButton(text: "REGISTER", onPressed: register),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}