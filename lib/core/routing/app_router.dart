import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/home/presentation/pages/home_page.dart';

import '../../features/home/presentation/pages/starred_page.dart';
import '../../features/topics/presentation/pages/topic_detail_page.dart';
import '../../features/topics/presentation/pages/topic_list_page.dart';
import '../../features/topics/presentation/pages/topic_form_page.dart';

import '../../features/words/presentation/pages/library_topic_list_page.dart';
import '../../features/words/presentation/pages/word_detail_page.dart';
import '../../features/words/presentation/pages/word_list_page.dart';
import '../../features/words/presentation/pages/word_form_page.dart';

import '../../features/practice/presentation/pages/practice_list_page.dart';
import '../../features/practice/presentation/pages/flashcard_page.dart';
import '../../features/practice/presentation/pages/matching_page.dart';

import 'app_routes.dart';
import 'go_router_refresh_change.dart';

class AppRouter {
  static final _navKey = GlobalKey<NavigatorState>();
  static final _refresh = GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges());

  static final GoRouter router = GoRouter(
    navigatorKey: _navKey,
    initialLocation: AppRoutes.login,
    refreshListenable: _refresh,
    redirect: (ctx, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final onAuth = state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.signup;
      if (!loggedIn && !onAuth) return AppRoutes.login;
      if (loggedIn && onAuth) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.home,   builder: (_, __) => const HomePage()),
      GoRoute(path: AppRoutes.login,  builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.signup, builder: (_, __) => const SignupPage()),

      GoRoute(path: AppRoutes.topics, builder: (_, __) => const TopicListPage()),
      GoRoute(path: AppRoutes.topicForm, builder: (_, __) => const TopicFormPage()),

      GoRoute(path: AppRoutes.library, builder: (_, __) => const LibraryTopicListPage()),
      GoRoute(
        path: AppRoutes.libraryWords,
        builder: (ctx, state) => WordListPage(topicId: state.uri.queryParameters['topicId']!),
      ),
      GoRoute(
        path: AppRoutes.wordForm,
        builder: (ctx, state) => WordFormPage(topicId: state.uri.queryParameters['topicId']!, wordId: state.uri.queryParameters['wordId']),
      ),

      GoRoute(path: AppRoutes.practice, builder: (_, __) => const PracticeListPage()),
      GoRoute(
        path: AppRoutes.practiceFlashcard,
        builder: (ctx, state) => FlashcardPage(topicId: state.uri.queryParameters['topicId']!, total: int.tryParse(state.uri.queryParameters['total'] ?? '6') ?? 6),
      ),
      GoRoute(
        path: AppRoutes.practiceMatching,
        builder: (ctx, state) => MatchingPage(topicId: state.uri.queryParameters['topicId']!, total: int.tryParse(state.uri.queryParameters['total'] ?? '6') ?? 6),
      ),
      GoRoute(
        path: '/topics/detail/:topicId',
        builder: (ctx, state) => TopicDetailPage(topicId: state.pathParameters['topicId']!),
      ),
      GoRoute(
        path: '/words/detail/:wordId',
        builder: (ctx, state) => WordDetailPage(wordId: state.pathParameters['wordId']!),
      ),
      GoRoute(
        path: AppRoutes.starred,
        name: 'starred',
        builder: (context, state) => const StarredPage(),
      ),
    ],
  );
}
