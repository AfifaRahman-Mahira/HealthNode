import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  // তোমার দেওয়া একদম লেটেস্ট এপিআই কি এখানে আপডেট করা হয়েছে
  static const String _apiKey = "AIzaSyCzzvsKLQzOEk98ttP82kr8JU0skTG1oFk";
  final List<Content> _chatHistory = [];

  Future<String> getMedicalAdvice(String prompt, String userId) async {
    try {
      // ফায়ারস্টোর থেকে ঔষধের লিস্ট আনা হচ্ছে
      final medSnapshot = await FirebaseFirestore.instance.collection('medicines').get();
      String inventory = medSnapshot.docs.isEmpty 
          ? "No medicines currently listed." 
          : medSnapshot.docs.map((doc) => doc['name']).join(", ");

      // মডেল কনফিগারেশন: সেফটি সেটিংস 'none' করা হয়েছে যাতে মেডিকেল টপিক ব্লক না হয়
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: _apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 500,
        ),
      );
      
      // এআইকে কনটেক্সট দেওয়া হচ্ছে
      final systemContext = "You are HealthNode Assistant. Available medicines in stock: $inventory. Instructions: Provide very short, helpful health advice. If a medicine is not in stock, let the user know.";

      // নতুন সেশন শুরু করা হচ্ছে
      final chat = model.startChat(history: _chatHistory);
      final response = await chat.sendMessage(Content.text("$systemContext\n\nUser Question: $prompt"));
      
      if (response.text == null || response.text!.isEmpty) {
        return "AI response is empty. Please try a different question.";
      }

      // চ্যাট হিস্টোরি আপডেট
      _chatHistory.add(Content.text("User: $prompt"));
      _chatHistory.add(Content.model([TextPart(response.text!)]));

      return response.text!;
    } catch (e) {
      print("Final Debug Error: $e");
      
      // এরর মেসেজগুলোকে ইউজার ফ্রেন্ডলি করা
      String errorMessage = "Something went wrong.";
      if (e.toString().contains('429')) {
        errorMessage = "Quota exceeded! Please wait 60 seconds.";
      } else if (e.toString().contains('403')) {
        errorMessage = "API Key Error. Please check your Google AI Studio status.";
      } else if (e.toString().contains('invalid')) {
        errorMessage = "Invalid API Key. Please update the key.";
      }

      return "AI Notice: $errorMessage (Check VPN if needed)";
    }
  }
}