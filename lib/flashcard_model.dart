import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Flashcard {
  String question;
  String answer;
  String? questionImagePath;
  String? answerImagePath;
  bool isFlipped;

  Flashcard({
    required this.question,
    required this.answer,
    this.questionImagePath,
    this.answerImagePath,
    this.isFlipped = false,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
        'questionImagePath': questionImagePath,
        'answerImagePath': answerImagePath,
        'isFlipped': isFlipped,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        question: json['question'],
        answer: json['answer'],
        questionImagePath: json['questionImagePath'],
        answerImagePath: json['answerImagePath'],
        isFlipped: json['isFlipped'] ?? false,
      );

  File? get questionImage =>
      questionImagePath != null ? File(questionImagePath!) : null;
  File? get answerImage =>
      answerImagePath != null ? File(answerImagePath!) : null;
}

class FlashcardCategory {
  String name;
  List<Flashcard> flashcards;

  FlashcardCategory({required this.name, List<Flashcard>? flashcards})
      : flashcards = flashcards ?? [];

  Map<String, dynamic> toJson() => {
        'name': name,
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
      };

  factory FlashcardCategory.fromJson(Map<String, dynamic> json) =>
      FlashcardCategory(
        name: json['name'],
        flashcards: (json['flashcards'] as List)
            .map((f) => Flashcard.fromJson(f))
            .toList(),
      );
}

class CardState extends ChangeNotifier {
  List<FlashcardCategory> categories = [];

  static const _storageKey = 'flashcard_data';

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final decoded = json.decode(jsonString);
      categories =
          (decoded as List).map((c) => FlashcardCategory.fromJson(c)).toList();
      notifyListeners();
    }
  }

  Future<void> saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(categories.map((c) => c.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  void addCategory(FlashcardCategory category) {
    categories.add(category);
    saveToPreferences();
    notifyListeners();
  }

  void removeCategory(int index) {
    categories.removeAt(index);
    saveToPreferences();
    notifyListeners();
  }

  void addFlashcard(int categoryIndex, Flashcard card) {
    categories[categoryIndex].flashcards.add(card);
    saveToPreferences();
    notifyListeners();
  }

  void removeFlashcard(int categoryIndex, int flashcardIndex) {
    categories[categoryIndex].flashcards.removeAt(flashcardIndex);
    saveToPreferences();
    notifyListeners();
  }
}
