// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/core/network_client.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkClient Redirects', () {
    test('follows redirects to the same host', () async {
      // httpbin.org/redirect-to?url=... redirects to the given URL
      // We use this to simulate a redirect
      final client = NetworkClient.fromBaseUrl('httpbin.org', authToken: null);

      try {
        final response = await client.get<Map<String, dynamic>>(
          '/redirect-to',
          queryParameters: {'url': '/get', 'status_code': 301},
        );

        expect(response, containsPair('url', contains('/get')));
      } finally {
        await client.dispose();
      }
    });

    test('follows redirects to a different host', () async {
      // httpbin.org/redirect-to?url=... redirects to the given URL
      final client = NetworkClient.fromBaseUrl('httpbin.org', authToken: null);

      try {
        final response = await client.get<Map<String, dynamic>>(
          '/redirect-to',
          queryParameters: {
            'url': 'https://jsonplaceholder.typicode.com/todos/1',
            'status_code': 301,
          },
        );

        expect(response, containsPair('id', 1));
        expect(response, containsPair('title', isNotEmpty));
      } finally {
        await client.dispose();
      }
    });
  });
}
