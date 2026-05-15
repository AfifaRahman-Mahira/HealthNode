import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AIService {

  static const String _apiKey = "AIzaSyA-gDagZSKZ5U6Tu4jsLwdOYBvfZQ-L6O4";
  
  //  Using 'v1' instead of 'v1beta' to avoid 404
  static const String _url = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$_apiKey";

  Future<String> getMedicalAdvice(String prompt, String userId) async {
    try {
      final medSnapshot = await FirebaseFirestore.instance.collection('medicines').get();
      String inventory = medSnapshot.docs.isEmpty 
          ? "No stock available" 
          : medSnapshot.docs.map((doc) => doc['name']).join(", ");

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "System: You are HealthNode AI. Inventory: $inventory. Answer in 1 short sentence. User Question: $prompt"
            }]
          }],
          // Explicit generation config to ensure compatibility
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 100
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Detailed log for debugging
        debugPrint("API Response Error: ${response.body}");
        return "AI Module under server maintenance.";
      }
    } catch (e) {
      debugPrint(" Request Failed: $e");
      return "Connection Error. Please check.";
    }
  }
}