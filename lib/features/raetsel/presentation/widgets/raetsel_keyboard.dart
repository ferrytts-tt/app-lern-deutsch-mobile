import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Clavier virtuel spécialisé pour Hoppla Rätsel (mots croisés / Crostic).
/// Dispose les lettres allemandes réelles : Ä, Ö, Ü, ß
/// et gère à la fois les appuis tactiles et les frappes clavier physique (Web/Desktop).
class RaetselKeyboard extends StatelessWidget {
  final void Function(String letter) onKeyPressed;
  final VoidCallback onBackspace;
  final bool isDark;

  const RaetselKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    this.isDark = true,
  });

  static const List<String> _row1 = ['Q', 'W', 'E', 'R', 'T', 'Z', 'U', 'I', 'O', 'P', 'Ü'];
  static const List<String> _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'Ö', 'Ä'];
  static const List<String> _row3 = ['Y', 'X', 'C', 'V', 'B', 'N', 'M', 'ß'];

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final keyBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final keyBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow(_row1, keyBgColor, keyBorderColor, textColor),
            const SizedBox(height: 6),
            _buildRow(_row2, keyBgColor, keyBorderColor, textColor),
            const SizedBox(height: 6),
            _buildRowWithBackspace(_row3, keyBgColor, keyBorderColor, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, Color keyBg, Color keyBorder, Color text) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: _buildKey(
              label: key,
              keyBg: keyBg,
              keyBorder: keyBorder,
              textColor: text,
              onTap: () => onKeyPressed(key),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRowWithBackspace(List<String> keys, Color keyBg, Color keyBorder, Color text) {
    return Row(
      children: [
        ...keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: _buildKey(
                label: key,
                keyBg: keyBg,
                keyBorder: keyBorder,
                textColor: text,
                onTap: () => onKeyPressed(key),
              ),
            ),
          );
        }),
        // Touche retour arrière (Backspace)
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Material(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
              elevation: 1,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBackspace();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.backspace_outlined,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKey({
    required String label,
    required Color keyBg,
    required Color keyBorder,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: keyBg,
      borderRadius: BorderRadius.circular(8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: keyBorder, width: 0.8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
