import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'patient_home.dart'; 
import 'admin_dashboard.dart';    // Added
import 'pharmacy_home.dart';     // Added
import 'delivery_home.dart';     // Added

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  String? userRole; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();
  }

  // Fetch user role from Firestore to determine dashboard layout
  Future<void> _checkAuthAndRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          setState(() {
            userRole = userDoc['role']; 
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Handles navigation between BottomNavBar tabs
  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Returns the correct Home view based on the user's role
  Widget _getHomeDashboard() {
    if (userRole == "Admin") {
      return const AdminDashboard(); // Connected to AdminDashboard file
    } else if (userRole == "Pharmacist") {
      return const PharmacyHome();   // Connected to PharmacyHome file
    } else if (userRole == "Rider") {
      return const DeliveryHome();   // Connected to DeliveryHome file
    } else if (userRole == "Patient") {
      return PatientLandingPage(onActionTap: _onTabChange);
    } else {
      return _buildGuestWelcome();
    }
  }

  Widget _buildGuestWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Welcome to HealthNode", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Text("Please login to access specialized services.", textAlign: TextAlign.center),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text("Go to Login"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Logic to switch between Home, Search, and Profile
    Widget currentBody;
    if (_currentIndex == 0) {
      currentBody = _getHomeDashboard();
    } else if (_currentIndex == 1) {
      currentBody = const PatientHome(); 
    } else {
      currentBody = const ProfilePage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("HealthNode", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          if (userRole != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  setState(() { 
                    userRole = null; 
                    _currentIndex = 0; 
                  });
                }
              },
            ),
        ],
      ),
      body: currentBody,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2193b0),
        onTap: _onTabChange,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// --- Patient Dashboard Component ---
class PatientLandingPage extends StatelessWidget {
  final Function(int) onActionTap;
  const PatientLandingPage({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.email?.split('@')[0].toUpperCase() ?? "PATIENT";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello, $displayName!", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Explore our health services today", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          
          _buildEmergencyBanner(() => onActionTap(1)),
          
          const SizedBox(height: 30),
          const Text("Quick Actions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(Icons.search, "Search Pharmacy", Colors.blue, () => onActionTap(1)),
              _buildActionCard(Icons.medication, "Medicines", Colors.orange, () => onActionTap(1)),
              _buildActionCard(Icons.delivery_dining, "Track Rider", Colors.green, () {}),
              _buildActionCard(Icons.admin_panel_settings, "Support", Colors.red, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner(VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFff416c), Color(0xFFff4b2b)]),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text("Emergency?\nFind medicine fast", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
            onPressed: onTap, 
            child: const Text("Locate Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// --- Profile Page ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50, 
            backgroundColor: Color(0xFF2193b0), 
            child: Icon(Icons.person, size: 50, color: Colors.white)
          ),
          const SizedBox(height: 20),
          Text(user?.email ?? "Guest User", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          const Text("Account Status: Active", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}