import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AchievementBadge.dart';
import 'package:provider/provider.dart';
import 'theme_model.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  late DateTime currDate;
  late DateTime selectedDay;
  Set<DateTime> activeDays = {};
  int highestStreak = 0;
  bool _isLoading = true;
  List<AchievementBadge> earnedBadges = [];

  @override
  void initState() {
    super.initState();
    currDate = DateTime.now();
    selectedDay = currDate;
    _loadActiveDays();
  }

  Future<void> _loadActiveDays() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDays = prefs.getStringList('activeDays') ?? [];

    setState(() {
      activeDays = savedDays.map((dateStr) => DateTime.parse(dateStr)).toSet();
      _isLoading = false;
      _markActiveDay();
      _checkBadges();
    });
  }

  Future<void> _saveActiveDays() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStrings = activeDays.map((date) => date.toString()).toList();
    await prefs.setStringList('activeDays', dateStrings);
  }

  void _markActiveDay() {
    if (_isLoading) return;

    DateTime today = DateTime.now();
    DateTime normalizedToday = DateTime.utc(today.year, today.month, today.day);

    setState(() {
      activeDays.add(normalizedToday);
      _updateStreak();
      _checkBadges();
      _saveActiveDays();
    });
  }

  void _addTestDays() {
    final today = DateTime.now();
    setState(() {
      for (int i = 0; i < 20; i++) {
        final day = today.subtract(Duration(days: i));
        activeDays.add(DateTime.utc(day.year, day.month, day.day));
      }
      _updateStreak();
      _checkBadges();
      _saveActiveDays();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added 20 test days')),
    );
  }

  void _updateStreak() {
    if (activeDays.isEmpty) {
      highestStreak = 0;
      return;
    }

    List<DateTime> sortedActiveDays = activeDays.toList()
      ..sort((a, b) => a.compareTo(b));

    int tempHighestStreak = 1;
    int tempCurrentStreak = 1;

    for (int i = 1; i < sortedActiveDays.length; i++) {
      if (sortedActiveDays[i].difference(sortedActiveDays[i - 1]).inDays == 1) {
        tempCurrentStreak++;
        if (tempCurrentStreak > tempHighestStreak) {
          tempHighestStreak = tempCurrentStreak;
        }
      } else {
        tempCurrentStreak = 1;
      }
    }

    setState(() {
      highestStreak = tempHighestStreak;
    });
  }

  void _checkBadges() {
    final totalDays = activeDays.length;
    final allBadges = AchievementBadge.allBadges;
    final newlyEarned = <AchievementBadge>[];

    for (final badge in allBadges) {
      if (badge.meetsRequirement(totalDays) &&
          !earnedBadges.any((b) => b.id == badge.id)) {
        newlyEarned.add(badge);
      }
    }

    if (newlyEarned.isNotEmpty) {
      setState(() {
        earnedBadges.addAll(newlyEarned);
      });
    }
  }

  void _showBadgesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Badges'),
        content: earnedBadges.isEmpty
            ? const Text('No badges earned yet.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: earnedBadges
                      .map(
                        (badge) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              Image.asset(badge.imagePath, width: 60),
                              const SizedBox(height: 8),
                              Text(
                                badge.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(badge.description),
                              const SizedBox(height: 8),
                              const Divider(),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String appTheme = Provider.of<Customization>(context).appTheme;
    Color textColor = appTheme == 'light' ? Colors.black : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Calendar",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appTheme == 'light' ? Colors.blue : const Color.fromARGB(255, 7, 31, 43),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration( // const
          image: DecorationImage(
            image: appTheme == 'light' ? AssetImage("assets/images/calendar_background.png") : AssetImage("assets/images/darkmode_calendar.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: OrientationBuilder(builder: (context, orientation) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return orientation == Orientation.portrait
                ? Column(
                    children: [
                      // Calendar Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(8.0),
                          child: TableCalendar(
                            focusedDay: currDate,
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            calendarFormat: CalendarFormat.month,
                            availableCalendarFormats: const {
                              CalendarFormat.month: 'Month'
                            },
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                            ),
                            calendarStyle: const CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) {
                                DateTime normalizedDay =
                                    DateTime.utc(day.year, day.month, day.day);
                                if (activeDays.contains(normalizedDay)) {
                                  return Positioned(
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${day.day}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return null;
                              },
                            ),
                            onDaySelected: (selectedDayParam, focusedDay) {
                              setState(() {
                                selectedDay = selectedDayParam;
                                currDate = focusedDay;
                              });
                            },
                            selectedDayPredicate: (day) =>
                                isSameDay(selectedDay, day),
                          ),
                        ),
                      ),
                      // Stats Section
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'Days Studied:',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              '${activeDays.length}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Highest Streak:',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Text(
                              '$highestStreak days',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Calendar Section - Landscape
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SingleChildScrollView(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: TableCalendar(
                                focusedDay: currDate,
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                calendarFormat: CalendarFormat.month,
                                availableCalendarFormats: const {
                                  CalendarFormat.month: 'Month'
                                },
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                ),
                                calendarStyle: const CalendarStyle(
                                  todayDecoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, day, events) {
                                    DateTime normalizedDay = DateTime.utc(
                                        day.year, day.month, day.day);
                                    if (activeDays.contains(normalizedDay)) {
                                      return Positioned(
                                        child: Container(
                                          width: 50,
                                          height: 50,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return null;
                                  },
                                ),
                                onDaySelected: (selectedDayParam, focusedDay) {
                                  setState(() {
                                    selectedDay = selectedDayParam;
                                    currDate = focusedDay;
                                  });
                                },
                                selectedDayPredicate: (day) =>
                                    isSameDay(selectedDay, day),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Stats Section - Landscape
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Days Studied:',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  '${activeDays.length}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Highest Streak:',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                Text(
                                  '$highestStreak days',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
          }),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'test_button',
            onPressed: _addTestDays,
            mini: true,
            child: const Icon(Icons.add),
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showBadgesDialog,
            child: const Icon(Icons.emoji_events),
            backgroundColor: Colors.amber,
          ),
        ],
      ),
    );
  }
}
