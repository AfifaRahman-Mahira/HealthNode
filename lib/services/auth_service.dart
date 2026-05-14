import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? currentUser;

  User? get user => _auth.currentUser;

  // --- Week 3: Authentication Logic ---
  // Handles user registration and initial Firestore profile creation
  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? pharmacyName,
    String? pharmacyLicense,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _db.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'name': name,
          'email': email,
          'role': role,
          'pharmacyName': pharmacyName ?? '',
          'pharmacyLicense': pharmacyLicense ?? '',
          'isVerified': false, // Week 5: Default status for admin approval
          'status': 'active',  // Week 5: Access control status
          'createdAt': FieldValue.serverTimestamp(),
        });
        return "success";
      }
      return "Registration failed";
    } catch (e) {
      return e.toString();
    }
  }

  // Validates user login and enforces role-based access
  Future<UserModel?> loginUser(
      String email, String password, String selectedRole) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        DocumentSnapshot doc =
            await _db.collection('users').doc(result.user!.uid).get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String dbRole = data['role'] ?? 'Patient';

          if (dbRole == selectedRole) {
            currentUser = UserModel(
              uid: result.user!.uid,
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              role: dbRole,
              pharmacyName: data['pharmacyName'] ?? '',
            );
            return currentUser;
          } else {
            await _auth.signOut();
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("Login Error: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    currentUser = null;
  }

  Stream<User?> get userState => _auth.authStateChanges();

  // --- Week 4: Patient Logic - Search & Filter ---
  // This stream enables real-time search filtering in patient_home.dart
  Stream<QuerySnapshot> searchMedicines(String query) {
    return _db
        .collection('medicines')
        .where('name', isGreaterThanOrEqualTo: query.toUpperCase())
        .where('name', isLessThanOrEqualTo: '${query.toUpperCase()}\uf8ff')
        .snapshots();
  }

  // --- Week 5: Admin Control Center Logic ---
  // Core logic for admin_dashboard.dart to verify licenses and manage access
  Future<void> updateUserStatus(String uid, String field, dynamic value) async {
    try {
      await _db.collection('users').doc(uid).update({
        field: value,
      });
    } catch (e) {
      debugPrint("Admin Control Error: $e");
    }
  }

  // --- Week 5: Pharmacist Inventory Logic ---
  // Enables adding medicine records directly from the app interface
  Future<String> addMedicine({
    required String name,
    required String category,
    required double price,
    required int stock,
  }) async {
    try {
      await _db.collection('medicines').add({
        'name': name.toUpperCase(),
        'category': category,
        'price': price,
        'stock': stock,
        'addedBy': _auth.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return "success";
    } catch (e) {
      return e.toString();
    }
  }
}