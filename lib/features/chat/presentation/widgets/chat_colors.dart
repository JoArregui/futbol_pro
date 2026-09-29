import 'package:flutter/material.dart';

/// Paleta del chat adaptada a claro/oscuro (estilo WhatsApp).
/// Centraliza los colores que antes estaban quemados y rompían el dark mode.
class ChatColors {
  const ChatColors._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Barra superior de lista y sala.
  static Color bar(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F2C34) : const Color(0xFF075E54);

  /// Fondo de la sala.
  static Color roomBackground(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B141A) : const Color(0xFFE5DDD5);

  /// Burbuja propia (verde, legible en ambos modos).
  static const Color myBubble = Color(0xFF005C4B);

  /// Burbuja ajena.
  static Color otherBubble(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F2C34) : Colors.white;

  static Color otherText(BuildContext context) =>
      isDark(context) ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);

  /// Texto secundario (horas, previews, hints).
  static Color subtle(BuildContext context) =>
      isDark(context) ? const Color(0xFF8696A0) : const Color(0xFF667781);

  /// Barra del input y campo de texto.
  static Color inputBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F2C34) : const Color(0xFFF0F0F0);

  static Color inputField(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A3942) : Colors.white;

  /// Chip de fecha y typing.
  static Color chip(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F2C34) : const Color(0xFFE1F2FA);

  static const Color accent = Color(0xFF25D366);
  static const Color tickRead = Color(0xFF53BDEB);
}
