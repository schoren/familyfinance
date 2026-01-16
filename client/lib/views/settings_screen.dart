import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_providers.dart';
import '../core/runtime_config.dart';
import '../widgets/user_avatar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String?>(
              value: settings.locale?.languageCode,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.systemDefault),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text(l10n.spanish),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(l10n.english),
                ),
              ],
              onChanged: (String? value) {
                ref.read(settingsProvider.notifier).setLanguage(value);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.versionInfo),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.clientVersion}: ${RuntimeConfig.appVersion}',
                ),
                ref.watch(serverVersionProvider).when(
                  data: (version) => Text('${l10n.serverVersion}: $version'),
                  loading: () => Text('${l10n.serverVersion}: ${l10n.loading}'),
                  error: (_, __) => Text('${l10n.serverVersion}: ${l10n.error}'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
