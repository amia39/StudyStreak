class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final bool Function(int) meetsRequirement;

  AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.meetsRequirement,
  });

  static List<AchievementBadge> get allBadges => [
        AchievementBadge(
          id: '20_days',
          title: '20 Logins',
          description: 'Obtained by logging onto the app for 20 or more days',
          imagePath: 'assets/images/badge_20.png',
          meetsRequirement: (totalDays) => totalDays >= 20,
        ),
      ];
}
