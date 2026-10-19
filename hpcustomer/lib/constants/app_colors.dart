import 'package:flutter/material.dart';

/// HungerPoint brand palette — derived from the app icon:
///   • Background:  #E84A1F  (warm orange-red)
///   • Foreground:  #FFFFFF  (white)
///   • Accent/Dark: #2D2D2D  (charcoal knife)
class AppColors {
  static const Color primaryYellow  = Color(0xFFE84A1F); // icon orange-red (replaces old yellow)
  static const Color primaryOrange  = Color(0xFFE84A1F); // same brand red-orange
  static const Color accentOrange   = Color(0xFFC73D18); // darker shade for pressed/hover
  static const Color darkNavy       = Color(0xFF2D2D2D); // charcoal (replaces old navy)
  static const Color textNavy       = Color(0xFF2D2D2D); // charcoal body text
  static const Color bgGrey         = Color(0xFFF9FAFB); // light background
  static const Color background     = Color(0xFFF9FAFB); // scaffold background
  static const Color cardBorder     = Color(0xFFF3F4F6); // subtle card borders
  static const Color textMuted      = Color(0xFF6B7280); // secondary text

  static const Color success        = Color(0xFF2E7D32);
  static const Color danger         = Color(0xFFEF4444);
}
