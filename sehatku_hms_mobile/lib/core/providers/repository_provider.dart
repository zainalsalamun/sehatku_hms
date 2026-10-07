import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/hms_api_client.dart';
import 'api_client_provider.dart';

final hmsRepositoryProvider = Provider<HmsApiClient>((ref) {
  return ref.watch(apiClientProvider);
});
