import 'package:keda/providers/auth_provider.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/views/members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../utils/test_utils.dart';

import '../providers_test.mocks.dart';

void main() {
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  testWidgets('MembersScreen shows active and pending members correctly', (tester) async {
    when(mockApiClient.getMembers()).thenAnswer((_) async => [
          {
            'id': 'user1',
            'name': 'Active User',
            'email': 'active@example.com',
            'status': 'active'
          },
          {
            'id': 'invite1',
            'name': 'Invitado',
            'email': 'pending@example.com',
            'status': 'pending',
            'invite_code': 'CODE123'
          },
        ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          authProvider.overrideWith(() => MockAuthNotifier()), // Default auth state
        ],
        child: createTestApp(home: const MembersScreen()),
      ),
    );

    // Wait for future builder
    await tester.pumpAndSettle();

    // Verify Active User
    expect(find.text('Active User (Tú)'), findsOneWidget); // Assuming default auth user is empty? Wait, authProvider logic needs check.
    // Ideally I should mock AuthNotifier or set its state.
    // But let's check basic text presence first.
    
    // Verify Pending User
    expect(find.text('Invitado (Pendiente)'), findsOneWidget);
    
    // Verify Copy Button presence
    expect(find.byIcon(Icons.copy), findsOneWidget);

    // Verify Delete Button presence for active (non-me)
    // 'Active User' (user1) is me? Mock says yes: userId: 'user1'.
    // So user1 is ME. No delete button for ME.

    // Verify Delete Button presence for pending
    // Pending user is 'invite1'. Not me. Should have delete button.
    expect(find.widgetWithIcon(IconButton, Icons.delete), findsOneWidget);

    // Test Delete Action
    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete));
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Eliminar Miembro'), findsOneWidget);
    expect(find.text('¿Estás seguro de que quieres eliminar a Invitado del hogar?'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // Verify API called verify(mockApiClient.removeMember('invite1')).called(1);
    verify(mockApiClient.removeMember('invite1')).called(1);
  });

  testWidgets('Invite Dialog handles 409 Conflict', (tester) async {
    when(mockApiClient.getMembers()).thenAnswer((_) async => []);
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
          authProvider.overrideWith(() => MockAuthNotifier()),
        ],
        child: createTestApp(home: const MembersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Open Invite Dialog
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    // Enter email
    await tester.enterText(find.byType(TextField), 'dup@example.com');
    
    // Mock 409 Error
    when(mockApiClient.createInvitation('dup@example.com'))
        .thenThrow(Exception('409 Conflict'));

    // Click Send
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle(); // Dialog closes? No, logic says Navigator.pop BEFORE api call? 
    // Wait, I changed it to pop first?
    // Let's check code:
    // try {
    //   await ref.read(apiClientProvider).createInvitation(email);
    //   if (mounted) { Navigator.pop(context); ... }
    // } catch... (dialog stays open? or shows snackbar on top of screen?)
    
    // Actually, looking at my previous edit:
    // try {
    //   Navigator.pop(context); // Pops dialog immediately
    //   await ...
    // ...
    
    // So dialog is gone. Snackbar should appear.
    // SnackBar detection might need a long pump or checks.
    
    expect(find.text('Este usuario ya tiene una invitación pendiente'), findsOneWidget);
  });
}

class MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      isAuthenticated: true,
      userId: 'user1',
      userName: 'Active User',
      userEmail: 'active@example.com',
      householdId: 'household1',
    );
  }
}
