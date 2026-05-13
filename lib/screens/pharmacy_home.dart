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
  final List<String> categories = [
    "All",
    "Fever",
    "Pain",
    "Gastric",
    "Antibiotic"
  ];
  final _formKey = GlobalKey<FormState>();

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

  Widget _buildTopSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: TextField(
        onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
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

  Widget _buildMedicineList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('medicines').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          String cat = data['category'] ?? "All";
          return name.contains(searchQuery) &&
              (selectedCategory == "All" || cat == selectedCategory);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            var docId = docs[index].id;
            int qty = data['qty'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                onTap: () =>
                    _showMedicineDetails(data), // ক্লিক করলে ডিটেইলস দেখাবে
                leading: Icon(Icons.medication, color: primaryColor),
                title: Text(data['name'] ?? "N/A",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Price: ৳${data['price']} | Qty: $qty"),
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

  // ক্লিক করলে মেডিসিনের ডিটেইলস দেখানোর ফাংশন
  void _showMedicineDetails(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
                child: Icon(Icons.maximize, size: 40, color: Colors.grey)),
            Text(data['name'] ?? "Details",
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            _infoRow(Icons.category, "Category", data['category'] ?? "General"),
            _infoRow(Icons.money, "Price", "৳${data['price']}"),
            _infoRow(Icons.storage, "In Stock", "${data['qty']} pcs"),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"))),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text("$title: $val", style: const TextStyle(fontSize: 16))
      ]),
    );
  }

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
                title: Text(docId == null ? "Add New" : "Edit Record"),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: nameC,
                      decoration: const InputDecoration(labelText: "Name")),
                  TextField(
                      controller: qtyC,
                      decoration: const InputDecoration(labelText: "Qty"),
                      keyboardType: TextInputType.number),
                  TextField(
                      controller: priceC,
                      decoration: const InputDecoration(labelText: "Price"),
                      keyboardType: TextInputType.number),
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
                actions: [
                  ElevatedButton(
                      onPressed: () async {
                        final data = {
                          'name': nameC.text,
                          'qty': int.parse(qtyC.text),
                          'price': double.parse(priceC.text),
                          'category': tempCat
                        };
                        docId == null
                            ? await FirebaseFirestore.instance
                                .collection('medicines')
                                .add(data)
                            : await FirebaseFirestore.instance
                                .collection('medicines')
                                .doc(docId)
                                .update(data);
                        Navigator.pop(context);
                      },
                      child: const Text("Save"))
                ],
              )),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Delete?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("No")),
                TextButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('medicines')
                          .doc(id)
                          .delete();
                      Navigator.pop(context);
                    },
                    child: const Text("Yes")),
              ],
            ));
  }
}
