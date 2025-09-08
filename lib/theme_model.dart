import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Customization extends ChangeNotifier {

  String appMode = 'light';

  Future<void> appThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    appMode = prefs.getString('themeMode') ?? 'light';
    notifyListeners();
  }

  // getter for app mode
  String get appTheme => appMode;

}