import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientHome extends StatefulWidget {
  const PatientHome({super.key});

  @override
  State<PatientHome> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHome> {
  String searchQuery = "";
  String selectedCategory = "All";

  // Categories list for filtering
  final List<String> categories = [
    "All",
    "Fever",
    "Pain",
    "Gastric",
    "Antibiotic"
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header & Category Filter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF2193b0),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Functional Search Bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search for Napa, Sergel...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Category Selection Chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(categories[index]),
                        selected: selectedCategory == categories[index],
                        onSelected: (selected) {
                          setState(() {
                            selectedCategory = categories[index];
                          });
                        },
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: selectedCategory == categories[index]
                              ? const Color(0xFF2193b0)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Real-time Firestore List (Fixed Error Logic)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('medicines').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("No medicines found in database."));
              }

              // ফিক্সড ফিল্টারিং লজিক (Error-Safe)
              var medicineDocs = snapshot.data!.docs.where((doc) {
                // ডাটা ম্যাপে কনভার্ট করা হচ্ছে যেন ফিল্ড না থাকলে ক্রাশ না করে
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                // চেক করছি ফিল্ড আছে কি না, না থাকলে ডিফল্ট ভ্যালু
                String name = data.containsKey('name')
                    ? data['name'].toString().toLowerCase()
                    : "";
                String category = data.containsKey('category')
                    ? data['category'].toString()
                    : "General";

                bool matchesSearch = name.contains(searchQuery);
                bool matchesCategory =
                    selectedCategory == "All" || category == selectedCategory;

                return matchesSearch && matchesCategory;
              }).toList();

              if (medicineDocs.isEmpty) {
                return const Center(
                    child: Text("No matching medicines found."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: medicineDocs.length,
                itemBuilder: (context, index) {
                  // ডাটা রিড করার সময় Null Safety চেক
                  Map<String, dynamic> medicine =
                      medicineDocs[index].data() as Map<String, dynamic>;

                  String medName = medicine['name'] ?? "Unknown";
                  String medCat = medicine['category'] ?? "General";
                  var medPrice = medicine['price'] ?? "0";
                  var medStock = medicine['stock'] ?? 0;

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication_liquid,
                            color: Color(0xFF2193b0), size: 30),
                      ),
                      title: Text(
                        medName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Category: $medCat"),
                          const SizedBox(height: 4),
                          Text(
                            "Stock: $medStock",
                            style: TextStyle(
                              color: (medStock is int && medStock > 0)
                                  ? Colors.grey
                                  : Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        "$medPrice TK",
                        style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
