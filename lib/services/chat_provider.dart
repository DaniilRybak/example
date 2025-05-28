import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, String>> messages = [];

  void addMessage(Map<String, String> message) {
    messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    messages.clear();
    notifyListeners();
  }
}