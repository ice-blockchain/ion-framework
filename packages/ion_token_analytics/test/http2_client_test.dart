import 'dart:async';

import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:test/test.dart';

void main() {
  group('Http2Client', () {
    late Http2Client client;

    setUp(() {
      client = Http2Client('nghttp2.org');
    });

    test('GET request returns valid JSON response', () async {
      final response = await client.request<Map<String, dynamic>>('/httpbin/get');

      expect(response.data, containsPair('headers', isA<Map<String, dynamic>>()));
      expect(response.data, containsPair('url', contains('https://nghttp2.org/httpbin/get')));
    });

    test('POST request with body returns echo response', () async {
      final body = {'test': 'data', 'value': 123};
      final response = await client.request<Map<String, dynamic>>(
        '/httpbin/post',
        data: body,
        options: Http2RequestOptions(method: 'POST'),
      );

      expect(response.data, containsPair('json', body));
      expect(response.data, containsPair('headers', isA<Map<dynamic, dynamic>>()));
    });

    test('handles different HTTP methods', () async {
      final response = await client.request<Map<String, dynamic>>(
        '/httpbin/put',
        options: Http2RequestOptions(method: 'PUT'),
      );

      expect(response.data, isA<Map<String, dynamic>>());
      expect(response.data!['url'], contains('/httpbin/put'));
    });

    test('includes custom headers in request', () async {
      final headers = {'X-Custom-Header': 'test-value'};
      final response = await client.request<Map<String, dynamic>>(
        '/httpbin/headers',
        options: Http2RequestOptions(headers: headers),
      );

      expect(response.data!['headers'], containsPair('X-Custom-Header', 'test-value'));
    });

    test('includes query parameters in request', () async {
      final queryParams = {'foo': 'bar', 'test': 'value'};
      final response = await client.request<Map<String, dynamic>>(
        '/httpbin/get',
        queryParameters: queryParams,
      );

      expect(response.data!['args'], containsPair('foo', 'bar'));
      expect(response.data!['args'], containsPair('test', 'value'));
      expect(response.data!['url'], contains('?'));
      expect(response.data!['url'], contains('foo=bar'));
      expect(response.data!['url'], contains('test=value'));
    });

    test('handles 404 error gracefully', () async {
      final response = await client.request<Map<String, dynamic>>('/httpbin/status/404');

      expect(response.statusCode, equals(404));
    });

    test('handles connection exceptions', () async {
      final invalidClient = Http2Client('invalid-host-that-does-not-exist.com');

      expect(() => invalidClient.request<Map<String, dynamic>>('/test'), throwsA(isA<Exception>()));
    });

    test('request timeout throws TimeoutException', () async {
      // The /httpbin/delay/5 endpoint delays response by 5 seconds
      // We set timeout to 1 second, so it should timeout
      expect(
        () => client.request<Map<String, dynamic>>(
          '/httpbin/delay/5',
          options: Http2RequestOptions(timeout: const Duration(seconds: 1)),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('connection gets disconnected automatically after request is done', () async {
      expect(client.connection, isNull);

      final future = client.request<Map<String, dynamic>>('/httpbin/delay/1');

      expect(client.connection, isNotNull);

      await future;

      expect(client.connection, isNull);
    });

    test('connection remains connected with multiple concurrent requests', () async {
      expect(client.connection, isNull);

      // Start multiple requests concurrently
      final future1 = client.request<Map<String, dynamic>>('/httpbin/delay/1');
      final future2 = client.request<Map<String, dynamic>>('/httpbin/delay/2');

      // Connection should be established
      expect(client.connection, isNotNull);
      final connectionDuringRequests = client.connection;

      // Wait for first request to complete
      final response1 = await future1;
      expect(response1.statusCode, equals(200));

      // Connection should still be active because second request is ongoing
      expect(client.connection, isNotNull);
      expect(client.connection, equals(connectionDuringRequests));

      // Wait for second request to complete
      await future2;

      // Now all requests are done, connection should be closed
      expect(client.connection, isNull);
    });
  });

  group('Http2Client connection lifecycle', () {
    late Http2Client client;

    setUp(() {
      client = Http2Client('51.75.87.132', port: 4443);
    });

    test('connection lifecycle with sequential requests', () async {
      expect(client.connection, isNull);

      // First request
      final response1 = await client.request<Map<String, dynamic>>('.well-known/nostr/nip96.json');
      expect(response1.statusCode, equals(200));
      expect(client.connection, isNull);

      // Second request - should create a new connection
      final future2 = client.request<Map<String, dynamic>>('.well-known/nostr/nip96.json');

      expect(client.connection, isNotNull);

      // Complete the request
      final response2 = await future2;
      expect(response2.statusCode, equals(200));

      // Connection should be closed after request
      expect(client.connection, isNull);
    });

    test('subscription keeps connection open and closes with subscription', () async {
      expect(client.connection, isNull);

      final subscription = await client.subscribe<String>('/');

      final messages = <String>[];
      final listener = subscription.stream.listen(messages.add);

      expect(client.connection, isNotNull);

      await listener.cancel();
      await subscription.close();

      expect(client.connection, isNull);
    });
  });
}
