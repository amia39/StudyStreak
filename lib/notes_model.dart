import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Note {
  final XFile? image;
  final String text;

  Note({this.image, this.text = ''});

  // Convert Note to JSON map
  Map<String, dynamic> toJson() {
    return {
      'imagePath': image?.path,
      'text': text,
    };
  }

// Create Note from JSON map
  factory Note.fromJson(Map<String, dynamic> json) {
    final imagePath = json['imagePath'] as String?;
    return Note(
      image:
          imagePath != null && imagePath.isNotEmpty ? XFile(imagePath) : null,
      text: json['text'] ?? '',
    );
  }
}

class NotesState extends ChangeNotifier {
  List<Note> notes = [];

  NotesState() {
    loadNotes();
  }

  // add a new file picture
  Future<void> addNote(XFile picture, {String text = ''}) async {
    notes.add(Note(image: picture, text: text));
    notifyListeners();
    await _saveToPreferences();
  }

  Future<void> addTextNote(String text) async {
    notes.add(Note(text: text));
    notifyListeners();
    await _saveToPreferences();
  }

  // remove a note and its picture
  Future<void> deleteNote(Note note) async {
    notes.remove(note);
    notifyListeners();
    await _saveToPreferences();
  }

  // save all paths to SharedPreferences
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert each note to a JSON string
    final noteJsonList = notes.map((note) => jsonEncode(note.toJson())).toList();
    await prefs.setStringList('notes', noteJsonList);
  }

  // load image paths from SharedPreferences on startup
  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final noteJsonList = prefs.getStringList('notes') ?? [];
    notes = noteJsonList.map((noteJson) {
      final Map<String, dynamic> noteMap = jsonDecode(noteJson);
      return Note.fromJson(noteMap);
    }).toList();
    notifyListeners();
  }
}
