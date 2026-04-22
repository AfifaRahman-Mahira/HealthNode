import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // লগইন করার পর ড্যাশবোর্ড দেখানোর জন্য পেজ লিস্ট
  final List<Widget> _pages = [
    const PatientLandingPage(),
    const Center(
      child: Text(
        "Pharmacy Services - Access Granted",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    const Center(
      child: Text(
        "Profile Settings",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // চেক করা হচ্ছে ইউজার লগইন কি না
    final user = FirebaseAuth.instance.currentUser;
    bool isLoggedIn = user != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "HealthNode",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // যদি লগইন না থাকে তবেই লগইন বাটন দেখাবে
          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                icon: const Icon(Icons.login, size: 18),
                label: const Text("Login"),
              ),
            )
          else
            // লগইন থাকলে লগআউট বাটন দেখাবে
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                setState(() {}); // ইউআই রিফ্রেশ করবে
              },
            ),
          const Icon(Icons.notifications_none_rounded, color: Colors.black),
          const SizedBox(width: 15),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2193b0),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_pharmacy),
            label: "Pharmacy",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

class PatientLandingPage extends StatelessWidget {
  const PatientLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ইউজারের নাম নেওয়ার চেষ্টা
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user != null
        ? (user.email?.split('@')[0] ?? "User")
        : "Guest";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // মাহীরার সেই ডিজাইন কিন্তু নাম ডাইনামিক
          Text(
            "Hello, ${displayName.toUpperCase()}!",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Explore our health services today",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 25),

          // ইমারজেন্সি কার্ড
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFff416c), Color(0xFFff4b2b)],
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    "Emergency?\nFind medicine fast",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {},
                  child: const Text("Locate Now"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // গ্রিড কার্ডস
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildActionCard(Icons.search, "Pharmacy", Colors.blue),
              _buildActionCard(Icons.medication, "Medicines", Colors.orange),
              _buildActionCard(Icons.delivery_dining, "Rider", Colors.green),
              _buildActionCard(Icons.admin_panel_settings, "Admin", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12, // এখানে black12 দে, এরর চলে যাবে
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
