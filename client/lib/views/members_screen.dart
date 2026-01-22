import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/premium_refresh_indicator.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../providers/data_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/user_avatar.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  late Future<List<Map<String, dynamic>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() {
      _membersFuture = ref.read(apiClientProvider).getMembers();
    });
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeMember),
        content: Text(l10n.removeMemberConfirm(memberName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiClientProvider).removeMember(memberId);
        _loadMembers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.memberRemoved)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithDetails(e.toString()))),
          );
        }
      }
    }
  }

  void _copyInviteLink(String code) {
    String baseUrl;
    if (kIsWeb) {
      baseUrl = Uri.base.origin;
    } else {
      baseUrl = 'http://localhost:8080'; // Fallback / Dev default
    }
    final link = '$baseUrl/invite?code=$code';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.inviteLinkCopied)),
    );
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();

    void submit() async {
      final l10n = AppLocalizations.of(context)!;
      final email = emailController.text.trim();
      if (email.isEmpty) return;

      try {
        await ref.read(apiClientProvider).createInvitation(email);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.invitationSent)),
          );
          _loadMembers(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          String message = l10n.inviteError(e.toString());
          if (e.toString().contains('409') || e.toString().contains('Invitation already pending')) {
            message = l10n.invitePending;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    }

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.inviteMember),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'ejemplo@gmail.com',
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => submit(),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: submit,
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).userId;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.householdMembers),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.inviteTooltip,
            onPressed: _showInviteDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorWithDetails(snapshot.error.toString())));
          }

          final members = snapshot.data ?? [];

          return PremiumRefreshIndicator(
            onRefresh: () async {
              _loadMembers();
              // Wait for the future to complete
              await _membersFuture;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final isMe = member['id'] == currentUserId;
                final status = member['status'] ?? 'active';
                final isPending = status == 'pending';
                final inviteCode = member['invite_code'];

                return ListTile(
                  leading: isPending 
                    ? const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.mail, color: Colors.white),
                      )
                    : UserAvatar(
                        pictureUrl: member['picture_url'],
                        name: member['name'],
                        color: member['color'],
                      ),
                  title: Text(
                    member['name'] + (isMe ? l10n.youSuffix : '') + (isPending ? l10n.pendingSuffix : ''),
                    style: TextStyle(
                      fontStyle: isPending ? FontStyle.italic : FontStyle.normal,
                      color: isPending ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(member['email']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPending && inviteCode != null)
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: l10n.copyLinkTooltip,
                          onPressed: () => _copyInviteLink(inviteCode),
                        ),
                      
                      if (!isMe)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeMember(member['id'], member['name']),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
