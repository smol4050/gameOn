import 'package:flutter/material.dart';

import '../theme/colors.dart';

class AppSports {
  static const String football = 'Fútbol';
  static const String basketball = 'Baloncesto';
  static const String tennis = 'Tenis';
  static const String volleyball = 'Vóley';
  static const String ultimate = 'Ultimate';
  static const String all = 'Todos';

  static const List<String> values = [
    football,
    basketball,
    tennis,
    volleyball,
    ultimate,
  ];

  static const List<String> filters = [
    all,
    ...values,
  ];

  static const Map<String, String> emojis = {
    football: '⚽',
    basketball: '🏀',
    tennis: '🎾',
    volleyball: '🏐',
    ultimate: '🥏',
  };

  static const Map<String, Color> colors = {
    football: AppColors.primary,
    basketball: AppColors.primary,
    tennis: AppColors.primary,
    volleyball: AppColors.primary,
    ultimate: AppColors.primary,
  };

  static const Map<String, IconData> icons = {
    football: Icons.sports_soccer,
    basketball: Icons.sports_basketball,
    tennis: Icons.sports_tennis,
    volleyball: Icons.sports_volleyball,
    ultimate: Icons.animation,
  };

  static String emojiFor(String sport) => emojis[sport] ?? '🏅';

  static Color colorFor(String sport) => colors[sport] ?? AppColors.primary;

  static IconData iconFor(String sport) => icons[sport] ?? Icons.sports;
}
