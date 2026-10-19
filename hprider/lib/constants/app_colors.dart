import 'package:flutter/material.dart';

/// HungerPoint brand palette — derived from the app icon:
///   • Background:  #E84A1F  (warm orange-red)
///   • Foreground:  #FFFFFF  (white)
///   • Accent/Dark: #2D2D2D  (charcoal knife)
class AppColors {
  AppColors._();

  static const Color amber         = Color(0xFFE84A1F); // icon orange-red (brand primary)
  static const Color orange        = Color(0xFFC73D18); // darker pressed/hover variant
  static const Color background    = Color(0xFFF9FAFB); // light scaffold
  static const Color surface       = Color(0xFFFFFFFF); // card surface
  static const Color surfaceBorder = Color(0xFFF3F4F6); // card borders
  static const Color appBar        = Color(0xFFFFFFFF); // top bar

  static const Color textPrimary   = Color(0xFF2D2D2D); // charcoal (replaces old navy)
  static const Color textMuted     = Color(0xFF6B7280); // secondary/hint text

  static const Color success       = Color(0xFF2E7D32);
  static const Color danger        = Color(0xFFEF4444);
}
