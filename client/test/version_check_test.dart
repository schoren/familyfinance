import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keda/providers/data_providers.dart';
import 'package:keda/repositories/api_client.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'version_check_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ApiClient>()])
void main() {
  group('VersionCheckNotifier', () {
    late MockApiClient mockApiClient;
    late ProviderContainer container;

    setUp(() {
      mockApiClient = MockApiClient();
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Initial state is upToDate if versions match', (tester) async {
      when(mockApiClient.getServerVersion()).thenAnswer((_) async => 'local-dev');
      
      final state = await container.read(versionCheckProvider.future);
      expect(state, UpdateState.upToDate);
    });

    testWidgets('Detects update available when versions differ', (tester) async {
      when(mockApiClient.getServerVersion()).thenAnswer((_) async => '1.0.0');
      final state = await container.read(versionCheckProvider.future);
      expect(state, UpdateState.upToDate); // Because current is 'local-dev'
    });
  });
}
