import 'package:flutter/material.dart';

/// HolySpots design tokens (from tokens/colors.css, effects.css, typography.css).
/// Sky-blue accent, cloud canvas, coral for destructive actions, Roboto type,
/// serif for data-entry value fields (the deliberate old-catalog quirk).
class Hs {
  // blues
  static const blue600 = Color(0xFF0091C4); // hover
  static const blue500 = Color(0xFF00ACE8); // primary
  static const blue400 = Color(0xFF47BFED); // save / checked
  static const blue300 = Color(0xFF60AAE5);
  static const blue100 = Color(0xFFCFF2FF); // like / selected bg
  static const cloud200 = Color(0xFFDCE8EC); // canvas + secondary buttons
  // neutrals
  static const white = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF9F9F9);
  static const gray100 = Color(0xFFF5F5F5);
  static const gray150 = Color(0xFFEEEDED);
  static const gray200 = Color(0xFFE0E0E0); // divider
  static const gray400 = Color(0xFFC6C6C6);
  static const gray500 = Color(0xFFB2B6BB);
  static const gray600 = Color(0xFF9B9B9B);
  static const gray700 = Color(0xFF575F6A);
  static const gray800 = Color(0xFF4A4A4A); // body text
  static const black = Color(0xFF000000);
  // warm accents
  static const coral500 = Color(0xFFFE835D); // cancel / delete / sound
  static const red500 = Color(0xFFFF5E5E);

  // semantic
  static const primary = blue500;
  static const primaryHover = blue600;
  static const danger = coral500;
  static const surfacePage = white;
  static const surfaceCloud = cloud200;
  static const textTitle = black;
  static const textBody = gray800;
  static const textAdmin = gray700;
  static const textSecondary = gray600;
  static const textTertiary = gray400;
  static const divider = gray200;
  static const dividerLight = Color(0xFFF4F4F4);

  // radii
  static const rCard = 5.0;
  static const rChip = 6.0;
  static const rBtn = 7.0;
  static const rInput = 9.0;

  // motion
  static const durFast = Duration(milliseconds: 150);
  static const durBase = Duration(milliseconds: 250);
  static const easeStandard = Cubic(.2, 0, 0, 1);

  // fonts
  static const fontCore = 'Roboto';
  static const List<String> serifData = ['Georgia', 'Times New Roman', 'serif'];

  static const cardShadow = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const dialogShadow = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 30, offset: Offset(0, 8)),
  ];

  // animation-track colours (kept inside palette: blues + one coral + gray)
  static Color animColor(String type) {
    switch (type) {
      case 'Translate':
        return blue500;
      case 'Rotate':
        return blue300;
      case 'Scale':
        return blue400;
      case 'Alpha':
        return gray500;
      default:
        return coral500; // Sound
    }
  }
}

ThemeData buildHolySpotsTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: Hs.fontCore,
    scaffoldBackgroundColor: Hs.surfaceCloud,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Hs.blue500,
      primary: Hs.blue500,
      surface: Hs.white,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: Hs.textBody,
      displayColor: Hs.textTitle,
    ),
    splashFactory: NoSplash.splashFactory, // 2026: no ripple; hover/press tokens
  );
}

/// Common label style for the uppercase panel section headers.
const kSectionLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w500,
  letterSpacing: .6,
  color: Hs.textSecondary,
);

TextStyle serifValue([Color color = Hs.primary]) => TextStyle(
      fontFamily: Hs.serifData.first,
      fontFamilyFallback: Hs.serifData.sublist(1),
      fontSize: 15,
      color: color,
    );
