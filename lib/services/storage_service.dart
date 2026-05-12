import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Week 8: Function to upload prescription and save URL in database
  Future<String?> uploadPrescription({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // 1. Define a unique path in Firebase Storage
      String filePath = 'prescriptions/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(filePath);

      // 2. Start the upload task
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // 3. Get the URL after successful upload
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 4. Save this URL and other info to Firestore (for patient history)
      await _db.collection('prescriptions').add({
        'userId': userId,
        'imageUrl': downloadUrl,
        'status': 'Pending Verification',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      return downloadUrl; // Return URL to display on the UI
    } catch (e) {
      debugPrint("Firebase Storage Error: $e");
      return null;
    }
  }

  // Week 8: Function to fetch all prescriptions uploaded by a specific user
  Stream<QuerySnapshot> getUserPrescriptions(String userId) {
    return _db
        .collection('prescriptions')
        .where('userId', isEqualTo: userId)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }
}