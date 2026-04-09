import 'package:flutter/material.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("HealthNode", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.black)),
        ],
      ),
      body: _currentIndex == 0 ? const PatientLandingPage() : const Center(child: Text("Coming Soon")),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF2193b0),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: "Pharmacy"),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hello, Afifa!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("How can we help you today?", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          
          // Emergency Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFFff416c), Color(0xFFff4b2b)]),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Emergency?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text("Find the nearest medicine fast", style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                  onPressed: () {},
                  child: const Text("Locate Now"),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          // Grid of Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildActionCard(Icons.search, "Find Pharmacy", Colors.blue),
              _buildActionCard(Icons.medical_services, "Medicines", Colors.orange),
              _buildActionCard(Icons.history, "Order History", Colors.green),
              _buildActionCard(Icons.chat_bubble, "AI Assistant", Colors.purple),
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
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}