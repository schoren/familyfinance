import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Keda',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            // Set invite code if present (needed for web flow)
            Builder(
              builder: (context) {
                final inviteCode = GoRouterState.of(context).uri.queryParameters['code'];
                if (inviteCode != null) {
                  // Defer state update to avoid build collisions
                  Future.microtask(() => ref.read(authProvider.notifier).setPendingInviteCode(inviteCode));
                }
                
                return FutureBuilder(
                  future: ref.read(authProvider.notifier).ensureGoogleSignInInitialized(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                       return Text(l10n.errorInitializingGoogleSignIn(snapshot.error.toString()));
                    }

                    return buildGoogleSignInButton(
                      onPressed: () async {
                        // Mobile/Stub flow
                        try {
                          await ref.read(authProvider.notifier).loginWithGoogle(inviteCode: inviteCode);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    );
                  }
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}
