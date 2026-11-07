import 'package:flutter/material.dart';
import '../../../../../core/widgets/custom_card.dart';
import '../../../../../core/widgets/duolingo_word_composer.dart';
import '../../../../../domain/models/phrase.dart';
import '../../../../../domain/models/topic.dart';

/// Exercice de Niveau 2 : « Reconstituer / Composer la phrase » style Duolingo.
/// Supporte la composition en allemand à partir du français/arabe et vice-versa,
/// avec tuiles 3D, lignes de cahier et personnage animé.
class ReconstructExercise extends StatelessWidget {
  final Phrase targetPhrase;
  final bool isTtsPlaying;
  final VoidCallback onPlayAudio;
  final VoidCallback? onPlaySlow;
  final Function(bool isCorrect) onValidate;
  final ReconstructDirection? initialDirection;

  const ReconstructExercise({
    super.key,
    required this.targetPhrase,
    required this.isTtsPlaying,
    required this.onPlayAudio,
    this.onPlaySlow,
    required this.onValidate,
    this.initialDirection,
  });

  @override
  Widget build(BuildContext context) {
    final topic = TopicInfo.getById(targetPhrase.topic);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          CustomCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête du thème
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: topic.themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(topic.icon, size: 16, color: topic.themeColor),
                          const SizedBox(width: 6),
                          Text(
                            topic.title,
                            style: TextStyle(
                              color: topic.themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF58CC02).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.extension_rounded, size: 14, color: Color(0xFF58CC02)),
                          SizedBox(width: 4),
                          Text(
                            'Duolingo Mode',
                            style: TextStyle(
                              color: Color(0xFF58CC02),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Compositeur de mots Duolingo
                DuolingoWordComposer(
                  targetPhrase: targetPhrase,
                  isTtsPlaying: isTtsPlaying,
                  onPlayAudio: onPlayAudio,
                  onPlaySlow: onPlaySlow,
                  onValidate: onValidate,
                  initialDirection: initialDirection,
                  showDirectionSwitch: true,
                  embeddedInCard: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
