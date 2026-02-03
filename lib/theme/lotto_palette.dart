import 'package:flutter/material.dart';

Color lottoBallBaseColor(int number) {
  if (number <= 10) {
    return const Color(0xFFF2C94C);
  }
  if (number <= 20) {
    return const Color(0xFF4A90E2);
  }
  if (number <= 30) {
    return const Color(0xFFE74C3C);
  }
  if (number <= 40) {
    return const Color(0xFF8E8E93);
  }
  return const Color(0xFF2ECC71);
}

Color lottoBallGlowColor(int number) {
  final base = lottoBallBaseColor(number);
  return _adjustLightness(base, 0.12);
}

List<Color> lottoBallGradient(int number) {
  final base = lottoBallBaseColor(number);
  return [
    _adjustLightness(base, 0.18),
    base,
    _adjustLightness(base, -0.28),
  ];
}

Color _adjustLightness(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}
