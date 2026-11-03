import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF6C63FF);
const Color kSecondary = Color(0xFF8E86FF);
const Color kAccent = Color(0xFFB8B3FF);
const Color kBackground = Color(0xFFF7F8FC);
const Color kCard = Colors.white;
const Color kTextDark = Color(0xFF1E1F2A);
const Color kTextLight = Color(0xFF7B7E8E);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: kBackground,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimary,
    primary: kPrimary,
    background: kBackground,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: kTextDark,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: kTextDark,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: kTextDark,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: kTextDark,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: kTextLight,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE8EAF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: kPrimary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: kTextLight),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 58),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBackground,
    elevation: 0,
    centerTitle: true,
    foregroundColor: kTextDark,
  ),
);

BoxDecoration gradientCardDecoration = BoxDecoration(
  gradient: const LinearGradient(
    colors: [kPrimary, kSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(28),
  boxShadow: const [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 22,
      offset: Offset(0, 10),
    ),
  ],
);

BoxDecoration whiteCardDecoration = BoxDecoration(
  color: kCard,
  borderRadius: BorderRadius.circular(22),
  boxShadow: const [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ],
);