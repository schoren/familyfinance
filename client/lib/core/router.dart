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

final routerProvider = Provider<GoRouter>((ref) {
  print('DEBUG: GoRouter instance created');
  // Use a stable router by not watching authState here directly for the whole object recreation
  // Instead, we can use a listenable to trigger refreshes.
  
  final listenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login';
      
      if (!authState.isAuthenticated) {
        if (loggingIn) return null;
        
        // Preserve query parameters (like ?code=...) when redirecting to login
        final query = state.uri.queryParameters;
        if (query.isNotEmpty) {
          return Uri(path: '/login', queryParameters: query).toString();
        }
        return '/login';
      }
      if (loggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
        path: '/manage-accounts',
        builder: (context, state) => const ManageAccountsScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const AccountFormScreen(),
          ),
          GoRoute(
            path: 'edit/:accountId',
            builder: (context, state) {
              final accountId = state.pathParameters['accountId']!;
              return AccountFormScreen(accountId: accountId);
            },
          ),
        ],
      ),
    ],
  );
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    _subscription = ref.listen(authProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
