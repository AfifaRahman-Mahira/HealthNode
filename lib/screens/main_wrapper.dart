import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'patient_home.dart';
import 'admin_dashboard.dart';
import 'pharmacy_home.dart';
import 'delivery_home.dart';
import 'login_screen.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthAndRole();
  }

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
            userRole = userDoc['role'].toString().toLowerCase();
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

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getHomeDashboard() {
    switch (userRole) {
      case "admin":
        return const AdminDashboard();
      case "pharmacist":
        return const PharmacyHome();
      case "rider":
        return const DeliveryHome();
      case "patient":
        return PatientLandingPage(onActionTap: _onTabChange);
      default:
        return _buildGuestWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        title: const Text("HealthNode",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          if (userRole != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false);
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

  Widget _buildGuestWelcome() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.medical_services_outlined,
              size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("Welcome to HealthNode",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text("Go to Login"),
          )
        ],
      ),
    );
  }
}

// --- পেশেন্ট ল্যান্ডিং পেজ ---
class PatientLandingPage extends StatelessWidget {
  final Function(int) onActionTap;
  const PatientLandingPage({super.key, required this.onActionTap});

  // --- নতুন ফাংশন: নিচ থেকে ওষুধের লিস্ট দেখানোর জন্য ---
  void _showMedicineBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 15),
                Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10))),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Available Medicines",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('medicines')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var meds = snapshot.data!.docs;
                      if (meds.isEmpty) {
                        return const Center(
                            child: Text("No medicines found in database."));
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: meds.length,
                        itemBuilder: (context, index) {
                          var data = meds[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.medication,
                                color: Colors.orange),
                            title: Text(data['name'] ?? "Unknown"),
                            subtitle: Text("${data['price'] ?? 0} BDT"),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2193b0)),
                              onPressed: () {
                                _placeOrder(context, data['name'],
                                    data['price'].toString());
                                Navigator.pop(context);
                              },
                              child: const Text("Order",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- নতুন ফাংশন: ফায়ারবেসে অর্ডার সেভ করার জন্য ---
  void _placeOrder(BuildContext context, String name, String price) {
    FirebaseFirestore.instance.collection('orders').add({
      'customerName': "Purovi Rahman",
      'medicineName': name,
      'price': price,
      'status': 'Assigned',
      'address': 'Gazipur, Tongi',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("$name Ordered! Rider will be notified."),
          backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String displayName = user?.email?.split('@')[0].toUpperCase() ?? "PATIENT";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hello, $displayName!",
              style:
                  const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Explore our health services today",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 25),
          _buildEmergencyBanner(() => onActionTap(1)),
          const SizedBox(height: 30),
          const Text("Quick Actions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(Icons.search, "Search Pharmacy", Colors.blue,
                  () => onActionTap(1)),
              // --- এই কার্ডে এখন শিট ওপেন হবে ---
              _buildActionCard(Icons.medication, "Medicines", Colors.orange,
                  () => _showMedicineBottomSheet(context)),
              _buildActionCard(
                  Icons.delivery_dining, "Track Rider", Colors.green, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          "Tracking feature is currently in development.")),
                );
              }),
              _buildActionCard(Icons.support_agent, "Support", Colors.red, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Support team is offline.")),
                );
              }),
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
        gradient: const LinearGradient(
            colors: [Color(0xFFff416c), Color(0xFFff4b2b)]),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text("Emergency?\nFind medicine fast",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: Colors.red),
            onPressed: onTap,
            child: const Text("Locate Now"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: color),
            const SizedBox(height: 10),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// --- প্রোফাইল পেজ ---
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String name = user?.email?.split('@')[0].toUpperCase() ?? "USER";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2193b0),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? "email@example.com",
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            const Divider(indent: 50, endIndent: 50),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text("My Orders"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text("Settings"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
