import 'package:flutter/material.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/phrase.dart';
import '../../../domain/models/topic.dart';

/// Écran d'ajout ou d'édition d'une phrase par l'administrateur / formateur.
class AdminEditPhraseScreen extends StatefulWidget {
  final Phrase? phrase;

  const AdminEditPhraseScreen({super.key, this.phrase});

  @override
  State<AdminEditPhraseScreen> createState() => _AdminEditPhraseScreenState();
}

class _AdminEditPhraseScreenState extends State<AdminEditPhraseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tts = TtsService.instance;

  late final TextEditingController _deController;
  late final TextEditingController _frController;
  late final TextEditingController _arController;
  late final TextEditingController _noteController;

  late String _selectedTopic;
  late String _selectedCefr;
  bool _isSaving = false;
  bool _isPlayingAudio = false;
  List<TopicInfo> _topics = List.from(TopicInfo.allTopics);

  bool get _isEditing => widget.phrase != null;

  @override
  void initState() {
    super.initState();
    final p = widget.phrase;
    _deController = TextEditingController(text: p?.de ?? '');
    _frController = TextEditingController(text: p?.fr ?? '');
    _arController = TextEditingController(text: p?.ar ?? '');
    _noteController = TextEditingController(text: p?.note ?? '');
    _selectedTopic = p?.topic ?? (_topics.isNotEmpty ? _topics.first.id : 'salutations');
    _selectedCefr = p?.cefr ?? 'A1';

    _loadTopics();
    _tts.isPlayingNotifier.addListener(_onTtsStateChanged);
  }

  Future<void> _loadTopics() async {
    final list = await AppDatabase.instance.getAllTopics();
    if (mounted && list.isNotEmpty) {
      setState(() {
        _topics = list;
        if (!_topics.any((t) => t.id == _selectedTopic)) {
          _selectedTopic = _topics.first.id;
        }
      });
    }
  }

  Future<void> _addNewTopic() async {
    final titleController = TextEditingController();
    final deController = TextEditingController();
    final created = await showDialog<TopicInfo>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nom en français *',
                hintText: 'ex: Voyages & Vacances',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: deController,
              decoration: const InputDecoration(
                labelText: 'Nom en allemand',
                hintText: 'ex: Reisen & Urlaub',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final id = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
              final t = TopicInfo(
                id: id,
                title: title,
                germanTitle: deController.text.trim().isNotEmpty ? deController.text.trim() : title,
                icon: Icons.folder_rounded,
                themeColor: const Color(0xFF2FA866),
                order: _topics.length + 1,
              );
              Navigator.of(ctx).pop(t);
            },
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (created != null) {
      await AppDatabase.instance.saveTopic(created);
      await _loadTopics();
      if (mounted) {
        setState(() => _selectedTopic = created.id);
      }
    }
  }

  void _onTtsStateChanged() {
    if (mounted) setState(() => _isPlayingAudio = _tts.isPlaying);
  }

  @override
  void dispose() {
    _tts.isPlayingNotifier.removeListener(_onTtsStateChanged);
    _deController.dispose();
    _frController.dispose();
    _arController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _testAudio() async {
    final text = _deController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir une phrase en allemand pour écouter.')),
      );
      return;
    }
    await _tts.speak(text);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final phrase = Phrase(
        id: widget.phrase?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
        topic: _selectedTopic,
        cefr: _selectedCefr,
        de: _deController.text.trim(),
        fr: _frController.text.trim(),
        ar: _arController.text.trim().isNotEmpty ? _arController.text.trim() : null,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      );

      await AppDatabase.instance.savePhrase(phrase);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: Text(
              _isEditing ? 'Phrase mise à jour avec succès !' : 'Nouvelle phrase ajoutée !',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.gentleError,
            content: Text('Erreur lors de l\'enregistrement : $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la phrase' : 'Nouvelle phrase'),
        actions: [
          IconButton(
            tooltip: 'Tester la prononciation',
            icon: Icon(
              _isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              color: AppColors.primary,
            ),
            onPressed: _testAudio,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info d'aide
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2F22) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Les candidats étudieront cette phrase avec le tunnel complet en 7 étapes (Lecture, Traductions FR/AR, 3 Vitesses audio, Dictée, Exemples, SRS).',
                          style: AppTextStyles.caption(isDark: isDark).copyWith(
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 1. Phrase en Allemand (DE)
                _buildFieldLabel('Phrase en Allemand (Deutsch) *', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _deController,
                  maxLines: 2,
                  style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(fontWeight: FontWeight.bold),
                  decoration: _buildInputDecoration(
                    hint: 'ex: Wie geht es Ihnen heute?',
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
                      onPressed: _testAudio,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'La phrase en allemand est obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // 2. Traduction en Français (FR)
                _buildFieldLabel('Traduction en Français (Français) *', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _frController,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium(isDark: isDark),
                  decoration: _buildInputDecoration(
                    hint: 'ex: Comment allez-vous aujourd\'hui ?',
                    isDark: isDark,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'La traduction française est obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // 3. Traduction en Arabe (AR)
                _buildFieldLabel('Traduction en Arabe (العربية)', isDark),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: TextFormField(
                    controller: _arController,
                    maxLines: 2,
                    textDirection: TextDirection.rtl,
                    style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
                      color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _buildInputDecoration(
                      hint: 'كيف حالكم اليوم؟',
                      isDark: isDark,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 4. Thématique & Niveau CEFR
                Row(
                  children: [
                    // Topic
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFieldLabel('Thématique', isDark),
                              InkWell(
                                onTap: _addNewTopic,
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    '+ Nouvelle',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            key: ValueKey('topic_dropdown_${_selectedTopic}_${_topics.length}'),
                            initialValue: _selectedTopic,
                            isExpanded: true,
                            decoration: _buildInputDecoration(hint: '', isDark: isDark),
                            items: _topics.map((t) {
                              return DropdownMenuItem(
                                value: t.id,
                                child: Row(
                                  children: [
                                    Icon(t.icon, size: 16, color: t.themeColor),
                                    const SizedBox(width: 8),
                                    Flexible(child: Text(t.title, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTopic = val);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // CEFR
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Niveau', isDark),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCefr,
                            decoration: _buildInputDecoration(hint: '', isDark: isDark),
                            items: const ['A1', 'A2', 'B1', 'B2'].map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCefr = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 5. Note pédagogique ou culturelle
                _buildFieldLabel('Note grammaticale / astuce (optionnelle)', isDark),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  style: AppTextStyles.bodyMedium(isDark: isDark),
                  decoration: _buildInputDecoration(
                    hint: 'ex: Ihnen = vouvoiement formel avec majuscule.',
                    isDark: isDark,
                  ),
                ),

                const SizedBox(height: 28),

                PrimaryButton(
                  label: _isSaving ? 'Enregistrement en cours...' : (_isEditing ? 'Mettre à jour la phrase' : 'Ajouter la phrase'),
                  icon: Icons.check_circle_rounded,
                  onPressed: _isSaving ? null : _save,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
