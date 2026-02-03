import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../views/home_screen.dart';
import '../views/login_screen.dart';
import '../views/new_expense_screen.dart';
import '../views/category_detail_screen.dart';
import '../views/manage_category_screen.dart';
import '../views/manage_accounts_screen.dart';
import '../views/account_form_screen.dart';
import '../views/members_screen.dart';
import '../views/expenses_screen.dart';

import '../views/navigation_shell.dart';
import '../views/settings_screen.dart';
import '../views/initial_splash_screen.dart';
import '../views/server_settings_screen.dart';


final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorAccountsKey = GlobalKey<NavigatorState>(debugLabel: 'shellAccounts');
final _shellNavigatorMembersKey = GlobalKey<NavigatorState>(debugLabel: 'shellMembers');
final _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

final routerProvider = Provider<GoRouter>((ref) {
  debugPrint('DEBUG: GoRouter instance created');
  final listenable = _AuthListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: listenable,

    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login';
      final splashing = state.matchedLocation == '/splash';
      final settingServer = state.matchedLocation == '/server-settings';
      
      if (authState.isInitialLoading) {
        return splashing ? null : '/splash';
      }

      if (!authState.isAuthenticated) {
        if (loggingIn || settingServer) return null;
        final query = state.uri.queryParameters;
        if (query.isNotEmpty) {
          return Uri(path: '/login', queryParameters: query).toString();
        }
        return '/login';
      }

      if (loggingIn || splashing) {
        return '/';
      }

      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorAccountsKey,
            routes: [
              GoRoute(
                path: '/manage-accounts',
                builder: (context, state) => const ManageAccountsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AccountFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:accountId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final accountId = state.pathParameters['accountId']!;
                      return AccountFormScreen(accountId: accountId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMembersKey,
            routes: [
              GoRoute(
                path: '/members',
                builder: (context, state) => const MembersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/invite',
        redirect: (context, state) => Uri(path: '/login', queryParameters: state.uri.queryParameters).toString(),
      ),
      GoRoute(
        path: '/category/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return CategoryDetailScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/new-expense/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return NewExpenseScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/edit-expense/:expenseId',
        builder: (context, state) {
          final expenseId = state.pathParameters['expenseId']!;
          return NewExpenseScreen(expenseId: expenseId);
        },
      ),
      GoRoute(
        path: '/manage-category/new',
        builder: (context, state) => const ManageCategoryScreen(),
      ),
      GoRoute(
        path: '/manage-category/edit/:categoryId',
        builder: (context, state) {
          final id = state.pathParameters['categoryId'];
          return ManageCategoryScreen(categoryId: id);
        },
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const InitialSplashScreen(),
      ),
      GoRoute(
        path: '/server-settings',
        builder: (context, state) => const ServerSettingsScreen(),
      ),
    ],

  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    _subscription = ref.listen(authProvider, (_, _) => notifyListeners());
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
