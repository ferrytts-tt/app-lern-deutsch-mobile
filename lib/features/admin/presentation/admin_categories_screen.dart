import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/models/topic.dart';

/// Écran d'administration des catégories / thématiques.
/// Permet à l'administrateur d'ajouter, modifier et supprimer des catégories.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final AppDatabase _database = AppDatabase.instance;
  bool _isLoading = true;
  List<TopicInfo> _topics = [];

  static const List<Color> _availableColors = [
    Color(0xFF2FA866), // Vert émeraude
    Color(0xFF2F80ED), // Bleu ciel
    Color(0xFFFFC83D), // Jaune ambre
    Color(0xFFF59E4B), // Orange
    Color(0xFF9C27B0), // Violet
    Color(0xFFE91E63), // Rose
    Color(0xFF009688), // Sarcelle
  ];

  static const List<IconData> _availableIcons = [
    Icons.waving_hand_rounded,
    Icons.person_rounded,
    Icons.chat_bubble_rounded,
    Icons.restaurant_rounded,
    Icons.explore_rounded,
    Icons.shopping_bag_rounded,
    Icons.train_rounded,
    Icons.local_hospital_rounded,
    Icons.home_rounded,
    Icons.work_rounded,
    Icons.sports_esports_rounded,
    Icons.groups_rounded,
    Icons.favorite_rounded,
    Icons.flight_takeoff_rounded,
    Icons.hotel_rounded,
    Icons.school_rounded,
    Icons.menu_book_rounded,
    Icons.music_note_rounded,
    Icons.pets_rounded,
    Icons.nature_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    final list = await _database.getAllTopics();
    if (mounted) {
      setState(() {
        _topics = list;
        _isLoading = false;
      });
    }
  }

  void _openTopicDialog([TopicInfo? topic]) {
    final isEditing = topic != null;
    final titleController = TextEditingController(text: topic?.title ?? '');
    final germanTitleController = TextEditingController(text: topic?.germanTitle ?? '');
    Color selectedColor = topic?.themeColor ?? _availableColors.first;
    IconData selectedIcon = topic?.icon ?? _availableIcons.first;
    final orderController = TextEditingController(text: '${topic?.order ?? (_topics.length + 1)}');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nom en Français *',
                      hintText: 'ex: Voyages & Vacances',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: germanTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Nom en Allemand (Deutsch)',
                      hintText: 'ex: Reisen & Urlaub',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Numéro d\'ordre d\'affichage',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Couleur du thème :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availableColors.map((color) {
                      final isSelected = selectedColor.toARGB32() == color.toARGB32();
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                                : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Icône représentative :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    width: double.maxFinite,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, i) {
                        final icon = _availableIcons[i];
                        final isSelected = selectedIcon.codePoint == icon.codePoint;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? selectedColor.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? selectedColor : (isDark ? Colors.grey[800]! : Colors.grey[300]!),
                              ),
                            ),
                            child: Icon(icon, color: isSelected ? selectedColor : Colors.grey),
                          ),
                        );
                      },
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
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;

                  final id = topic?.id ??
                      title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

                  final newTopic = TopicInfo(
                    id: id,
                    title: title,
                    germanTitle: germanTitleController.text.trim().isNotEmpty
                        ? germanTitleController.text.trim()
                        : title,
                    icon: selectedIcon,
                    themeColor: selectedColor,
                    order: int.tryParse(orderController.text.trim()) ?? (_topics.length + 1),
                  );

                  await _database.saveTopic(newTopic);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  _loadTopics();
                },
                child: Text(isEditing ? 'Mettre à jour' : 'Ajouter', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(TopicInfo topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        content: Text(
          'Voulez-vous supprimer « ${topic.title} » ? Les phrases associées resteront enregistrées.',
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
      await _database.deleteTopic(topic.id);
      _loadTopics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Gestion des catégories'),
        actions: [
          IconButton(
            tooltip: 'Ajouter une catégorie',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openTopicDialog(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nouvelle catégorie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openTopicDialog(),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
                itemCount: _topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final topic = _topics[i];
                  return CustomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: topic.themeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(topic.icon, color: topic.themeColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topic.title,
                                style: AppTextStyles.bodyLarge(isDark: isDark).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (topic.germanTitle.isNotEmpty)
                                Text(
                                  topic.germanTitle,
                                  style: AppTextStyles.caption(isDark: isDark).copyWith(
                                    color: topic.themeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${topic.order}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.secondary, size: 20),
                          onPressed: () => _openTopicDialog(topic),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.gentleError, size: 20),
                          onPressed: () => _confirmDelete(topic),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
