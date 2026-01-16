import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Miembro'),
        content: Text('¿Estás seguro de que quieres eliminar a $memberName del hogar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
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
            const SnackBar(content: Text('Miembro eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
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
      const SnackBar(content: Text('Enlace de invitación copiado al portapapeles')),
    );
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();

    void submit() async {
      final email = emailController.text.trim();
      if (email.isEmpty) return;

      try {
        await ref.read(apiClientProvider).createInvitation(email);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invitación enviada con éxito')),
          );
          _loadMembers(); // Refresh list
        }
      } catch (e) {
        if (mounted) {
          String message = 'Error al enviar invitación: $e';
          if (e.toString().contains('409') || e.toString().contains('Invitation already pending')) {
            message = 'Este usuario ya tiene una invitación pendiente';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invitar Miembro'),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: submit,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(authProvider).userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Miembros del Hogar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invitar',
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final members = snapshot.data ?? [];

          return ListView.builder(
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
                  member['name'] + (isMe ? ' (Tú)' : '') + (isPending ? ' (Pendiente)' : ''),
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
                        tooltip: 'Copiar enlace',
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
          );
        },
      ),
    );
  }
}
