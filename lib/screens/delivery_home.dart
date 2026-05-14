import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rider_tracking_page.dart'; // নিশ্চিত কর এই ফাইলটি প্রজেক্টে আছে

class DeliveryHome extends StatefulWidget {
  const DeliveryHome({super.key});

  @override
  State<DeliveryHome> createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

 
  Future<void> _updateOrderStatus(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'Picked Up',
        'riderId': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order Picked Up Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RiderTrackingPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text("Rider Dashboard",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const Text("Ready for your next delivery?",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),

            // উপরের স্ট্যাটাস কার্ড (ব্যানার)
            _buildStatsCard(),

            const SizedBox(height: 25),
            const Text("Assigned Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('orders')
                    .where('status', isEqualTo: 'Assigned')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var orders = snapshot.data?.docs ?? [];

                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 80, color: Colors.blueGrey[100]),
                          const SizedBox(height: 10),
                          const Text("No tasks currently assigned",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];

                      // --- CRITICAL FIX: ডাটা ম্যাপে নিয়ে চেক করা যাতে লাল স্ক্রিন না আসে ---
                      Map<String, dynamic> data =
                          order.data() as Map<String, dynamic>;

                      String customerName = data.containsKey('customerName')
                          ? data['customerName']
                          : "Unknown Customer";

                      String address = data.containsKey('address')
                          ? data['address']
                          : "Gazipur, Tongi"; // ডিফল্ট অ্যাড্রেস

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long,
                                        size: 18, color: Color(0xFF2193b0)),
                                    const SizedBox(width: 8),
                                    Text("ID: #${order.id.substring(0, 8)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey)),
                                  ],
                                ),
                                _statusBadge("Assigned"),
                              ],
                            ),
                            const Divider(height: 25),
                            _infoRow(
                                Icons.person_outline, "Customer", customerName),
                            const SizedBox(height: 8),
                            _infoRow(
                                Icons.location_on_outlined, "Address", address),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _updateOrderStatus(order.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2193b0),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text("Accept & Pick Up",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // স্ট্যাটাস ব্যাজ ডিজাইন
  Widget _statusBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // কার্ডের ভেতর ইনফরমেশন রো
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text("$label: ",
            style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Expanded(
          child: Text(value,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ],
    );
  }

  // উপরের ব্লু গ্রেডিয়েন্ট কার্ড
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Task", style: TextStyle(color: Colors.white70)),
              Text("Active Orders", // এখানে তুই চাইলে orders.length দিতে পারিস
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(Icons.delivery_dining, color: Colors.white, size: 40),
        ],
      ),
    );
  }
}
