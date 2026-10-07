import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/hms_api_client.dart';

final apiClientProvider = Provider<HmsApiClient>((ref) {
  return const HmsApiClient();
});
