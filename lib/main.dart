import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:studystreak/theme_model.dart';
import 'calendar_tab.dart';
import 'flashcard_tab.dart';
import 'notetaking_tab.dart';
import 'home_screen.dart';
import 'package:studystreak/notes_model.dart';
import 'package:studystreak/flashcard_model.dart';

Future<void> main() async {
  // setting up camera functionality
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  // Initialize models with data loaded from SharedPrefs
  final cardState = CardState();
  await cardState.loadFromPreferences();

  final notesState = NotesState();
  await notesState.loadNotes();

  final customization = Customization();
  await customization.appThemeFromPreferences();
  print("this is the app theme: ${customization.appTheme}");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CardState>.value(value: cardState),
        ChangeNotifierProvider<NotesState>.value(value: notesState),
        ChangeNotifierProvider<Customization>.value(value: customization),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String appTheme = Provider.of<Customization>(context).appTheme;
    Color textColor = appTheme == 'light' ? Colors.black : Colors.white;

    return MaterialApp(
      title: 'StudyStreak',
      theme: ThemeData(
        scaffoldBackgroundColor: textColor,
        appBarTheme: AppBarTheme(
          backgroundColor: textColor,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  @override
  Widget build(BuildContext context) {
    String appTheme = Provider.of<Customization>(context).appTheme;
    Color textColor = appTheme == 'light' ? Colors.black : Colors.white;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: appTheme == 'light' ? Colors.white : Colors.black,
        body: TabBarView(
          children: [
            CalendarTab(),
            FlashcardTab(),
            NoteTakingTab(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: appTheme == 'light' ? Colors.white : const Color.fromARGB(255, 7, 31, 43),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
                spreadRadius: 2.0,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: TabBar(
              indicatorColor: Colors.black,
              labelColor: textColor,
              unselectedLabelColor: appTheme == 'light' ? Colors.grey : Colors.blueGrey,
              tabs: [
                Tab(icon: Icon(Icons.calendar_today), text: 'Calendar'),
                Tab(icon: Icon(Icons.school), text: 'Flashcards'),
                Tab(icon: Icon(Icons.note), text: 'Notes'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
