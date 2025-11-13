import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:test/test.dart';

void main() {
  group('Http2Client', () {
    test('connects to a relay and receives response', () async {
      final client = Http2Client('nghttp2.org');
      final response = await client.request<Map<String, dynamic>>('/httpbin/get');

      print(response);
      // Connection will be automatically closed after request completes
    });
  });
}
