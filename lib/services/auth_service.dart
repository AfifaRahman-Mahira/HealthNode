import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? currentUser;

  // Check if someone is currently signed in
  User? get user => _auth.currentUser;

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
          'createdAt': FieldValue.serverTimestamp(),
        });
        return "success";
      }
      return "Registration failed";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          currentUser = UserModel(
            uid: result.user!.uid,
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            role: data['role'] ?? 'Patient',
            pharmacyName: data['pharmacyName'] ?? '',
          );
          return currentUser!.role; 
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
}