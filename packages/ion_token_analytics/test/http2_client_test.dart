// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';
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
      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));

      final future = client.request<Map<String, dynamic>>('/httpbin/delay/1');

      expect(client.connection.status, equals(const ConnectionStatusConnecting()));

      await future;

      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));
    });

    test('connection remains connected with multiple concurrent requests', () async {
      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));

      final future1 = client.request<Map<String, dynamic>>('/httpbin/delay/1');
      final future2 = client.request<Map<String, dynamic>>('/httpbin/delay/2');

      expect(client.connection.status, equals(const ConnectionStatusConnecting()));
      final connectionDuringRequests = client.connection;

      final response1 = await future1;
      expect(response1.statusCode, equals(200));

      expect(client.connection.status, equals(const ConnectionStatusConnected()));
      expect(client.connection, equals(connectionDuringRequests));

      await future2;

      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));
    });
  });

  group('Http2Client connection lifecycle', () {
    late Http2Client client;

    setUp(() {
      client = Http2Client('181.41.142.217', port: 4443);
    });

    test('connection lifecycle with sequential requests', () async {
      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));

      final response1 = await client.request<Map<String, dynamic>>('.well-known/nostr/nip96.json');
      expect(response1.statusCode, equals(200));
      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));

      final future2 = client.request<Map<String, dynamic>>('.well-known/nostr/nip96.json');

      expect(client.connection.status, equals(const ConnectionStatusConnecting()));

      final response2 = await future2;
      expect(response2.statusCode, equals(200));

      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));
    });

    test('active subscriptions keep connection open', () async {
      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));

      final subscription1 = await client.subscribe<String>('/');
      final subscription2 = await client.subscribe<String>('/');

      expect(client.connection.status, equals(const ConnectionStatusConnected()));

      await subscription1.close();

      expect(client.connection.status, equals(const ConnectionStatusConnected()));

      await subscription2.close();

      expect(client.connection.status, equals(const ConnectionStatusDisconnected()));
    });
  });
}
