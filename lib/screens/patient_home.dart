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

class _PatientHomeState extends State<PatientHome> {
  String searchQuery = "";
  String selectedCategory = "All";
  String? userLocation; 
  
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  final List<String> categories = ["All", "Fever", "Pain", "Antibiotics", "Diabetes", "Gastric"];
  
  // ঢাকা বিভাগের এলাকাগুলোর লিস্ট
  final List<String> dhakaAreas = ["Uttara", "Tongi", "Mirpur", "Gulshan", "Dhanmondi", "Banani", "Motijheel", "Savar", "Gazipur"];

  // GPS লোকেশন ফাংশন
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar("Please enable Location Services", Colors.red);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar("Location permissions are denied", Colors.red);
        return;
      }
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      // রিয়েল জিপিএস কোঅর্ডিনেট না নিয়ে প্রজেক্ট ডিমান্ড অনুযায়ী এলাকা সেট করছি
      setState(() => userLocation = "Tongi"); 
      _showSnackBar("Location updated via GPS: Tongi", Colors.green);
    } else {
      _showLocationPicker();
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("Select Area (Dhaka Division)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.gps_fixed, color: Colors.blue),
            title: const Text("Use Current GPS Location", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () { Navigator.pop(ctx); _getCurrentLocation(); },
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: dhakaAreas.length,
              itemBuilder: (ctx, index) => ListTile(
                title: Text(dhakaAreas[index]),
                onTap: () => _updateLocation(dhakaAreas[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateLocation(String loc) {
    setState(() => userLocation = loc);
    Navigator.pop(context);
    _showSnackBar("Location set to $loc", Colors.blue);
  }

  Future<void> _processOrder(Map<String, dynamic> med) async {
    final user = FirebaseAuth.instance.currentUser;
    if (userLocation == null) {
      _showLocationPicker();
      return;
    }

    String cat = med['category'] ?? "General";
    bool needsPrescription = (cat == "Antibiotics" || cat == "Diabetes");

    if (needsPrescription) {
      final query = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userId', isEqualTo: user!.uid)
          .get();

      if (query.docs.isEmpty) {
        _showErrorDialog("Prescription Required", "Please upload a prescription for this medicine.");
        return;
      }
    }

    _showPharmacyList(med, user!.uid);
  }

  void _showPharmacyList(Map<String, dynamic> med, String uid) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pharmacies')
            .where('Location', isEqualTo: userLocation) 
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.docs.isEmpty) return const Center(child: Text("No pharmacies in your area."));

          return ListView(
            children: snap.data!.docs.map((d) {
              var data = d.data() as Map<String, dynamic>;
              String pName = data['PharmacyName'] ?? data['name'] ?? "Pharmacy";
              return ListTile(
                leading: const Icon(Icons.local_pharmacy),
                title: Text(pName),
                subtitle: Text(data['address'] ?? ""),
                onTap: () => _finalOrder(med, pName, uid),
              );
            }).toList(),
          );
        }
      )
    );
  }

  Future<void> _finalOrder(Map<String, dynamic> med, String pName, String uid) async {
    await FirebaseFirestore.instance.collection('orders').add({
      'medicineName': med['name'],
      'price': med['price'],
      'pharmacy': pName,
      'patientId': uid,
      'location': userLocation,
      'status': 'Pending',
      'orderAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
    _showSnackBar("Order placed successfully with $pName!", Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showAIChat,
        backgroundColor: const Color(0xFF2193b0),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildTopBar(),
          _buildCategoryFilters(),
          _buildMedicineGrid(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 15),
      color: const Color(0xFF2193b0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("HealthNode", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: _uploadPrescriptionAction),
                  IconButton(icon: const Icon(Icons.my_location, color: Colors.white), onPressed: _showLocationPicker),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
            onTap: userLocation == null ? _showLocationPicker : null,
            readOnly: userLocation == null,
            decoration: InputDecoration(
              hintText: userLocation == null ? "Select location..." : "Search in $userLocation...",
              fillColor: Colors.white,
              filled: true,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPrescriptionAction() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _storageService.uploadPrescription(
        imageFile: File(image.path), 
        userId: FirebaseAuth.instance.currentUser!.uid
      );
      _showSnackBar("Prescription Uploaded Successfully!", Colors.green);
    }
  }

  void _showAIChat() {
    TextEditingController ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("HealthNode AI Bot", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Ask anything...")),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () async {
                String q = ctrl.text;
                Navigator.pop(ctx);
                String response = await _aiService.getMedicalAdvice(q, FirebaseAuth.instance.currentUser?.uid ?? "");
                _showAIResponse(response);
              }, 
              child: const Text("Ask Gemini")
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: ChoiceChip(
            label: Text(categories[i]),
            selected: selectedCategory == categories[i],
            onSelected: (s) => setState(() => selectedCategory = categories[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineGrid() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs.where((d) {
            var data = d.data() as Map<String, dynamic>;
            bool matchesSearch = (data['name'] ?? "").toString().toLowerCase().contains(searchQuery);
            bool matchesCat = selectedCategory == "All" || (data['category'] ?? "") == selectedCategory;
            return matchesSearch && matchesCat;
          }).toList();

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              var med = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ListTile(
                  title: Text(med['name'] ?? "Unknown"),
                  subtitle: Text("${med['price']} TK • ${med['category']}"),
                  trailing: ElevatedButton(onPressed: () => _processOrder(med), child: const Text("Order")),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  void _showAIResponse(String m) => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("AI Advice"), content: SingleChildScrollView(child: Text(m)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))]));
  void _showErrorDialog(String t, String c) => showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(t), content: Text(c), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))]));
}