import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final AuthService _authService = AuthService();
  
  String selectedRole = 'Patient';
  final List<String> roles = ['Patient', 'Pharmacist', 'Rider', 'Admin'];
  bool isLoading = false;

  Future<void> login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      if (!mounted) return; // async gap check
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields!")),
      );
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      var userModel = await _authService.loginUser(
        _email.text.trim(), 
        _pass.text.trim(),
        selectedRole,
      );

      if (!mounted) return; // async gap check

      if (userModel != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainWrapper()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Failed: Role mismatched or invalid credentials."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return; // async gap check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Card(
              // Updated deprecated withOpacity to withValues
              color: Colors.white.withValues(alpha: 0.1), 
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_person,
                      size: 60,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _email,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.email, color: Colors.cyanAccent),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.lock, color: Colors.cyanAccent),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    Theme(
                      data: Theme.of(context).copyWith(canvasColor: const Color(0xFF2C5364)),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Select Role",
                          labelStyle: TextStyle(color: Colors.cyanAccent),
                          border: OutlineInputBorder(),
                        ),
                        items: roles.map((r) => DropdownMenuItem(
                          value: r, 
                          child: Text(r, style: const TextStyle(color: Colors.white))
                        )).toList(),
                        onChanged: (v) => setState(() => selectedRole = v!),
                      ),
                    ),

                    const SizedBox(height: 30),
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.cyanAccent)
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: login,
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Register Now",
                        style: TextStyle(color: Colors.cyanAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}