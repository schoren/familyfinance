import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/user_avatar.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                UserAvatar(
                  radius: 40,
                  pictureUrl: authState.userPictureUrl,
                  name: authState.userName ?? 'Usuario',
                  color: authState.userColor,
                ),
                const SizedBox(height: 16),
                Text(
                  authState.userName ?? 'Usuario',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (authState.userEmail != null)
                  Text(
                    authState.userEmail!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Información de Versión'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Version Cliente: ${String.fromEnvironment('APP_VERSION', defaultValue: 'dev')}',
                ),
                ref.watch(serverVersionProvider).when(
                  data: (version) => Text('Versión Servidor: $version'),
                  loading: () => const Text('Versión Servidor: cargando...'),
                  error: (_, __) => const Text('Versión Servidor: error'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
