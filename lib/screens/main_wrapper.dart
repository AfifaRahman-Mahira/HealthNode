import 'package:flutter/material.dart';
import 'patient_home.dart';
import 'pharmacy_home.dart';
import 'delivery_home.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // Screen gulor list
  final List<Widget> _screens = [
    const PatientHome(),
    const PharmacyHome(),
    const DeliveryHome(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Patient'),
          BottomNavigationBarItem(icon: Icon(Icons.local_pharmacy), label: 'Pharmacy'),
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Runner'),
        ],
      ),
    );
  }
}