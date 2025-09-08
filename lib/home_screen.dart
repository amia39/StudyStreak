import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studystreak/main.dart';
import 'dart:ui';

// This is the very first screen the user goes to.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/home_background.png',
            fit: BoxFit.cover,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Text(
                'Study',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'NothingYouCouldDo',
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 40.0),
                child: Text(
                  'Streak',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'NothingYouCouldDo',
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const StudyScreen()),
                        );
                      },
                      child: const Text(
                        'Start Studying',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15,),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.9)),
                    ),
                    child: 
                    TextButton(
                      onPressed: () async{
                        SharedPreferences preference = await SharedPreferences.getInstance();
                        await preference.setString('themeMode', 'dark'); // default light mode
                        print("clicked, now in dark mode!");
                      },
                      child: const Text(
                        'Click to switch to dark mode!',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
