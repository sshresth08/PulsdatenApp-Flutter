import 'package:flutter/material.dart';

const textColor = Color(0xFFFBFDFE);
const backgroundColor = Color(0xFF05181F);
const primaryColor = Color(0xFF80C5C1);
const primaryFgColor = Color(0xFF05181F);
const secondaryColor = Color(0xFF0A313D);
const secondaryFgColor = Color(0xFFFBFDFE);
const accentColor = Color(0xFFDF5F34);
const accentFgColor = Color(0xFF05181F);

const colorScheme = ColorScheme(
  brightness: Brightness.dark,
  background: backgroundColor,
  onBackground: textColor,
  primary: primaryColor,
  onPrimary: primaryFgColor,
  secondary: secondaryColor,
  onSecondary: secondaryFgColor,
  tertiary: accentColor,
  onTertiary: accentFgColor,
  surface: backgroundColor,
  onSurface: textColor,
  error: Brightness.dark == Brightness.light
      ? Color(0xffB3261E)
      : Color(0xffF2B8B5),
  onError: Brightness.dark == Brightness.light
      ? Color(0xffFFFFFF)
      : Color(0xff601410),
);

class FigmaTextStyles {
  const FigmaTextStyles();

  static TextStyle get header => const TextStyle(
        fontSize: 28,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        color: textColor,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w700,
        height: 28 / 28,
        letterSpacing: 0,
      );

  static TextStyle get regular => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        color: textColor,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w500,
        height: 16 / 16,
        letterSpacing: 0,
      );

  static TextStyle get bold => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        color: textColor,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w900,
        height: 16 / 16,
        letterSpacing: 0,
      );

  static TextStyle get icons => const TextStyle(
        fontSize: 16,
        decoration: TextDecoration.none,
        fontStyle: FontStyle.normal,
        color: textColor,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        height: 16 / 16,
        letterSpacing: 0,
      );
}
