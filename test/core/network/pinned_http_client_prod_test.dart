import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi_mobile/api/urls.dart';
import 'package:epresensi_mobile/core/network/pinned_http_client.dart';

void main() {
  test(
    'production certificate pin accepts the live API certificate',
    () async {
      final client = PinnedHttpClient.createClient(allowDebugBypass: false);
      addTearDown(client.close);

      final response = await client.get(Uri.parse(Urls.baseUrl));

      expect(response.statusCode, isNot(0));
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}