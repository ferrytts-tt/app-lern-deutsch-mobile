import 'package:flutter/material.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/arabic_text_view.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/topic.dart';
import 'admin_categories_screen.dart';
import 'admin_edit_phrase_screen.dart';

/// Tableau de bord administrateur / formateur pour la gestion complète du catalogue de phrases.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AppDatabase _database = AppDatabase.instance;
  final TtsService _tts = TtsService.instance;

  bool _isLoading = true;
  List<Phrase> _allPhrases = [];
  List<Phrase> _filteredPhrases = [];

  String _searchQuery = '';
  String? _selectedTopicFilter;
  String? _playingPhraseId;

  @override
  void initState() {
    super.initState();
    _loadPhrases();
    _tts.isPlayingNotifier.addListener(() {
      if (!_tts.isPlaying && mounted) {
        setState(() => _playingPhraseId = null);
      }
    });
  }

  Future<void> _loadPhrases() async {
    setState(() => _isLoading = true);
    final phrases = await _database.getAllPhrases();
    if (mounted) {
      setState(() {
        _allPhrases = phrases;
        _filterPhrases();
        _isLoading = false;
      });
    }
  }

  void _filterPhrases() {
    final query = _searchQuery.trim().toLowerCase();
    setState(() {
      _filteredPhrases = _allPhrases.where((p) {
        final matchesQuery = query.isEmpty ||
            p.de.toLowerCase().contains(query) ||
            p.fr.toLowerCase().contains(query) ||
            (p.ar != null && p.ar!.contains(query));

        final matchesTopic =
            _selectedTopicFilter == null || p.topic == _selectedTopicFilter;

        return matchesQuery && matchesTopic;
      }).toList();
    });
  }

  Future<void> _playPhraseAudio(Phrase phrase) async {
    if (_playingPhraseId == phrase.id) {
      await _tts.stop();
      setState(() => _playingPhraseId = null);
    } else {
      setState(() => _playingPhraseId = phrase.id);
      await _tts.speak(phrase.de);
    }
  }

  Future<void> _confirmDelete(Phrase phrase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la phrase ?'),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement « ${phrase.de} » ainsi que toute la progression associée ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gentleError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _database.deletePhrase(phrase.id);
      await _loadPhrases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phrase supprimée avec succès')),
        );
      }
    }
  }

  Future<void> _openEditScreen([Phrase? phrase]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => AdminEditPhraseScreen(phrase: phrase),
      ),
    );
    if (result == true) {
      _loadPhrases();
    }
  }

  Future<void> _showImportLotDialog() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Importer un lot JSON'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Collez ici le JSON du lot de phrases quotidiennes (formats avec ou sans id). Les doublons par de_standard seront automatiquement filtrés et la progression utilisateur conservée.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '[\n  {\n    "theme": "travail",\n    "de_standard": "...",\n    "de_parle": "...",\n    "ar": "..."\n  }\n]',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            child: const Text('Importer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final count = await _database.importPhrasesFromJson(jsonContent: result);
        await _loadPhrases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count nouvelle(s) phrase(s) importée(s) ! Doublons ignorés.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'import : $e'),
              backgroundColor: AppColors.gentleError,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gestion des phrases'),
        actions: [
          IconButton(
            tooltip: 'Importer un lot JSON',
            icon: const Icon(Icons.file_upload_rounded, color: AppColors.primary),
            onPressed: _showImportLotDialog,
          ),
          IconButton(
            tooltip: 'Gérer les catégories',
            icon: const Icon(Icons.category_rounded, color: AppColors.secondary),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
              );
              _loadPhrases();
            },
          ),
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPhrases,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ajouter une phrase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _openEditScreen(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bandeau statistiques
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total', '${_allPhrases.length}', AppColors.primary),
                    _buildStatItem(
                      'A1',
                      '${_allPhrases.where((p) => p.cefr == 'A1').length}',
                      AppColors.secondary,
                    ),
                    _buildStatItem(
                      'A2',
                      '${_allPhrases.where((p) => p.cefr == 'A2').length}',
                      AppColors.accentDark,
                    ),
                    _buildStatItem(
                      'B1+',
                      '${_allPhrases.where((p) => p.cefr.startsWith('B')).length}',
                      const Color(0xFF9C27B0),
                    ),
                  ],
                ),
              ),
            ),

            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: TextField(
                onChanged: (val) {
                  _searchQuery = val;
                  _filterPhrases();
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher en allemand, français ou arabe...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Sélecteur de filtres par thématiques
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tous'),
                    selected: _selectedTopicFilter == null,
                    onSelected: (selected) {
                      setState(() => _selectedTopicFilter = null);
                      _filterPhrases();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...TopicInfo.allTopics.map((t) {
                    final isSelected = _selectedTopicFilter == t.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        avatar: Icon(t.icon, size: 14, color: isSelected ? Colors.white : t.themeColor),
                        label: Text(t.title),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedTopicFilter = selected ? t.id : null);
                          _filterPhrases();
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Liste des phrases
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filteredPhrases.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'Aucune phrase trouvée',
                                style: AppTextStyles.bodyMedium(isDark: isDark),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 80,
                          ),
                          itemCount: _filteredPhrases.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) {
                            final phrase = _filteredPhrases[i];
                            final topic = TopicInfo.getById(phrase.topic);
                            final isPlaying = _playingPhraseId == phrase.id;

                            return CustomCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Ligne en-tête carte
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: topic.themeColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              phrase.cefr,
                                              style: TextStyle(
                                                color: topic.themeColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            topic.title,
                                            style: TextStyle(
                                              color: topic.themeColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isPlaying ? Icons.pause_circle_filled_rounded : Icons.volume_up_rounded,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                            onPressed: () => _playPhraseAudio(phrase),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.secondary),
                                            onPressed: () => _openEditScreen(phrase),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.gentleError),
                                            onPressed: () => _confirmDelete(phrase),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  // Phrase en allemand
                                  Text(
                                    phrase.de,
                                    style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // Traduction française
                                  Text(
                                    phrase.fr,
                                    style: AppTextStyles.translation(isDark: isDark).copyWith(fontSize: 14),
                                  ),

                                  // Traduction arabe (si renseignée)
                                  if (phrase.ar != null && phrase.ar!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    ArabicTextView(
                                      text: phrase.ar!,
                                      fontSize: 13,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
