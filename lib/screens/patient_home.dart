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

  final List<String> categories = ["All", "Fever", "Pain", "Gastric", "Antibiotic"];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: "Search for Napa, Sergel...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2193b0)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
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
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: selectedCategory == categories[index] 
                              ? const Color(0xFF2193b0) 
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No medicines found.", style: TextStyle(fontSize: 16)));
              }

              var medicineDocs = snapshot.data!.docs.where((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String name = (data['name'] ?? "").toString().toLowerCase();
                String category = data.containsKey('category') ? data['category'].toString() : "General";
                
                bool matchesSearch = name.contains(searchQuery);
                bool matchesCategory = selectedCategory == "All" || category == selectedCategory;
                
                return matchesSearch && matchesCategory;
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: medicineDocs.length,
                itemBuilder: (context, index) {
                  var doc = medicineDocs[index];
                  Map<String, dynamic> medicine = doc.data() as Map<String, dynamic>;
                  
                  String medName = medicine['name'] ?? "Unknown";
                  String medCategory = medicine.containsKey('category') ? medicine['category'] : "General";
                  int medStock = medicine['stock'] ?? 0;
                  var medPrice = medicine['price'] ?? 0;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2193b0).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication, color: Color(0xFF2193b0), size: 32),
                      ),
                      title: Text(
                        medName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, // Extra bold for clarity
                          fontSize: 17,
                          color: Color(0xFF2C3E50),
                          letterSpacing: 0.5,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Category: $medCategory",
                              style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Stock: $medStock units",
                              style: TextStyle(
                                color: medStock > 0 ? Colors.green.shade700 : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(
                        "$medPrice ৳", // Taka sign for local feel
                        style: const TextStyle(
                          color: Color(0xFF27AE60), 
                          fontWeight: FontWeight.w900,
                          fontSize: 19
                        ),
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