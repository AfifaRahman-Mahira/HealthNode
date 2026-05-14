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

  // ক্যাটাগরি লিস্ট
  final List<String> categories = [
    "All",
    "Fever",
    "Pain",
    "Antibiotics",
    "Diabetes"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // --- সার্চ বার সেকশন ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for Napa, Sergel or stock qty...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // --- ক্যাটাগরি চিপস ---
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: selectedCategory == categories[index],
                    onSelected: (bool selected) {
                      setState(() {
                        selectedCategory = categories[index];
                      });
                    },
                    selectedColor: const Color(0xFF2193b0),
                    labelStyle: TextStyle(
                      color: selectedCategory == categories[index]
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),

          // --- মেডিসিন লিস্ট (StreamBuilder) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('medicines')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text("Error loading data"));
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                // --- সার্চ এবং ফিল্টারিং লজিক ---
                var medicineDocs = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;

                  String name = (data['name'] ?? "").toString().toLowerCase();
                  String category = (data['category'] ?? "General").toString();
                  // ডাটাবেজে ফিল্ডের নাম 'qty' অথবা 'stock' যাই হোক সেটি হ্যান্ডেল করবে
                  String stock =
                      (data['qty'] ?? data['stock'] ?? "0").toString();

                  // লজিক: নাম অথবা স্টকের পরিমাণের সাথে সার্চ কিউরি মিললে দেখাবে
                  bool matchesSearch =
                      name.contains(searchQuery) || stock == searchQuery;
                  bool matchesCategory =
                      selectedCategory == "All" || category == selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (medicineDocs.isEmpty) {
                  return const Center(child: Text("No medicine found!"));
                }

                return ListView.builder(
                  itemCount: medicineDocs.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    var medicine =
                        medicineDocs[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE1F5FE),
                          child:
                              Icon(Icons.medication, color: Color(0xFF2193b0)),
                        ),
                        title: Text(medicine['name'] ?? "Unknown",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "Stock: ${medicine['qty'] ?? medicine['stock'] ?? 0}"),
                        trailing: Text("${medicine['price'] ?? 0} TK",
                            style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        onTap: () {
                          // অর্ডারিং বা ডিটেইলস লজিক এখানে আসবে
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
