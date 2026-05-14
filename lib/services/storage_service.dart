import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadPrescription({required File imageFile, required String userId}) async {
    try {
      // ১. Firebase Storage-এ ফাইল আপলোড করা
      String fileName = 'prescriptions/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      
      // ফাইল আপলোড শুরু
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      // ২. আপলোড করা ফাইলের ডাউনলোড লিঙ্ক (URL) নেওয়া
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // ৩. Firestore-এ রেকর্ড সেভ করা (এটিই হলো ৩ নম্বর পয়েন্টের মূল কাজ)
      // এই ডাটা চেক করেই অ্যাপ সিদ্ধান্ত নেবে ইউজার প্রেসক্রিপশন দিয়েছে কি না
      await _firestore.collection('prescriptions').add({
        'userId': userId,
        'imageUrl': downloadUrl,
        'status': 'verified', // আপনি চাইলে পেন্ডিং রাখতে পারেন
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl;
    } catch (e) {
      print("Error in StorageService: $e");
      return null;
    }
  }
}