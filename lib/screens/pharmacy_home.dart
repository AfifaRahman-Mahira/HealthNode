import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmacyHome extends StatefulWidget {
  const PharmacyHome({super.key});
  @override
  State<PharmacyHome> createState() => _PharmacyHomeState();
}

class _PharmacyHomeState extends State<PharmacyHome> {
  final Color primaryColor = const Color(0xFF2193b0);
  final Color secondaryColor = const Color(0xFF6dd5ed);
  String searchQuery = "";
  String selectedCategory = "All";

  // ক্যাটাগরি লিস্ট
  final List<String> categories = [
    "All",
    "Fever",
    "Pain",
    "Gastric",
    "Antibiotic",
    "Vitamin"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [primaryColor, secondaryColor])),
        ),
        title: const Text("HealthNode Inventory",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildTopSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _buildMedicineList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Medicine",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // সার্চ বার ডিজাইন
  Widget _buildTopSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase().trim()),
        decoration: InputDecoration(
          hintText: "Search medicine...",
          prefixIcon: Icon(Icons.search, color: primaryColor),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ক্যাটাগরি ফিল্টার
  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              selectedColor: primaryColor,
              labelStyle:
                  TextStyle(color: isSelected ? Colors.white : Colors.black87),
              onSelected: (val) =>
                  setState(() => selectedCategory = categories[index]),
            ),
          );
        },
      ),
    );
  }

  // মেইন মেডিসিন লিস্ট (ফায়ারবেস কানেকশনসহ)
  Widget _buildMedicineList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No medicine found"));
        }

        // ফিল্টারিং লজিক (সার্চ এবং ক্যাটাগরি)
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          String cat = data['category'] ?? "All";
          return name.contains(searchQuery) &&
              (selectedCategory == "All" || cat == selectedCategory);
        }).toList();

        if (docs.isEmpty) return const Center(child: Text("No match found"));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            var docId = doc.id;

            // স্টক ডাটা সেফলি রিড করা
            int qty = 0;
            if (data['qty'] != null) {
              qty = (data['qty'] is int)
                  ? data['qty']
                  : (int.tryParse(data['qty'].toString()) ?? 0);
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              elevation: 2,
              child: ListTile(
                onTap: () => _showMedicineDetails(data),
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.medication, color: primaryColor),
                ),
                title: Text(data['name'] ?? "N/A",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Price: ৳${data['price']} | Stock: $qty",
                    style: TextStyle(
                        color: qty == 0 ? Colors.red : Colors.grey[700],
                        fontWeight:
                            qty == 0 ? FontWeight.bold : FontWeight.normal)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showForm(docId: docId, currentData: data)),
                    IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(docId)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ডিটেইলস প্যানেল
  void _showMedicineDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['name'] ?? "Details",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            const SizedBox(height: 10),
            _infoRow(Icons.category, "Category", data['category'] ?? "General"),
            _infoRow(Icons.money, "Price", "৳${data['price']}"),
            _infoRow(Icons.storage, "Current Stock", "${data['qty']} pcs"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20, color: primaryColor),
        const SizedBox(width: 10),
        Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(val),
      ]),
    );
  }

  // এড বা এডিট ফর্ম
  void _showForm({String? docId, Map<String, dynamic>? currentData}) {
    final nameC = TextEditingController(text: currentData?['name']);
    final qtyC = TextEditingController(text: currentData?['qty']?.toString());
    final priceC =
        TextEditingController(text: currentData?['price']?.toString());
    String tempCat = currentData?['category'] ?? "Fever";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(docId == null ? "Add New Medicine" : "Edit Record"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: nameC,
                  decoration:
                      const InputDecoration(labelText: "Medicine Name")),
              TextField(
                  controller: qtyC,
                  decoration: const InputDecoration(labelText: "Quantity"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: priceC,
                  decoration: const InputDecoration(labelText: "Price (TK)"),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 15),
              DropdownButton<String>(
                value: tempCat,
                isExpanded: true,
                items: categories
                    .where((c) => c != "All")
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setDialogState(() => tempCat = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'name': nameC.text,
                  'qty': int.tryParse(qtyC.text) ?? 0,
                  'price': double.tryParse(priceC.text) ?? 0.0,
                  'category': tempCat
                };
                if (docId == null) {
                  await FirebaseFirestore.instance
                      .collection('medicines')
                      .add(data);
                } else {
                  await FirebaseFirestore.instance
                      .collection('medicines')
                      .doc(docId)
                      .update(data);
                }
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  // ডিলিট কনফার্মেশন
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Medicine?"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('medicines')
                    .doc(id)
                    .delete();
                Navigator.pop(context);
              },
              child: const Text("Yes", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
