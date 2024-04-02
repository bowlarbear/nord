import 'package:flutter/material.dart';

ThemeData theme() {
  Color secondaryColor = Colors.orange;
  Color primaryColor = Colors.blue.withOpacity(.8);
  Color globalBackgroundColor = Colors.black;
  return ThemeData(
      primaryColor: primaryColor,
      secondaryHeaderColor: secondaryColor,
      scaffoldBackgroundColor: globalBackgroundColor,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
      ),
      textTheme: TextTheme(
          displayLarge: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          displayMedium: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.5),
          bodyLarge: TextStyle(
              color: Colors.white.withOpacity(.8),
              fontWeight: FontWeight.w500,
              fontSize: 12),
          labelLarge: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(.4),
            fontWeight: FontWeight.w500,
            fontSize: 10),
      ));
}
