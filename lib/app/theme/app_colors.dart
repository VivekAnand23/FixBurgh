import 'package:flutter/material.dart';

/// Brand colors from the FixBurgh logo (see BRD section 11.4).
///
/// Contrast against white: navy 8.4:1, orange700 5.0:1, teal700 6.3:1.
/// [orange] is only 2.7:1, so never use it for text or behind white text.
abstract final class AppColors {
  static const navy = Color(0xFF1B4F86);
  static const orange = Color(0xFFF47B20);
  static const orange700 = Color(0xFFB4530E);
  static const teal = Color(0xFF3A9284);
  static const teal700 = Color(0xFF1F6B5F);
  static const danger = Color(0xFFC53030);
  static const neutral900 = Color(0xFF1A202C);
  static const neutral600 = Color(0xFF4A5568);
}
