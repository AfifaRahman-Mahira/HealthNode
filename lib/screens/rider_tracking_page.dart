import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderTrackingPage extends StatelessWidget {
  const RiderTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Order Status")),
      body: StreamBuilder<QuerySnapshot>(
        // লেটেস্ট অর্ডারটি ট্র্যাক করার জন্য
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active orders found."));
          }

          var order = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          String status = order['status'] ?? 'Assigned';

          return Column(
            children: [
              // ম্যাপ সিমুলেশন
              Container(
                height: 250,
                width: double.infinity,
                color: Colors.blue[50],
                child: const Center(
                    child:
                        Icon(Icons.map_rounded, size: 80, color: Colors.blue)),
              ),
              const SizedBox(height: 20),
              // স্ট্যাটাস ট্র্যাকিং লজিক (Week 7)
              _step(
                  "Order Assigned",
                  status == 'Assigned' ||
                      status == 'Picked Up' ||
                      status == 'In Transit' ||
                      status == 'Delivered'),
              _step(
                  "Rider Picked Up",
                  status == 'Picked Up' ||
                      status == 'In Transit' ||
                      status == 'Delivered'),
              _step("In Transit",
                  status == 'In Transit' || status == 'Delivered'),
              _step("Delivered", status == 'Delivered'),
            ],
          );
        },
      ),
    );
  }

  Widget _step(String title, bool isDone) {
    return ListTile(
      leading: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? Colors.green : Colors.grey),
      title: Text(title,
          style: TextStyle(color: isDone ? Colors.black : Colors.grey)),
    );
  }
}
