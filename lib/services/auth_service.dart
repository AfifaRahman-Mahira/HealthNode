import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserModel? currentUser;

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

  // ড্রপডাউন থেকে আসা selectedRole প্যারামিটারটি এখানে চেক হবে
  Future<UserModel?> loginUser(String email, String password, String selectedRole) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (result.user != null) {
        DocumentSnapshot doc = await _db.collection('users').doc(result.user!.uid).get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String dbRole = data['role'] ?? 'Patient';

          // যদি সিলেক্ট করা রোলের সাথে ডাটাবেসের রোল মিলে যায়
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
            // রোল না মিললে আমরা তাকে লগইন করতে দেব না
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
}