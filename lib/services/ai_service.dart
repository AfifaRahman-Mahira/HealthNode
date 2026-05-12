import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';

class AIService {
  // Week 6: Gemini API Key Integration
  static const String _apiKey = "AIzaSyApwRXLkgQORQ868IGZmPbl-CPmPUqN70o";

  // Week 7: Chat History List
  // This list will store the conversation to make the AI remember previous context
  final List<Content> _chatHistory = [];

  // Function to get medical advice with session memory
  Future<String> getMedicalAdvice(String prompt) async {
    try {
      // Week 6: Initializing the Generative Model
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      // Week 7: Starting a Chat Session with history support
      final chatSession = model.startChat(history: _chatHistory);

      // Week 6: Providing role-based instructions for medical safety
      final instruction = "Role: Medical Assistant for HealthNode app. "
          "Task: Provide accurate info about medicines and side effects. "
          "Rule: Keep it brief and always advise to consult a doctor. "
          "Question: $prompt";

      // Week 7: Sending the message through the chat session
      final response = await chatSession.sendMessage(Content.text(instruction));
      final responseText = response.text ?? "I'm sorry, I couldn't generate a response.";

      // Week 7: Manually updating local history to track the conversation
      _chatHistory.add(Content.text("User: $prompt"));
      _chatHistory.add(Content.model([TextPart(responseText)]));
      
      return responseText;
    } catch (e) {
      // Week 6: Error handling for API connection issues
      debugPrint("Gemini AI Error: $e");
      return "Technical error: Please check your internet connection.";
    }
  }

  // Week 7: Utility function to clear chat history when needed
  void resetChat() {
    _chatHistory.clear();
  }
}