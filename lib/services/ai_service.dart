import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AIService {
  // Use a key from a BRAND NEW project here
  static const String _apiKey = "AIzaSyCKD7pbJ8MCzDeLYXS1m-peeMLXFAIq94c"; 
  
  // v1beta is required for gemini-1.5-flash-latest
  static const String _url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$_apiKey";

  Future<String> getMedicalAdvice(String prompt, String userId) async {
    try {
      final medSnapshot = await FirebaseFirestore.instance.collection('medicines').get();
      String inventory = medSnapshot.docs.isEmpty 
          ? "No stock available" 
          : medSnapshot.docs.map((doc) => doc['name'] as String).join(", ");

      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "System: You are HealthNode AI assistant. Inventory: $inventory. User: $prompt. Provide a short, one-sentence medical answer in English."
            }]
          }]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        debugPrint("API Error Detail: ${response.body}");
        return "AI Module error (${response.statusCode}).";
      }
    } catch (e) {
      return "Connection failed.";
    }
  }
}