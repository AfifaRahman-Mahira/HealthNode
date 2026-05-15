import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String searchQuery = "";
  String selectedCategory = "All";
  String? userLocation;
  
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  final List<String> categories = ["All", "Fever", "Pain", "Antibiotics", "Diabetes", "Gastric"];
  final List<String> bdDivisions = ["Dhaka", "Chattogram", "Rajshahi", "Khulna", "Barishal", "Sylhet", "Rangpur", "Mymensingh"];

  // Animation Controllers
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  // --- Logic: Sync and Order Process ---
  Future<void> _processOrder(Map<String, dynamic> med) async {
    final user = FirebaseAuth.instance.currentUser;
    if (userLocation == null) {
      _showLocationPicker();
      return;
    }

    // Check if medication still exists in the master list
    final medCheck = await FirebaseFirestore.instance.collection('medicines').where('name', isEqualTo: med['name']).get();
    if (medCheck.docs.isEmpty) {
      _showSnackBar("This medicine is no longer available in stock!", Colors.red);
      return;
    }

    String cat = med['category'] ?? "General";
    if (cat == "Antibiotics" || cat == "Diabetes") {
      final query = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userId', isEqualTo: user!.uid)
          .get();

      if (query.docs.isEmpty) {
        _showErrorDialog("Prescription Required", "Please upload a prescription for $cat.");
        return;
      }
    }
    _showPharmacyList(med, user!.uid);
  }

  void _showPharmacyList(Map<String, dynamic> med, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pharmacies').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const LinearProgressIndicator();
          return Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Select Nearby Pharmacy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: ListView(
                  children: snap.data!.docs.map((d) {
                    var data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFe0f2f1), child: Icon(Icons.local_pharmacy, color: Color(0xFF2193b0))),
                      title: Text(data['PharmacyName'] ?? "General Pharmacy"),
                      subtitle: Text(data['Location'] ?? "Nearby"),
                      onTap: () => _confirmFinalOrder(med, data['PharmacyName'], uid),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        }
      )
    );
  }

  Future<void> _confirmFinalOrder(Map<String, dynamic> med, String pName, String uid) async {
    await FirebaseFirestore.instance.collection('orders').add({
      'medicineName': med['name'],
      'price': med['price'],
      'pharmacy': pName,
      'patientId': uid,
      'location': userLocation,
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    _showSnackBar("Order for ${med['name']} placed!", Colors.green);
  }

  // --- UI Builders ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF2193b0),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Store"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: "Orders"),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: _showAIChat,
        backgroundColor: const Color(0xFF2193b0),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text("AI Help", style: TextStyle(color: Colors.white)),
      ) : null,
      body: _selectedIndex == 0 ? _buildHomeBody() : _buildOrdersBody(),
    );
  }

  Widget _buildHomeBody() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverToBoxAdapter(child: _buildCategoryFilters()),
        _buildMedicineGrid(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome to", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text("HealthNode Store", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                onPressed: _showLocationPicker,
                icon: const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
              )
            ],
          ),
          const SizedBox(height: 25),
          TextField(
            onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: userLocation == null ? "Find medicine in your area..." : "Searching in $userLocation",
              fillColor: Colors.white,
              filled: true,
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2193b0)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersBody() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      children: [
        const SizedBox(height: 60),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text("Live Order Status", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('patientId', isEqualTo: uid).snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                itemCount: snap.data!.docs.length,
                itemBuilder: (ctx, i) {
                  var order = snap.data!.docs[i].data() as Map<String, dynamic>;
                  String medName = order['medicineName'];
                  
                  // SYNC LOGIC: Check if medicine is deleted from main list
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('medicines').where('name', isEqualTo: medName).snapshots(),
                    builder: (context, medSnap) {
                      bool isDeleted = medSnap.hasData && medSnap.data!.docs.isEmpty;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: isDeleted ? Border.all(color: Colors.redAccent, width: 1) : null,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isDeleted ? Colors.red[50] : Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                            child: Icon(isDeleted ? Icons.warning_amber_rounded : Icons.receipt_long, color: isDeleted ? Colors.red : Colors.blue),
                          ),
                          title: Text(medName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Shop: ${order['pharmacy']}"),
                              Text("Status: ${order['status']}", style: TextStyle(color: isDeleted ? Colors.red : Colors.green, fontWeight: FontWeight.w600)),
                              if (isDeleted) const Text("⚠️ Master medicine list updated. Contact Pharmacy.", style: TextStyle(fontSize: 10, color: Colors.red)),
                            ],
                          ),
                          trailing: Text("${order['price']} ৳", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2193b0))),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No active orders found", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: categories.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(categories[i]),
            selectedColor: const Color(0xFF2193b0),
            labelStyle: TextStyle(color: selectedCategory == categories[i] ? Colors.white : Colors.black87),
            selected: selectedCategory == categories[i],
            onSelected: (s) => setState(() => selectedCategory = categories[i]),
            backgroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        var docs = snapshot.data!.docs.where((d) {
          var data = d.data() as Map<String, dynamic>;
          bool matchesSearch = (data['name'] ?? "").toString().toLowerCase().contains(searchQuery);
          bool matchesCat = selectedCategory == "All" || (data['category'] ?? "") == selectedCategory;
          return matchesSearch && matchesCat;
        }).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                var med = docs[i].data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.medication_liquid_rounded, color: Color(0xFF2193b0), size: 30),
                    ),
                    title: Text(med['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    subtitle: Text("${med['price']} TK • ${med['category']}"),
                    trailing: IconButton.filled(
                      onPressed: () => _processOrder(med),
                      icon: const Icon(Icons.add_shopping_cart_rounded),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF2193b0)),
                    ),
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  // --- Helper Methods ---
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Select Delivery Area", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 15),
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.blue),
              title: const Text("Use Live GPS"),
              onTap: () { Navigator.pop(ctx); _getCurrentLocation(); },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: bdDivisions.length,
                itemBuilder: (ctx, index) => ListTile(
                  title: Text(bdDivisions[index]),
                  onTap: () {
                    setState(() => userLocation = bdDivisions[index]);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() => userLocation = "GPS: ${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}");
    _showSnackBar("GPS Updated", Colors.blue);
  }

  void _showAIChat() {
    TextEditingController ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2193b0), size: 50),
            const SizedBox(height: 15),
            const Text("HealthNode AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: ctrl, decoration: InputDecoration(hintText: "Enter symptom or medicine name...", border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2193b0), minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                String q = ctrl.text; Navigator.pop(ctx);
                String res = await _aiService.getMedicalAdvice(q, FirebaseAuth.instance.currentUser!.uid);
                _showAIResponse(res);
              },
              child: const Text("Ask AI", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));
  void _showAIResponse(String m) => showDialog(context: context, builder: (ctx) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text("AI Advice"), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
  void _showErrorDialog(String t, String c) => showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(t), content: Text(c), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
}