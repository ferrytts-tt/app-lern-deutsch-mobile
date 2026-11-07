import 'package:flutter/material.dart';
import 'package:app_lern_deutsch_mobile/core/theme/app_colors.dart';

/// Modal d'affichage plein écran d'une annonce interstitielle.
/// N'apparaît qu'entre les niveaux (au maximum tous les 3 niveaux),
/// jamais pendant la partie.
class RaetselInterstitialAdDialog extends StatefulWidget {
  final VoidCallback onDismissed;
  final bool isDark;

  const RaetselInterstitialAdDialog({
    super.key,
    required this.onDismissed,
    this.isDark = true,
  });

  static Future<void> show(BuildContext context, {required VoidCallback onDismissed, bool isDark = true}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RaetselInterstitialAdDialog(
        onDismissed: () {
          Navigator.of(ctx).pop();
          onDismissed();
        },
        isDark: isDark,
      ),
    );
  }

  @override
  State<RaetselInterstitialAdDialog> createState() => _RaetselInterstitialAdDialogState();
}

class _RaetselInterstitialAdDialogState extends State<RaetselInterstitialAdDialog> {
  int _secondsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
        _startCountdown();
      } else {
        setState(() => _secondsRemaining = 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: bgColor,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ANNONCE SPONSORISÉE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                if (_secondsRemaining > 0)
                  Text(
                    'Fermeture dans $_secondsRemaining s',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white60 : Colors.black54,
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: widget.onDismissed,
                    tooltip: 'Fermer la publicité',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.campaign_rounded,
                    size: 64,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Espace Publicité Interstitielle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Google AdMob Interstitial (Plein écran)\nAffiché au plus tous les 3 niveaux.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _secondsRemaining == 0 ? widget.onDismissed : null,
                child: Text(
                  _secondsRemaining == 0 ? 'Continuer' : 'Patientez ($_secondsRemaining)...',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
