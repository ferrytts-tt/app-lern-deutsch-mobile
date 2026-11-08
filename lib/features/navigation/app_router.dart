import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../admin/presentation/admin_categories_screen.dart';
import '../admin/presentation/admin_dashboard_screen.dart';
import '../admin/presentation/admin_edit_phrase_screen.dart';
import '../auth/presentation/auth_screen.dart';
import '../home/presentation/home_screen.dart';
import '../library/presentation/library_screen.dart';
import '../library/presentation/phrase_detail_screen.dart';
import '../library/presentation/topic_phrases_screen.dart';
import '../master_xp/presentation/master_xp_screen.dart';
import '../onboarding/presentation/onboarding_screen.dart';
import '../palier_exam/presentation/palier_exam_screen.dart';
import '../progress/presentation/progress_screen.dart';
import '../session/presentation/session_screen.dart';
import '../settings/presentation/settings_screen.dart';
import '../splash/presentation/splash_screen.dart';
import '../../core/services/subscription_service.dart';
import '../../domain/models/media_content.dart';
import '../../domain/models/phrase.dart';
import '../media/presentation/media_player_screen.dart';
import '../media/presentation/media_section_screen.dart';
import '../raetsel/presentation/raetsel_hub_screen.dart';
import 'main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorHome =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellNavigatorLibrary =
    GlobalKey<NavigatorState>(debugLabel: 'shellLibrary');
final GlobalKey<NavigatorState> _shellNavigatorRaetsel =
    GlobalKey<NavigatorState>(debugLabel: 'shellRaetsel');
final GlobalKey<NavigatorState> _shellNavigatorProgress =
    GlobalKey<NavigatorState>(debugLabel: 'shellProgress');
final GlobalKey<NavigatorState> _shellNavigatorSettings =
    GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

/// Configuration déclarative GoRouter avec barre de navigation en bas.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    // Si Supabase renvoie une URL avec erreur ou callback OAuth sur la racine
    if (state.uri.queryParameters.containsKey('error') ||
        state.uri.queryParameters.containsKey('error_description')) {
      return '/auth';
    }
    return null;
  },
  errorBuilder: (context, state) => const AuthScreen(),
  routes: [
    // 1. Splash Screen
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // 2. Onboarding (plein écran, sans barre)
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // 2.1 Authentification / Espace Candidat
    GoRoute(
      path: '/auth',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AuthScreen(),
    ),

    // 3. Séance plein écran
    GoRoute(
      path: '/session',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final isExpress = state.uri.queryParameters['mode'] == 'express';
        final phraseIds = state.extra as List<String>?;
        return SessionScreen(isExpressMode: isExpress, targetPhraseIds: phraseIds);
      },
    ),

    // 3.1 Master XP (Défi des 10 phrases)
    GoRoute(
      path: '/master-xp',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final phraseIds = state.extra as List<String>?;
        return MasterXpScreen(initialPhraseIds: phraseIds);
      },
    ),

    // 3.2 Grand Examen de Palier (Tous les 30 phrases)
    GoRoute(
      path: '/palier-exam',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final palier = int.tryParse(state.uri.queryParameters['palier'] ?? '1') ?? 1;
        final phrases = state.extra as List<Phrase>?;
        return PalierExamScreen(palierIndex: palier, phrases: phrases);
      },
    ),

    // 3.3 Lecteur Chansons & Dialogues (plein écran)
    GoRoute(
      path: '/media-player',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final item = state.extra as MediaItem;
        return MediaPlayerScreen(item: item);
      },
    ),

    // 3.4 Rubrique Chansons & Dialogues (liste des lots)
    GoRoute(
      path: '/chansons-dialogues',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MediaSectionScreen(),
    ),

    // 3.5 Espace Administrateur (Strictement réservé à l'administrateur connecté)
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        if (!SubscriptionService.instance.isAdmin) {
          return '/settings';
        }
        return '/admin/dashboard';
      },
      builder: (context, state) => const AdminDashboardScreen(),
      routes: [
        GoRoute(
          path: 'dashboard',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!SubscriptionService.instance.isAdmin) {
              return '/settings';
            }
            return null;
          },
          builder: (context, state) => const AdminDashboardScreen(),
          routes: [
            GoRoute(
              path: 'edit-phrase',
              parentNavigatorKey: _rootNavigatorKey,
              redirect: (context, state) {
                if (!SubscriptionService.instance.isAdmin) {
                  return '/settings';
                }
                return null;
              },
              builder: (context, state) => AdminEditPhraseScreen(
                phrase: state.extra as Phrase?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'categories',
          parentNavigatorKey: _rootNavigatorKey,
          redirect: (context, state) {
            if (!SubscriptionService.instance.isAdmin) {
              return '/settings';
            }
            return null;
          },
          builder: (context, state) => const AdminCategoriesScreen(),
        ),
      ],
    ),

    // 4. Shell principal avec les 4 onglets
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Onglet 1 : Accueil
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHome,
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Onglet 2 : Phrases (Bibliothèque)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorLibrary,
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: 'topic/:id',
                  builder: (context, state) => TopicPhrasesScreen(
                    topicId: state.pathParameters['id'] ?? '',
                  ),
                ),
                GoRoute(
                  path: 'phrase/:id',
                  builder: (context, state) => PhraseDetailScreen(
                    phraseId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),

        // Onglet 3 : Hoppla Rätsel (Mots croisés à niveaux)
        StatefulShellBranch(
          navigatorKey: _shellNavigatorRaetsel,
          routes: [
            GoRoute(
              path: '/raetsel',
              builder: (context, state) => const RaetselHubScreen(),
            ),
          ],
        ),

        // Onglet 4 : Progrès
        StatefulShellBranch(
          navigatorKey: _shellNavigatorProgress,
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),

        // Onglet 4 : Réglages
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettings,
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
