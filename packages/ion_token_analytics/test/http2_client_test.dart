// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:http2/http2.dart';
import 'package:ion_token_analytics/src/http2_client/http2_client.dart';
import 'package:ion_token_analytics/src/http2_client/http2_connection.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_request_options.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttp2Connection extends Mock implements Http2Connection {}

class MockClientTransportConnection extends Mock implements ClientTransportConnection {}

class MockClientTransportStream extends Mock implements ClientTransportStream {}

class FakeClientTransportStream extends Mock implements ClientTransportStream {
  final _incomingController = StreamController<StreamMessage>();
  final _outgoingController = StreamController<List<int>>();

  @override
  Stream<StreamMessage> get incomingMessages => _incomingController.stream;

  @override
  void sendData(List<int> bytes, {bool endStream = false}) {
    _outgoingController.add(bytes);
  }

  void pushMessage(StreamMessage message) {
    _incomingController.add(message);
  }

  void closeIncoming() {
    _incomingController.close();
  }
}

void main() {
  group('Http2Client', () {
    late Http2Client client;
    late MockHttp2Connection mockConnection;
    late MockClientTransportConnection mockTransport;
    late FakeClientTransportStream fakeStream;

    setUp(() {
      mockConnection = MockHttp2Connection();
      mockTransport = MockClientTransportConnection();
      fakeStream = FakeClientTransportStream();

      when(() => mockConnection.status).thenReturn(const ConnectionStatusDisconnected());
      when(() => mockConnection.connect()).thenAnswer((_) async {
        when(() => mockConnection.status).thenReturn(const ConnectionStatusConnected());
      });
      when(() => mockConnection.disconnect()).thenAnswer((_) async {
        when(() => mockConnection.status).thenReturn(const ConnectionStatusDisconnected());
      });
      when(() => mockConnection.transport).thenReturn(mockTransport);

      when(() => mockTransport.makeRequest(any())).thenReturn(fakeStream);

      client = Http2Client('example.com', connection: mockConnection);
    });

    test('GET request returns valid JSON response', () async {
      // Simulate response
      scheduleMicrotask(() {
        final headers = [
          Header.ascii(':status', '200'),
          Header.ascii('content-type', 'application/json'),
        ];
        fakeStream.pushMessage(HeadersStreamMessage(headers));

        final body = jsonEncode({'key': 'value'});
        fakeStream
          ..pushMessage(DataStreamMessage(utf8.encode(body)))
          ..closeIncoming();
      });

      final response = await client.request<Map<String, dynamic>>('/api/data');

      expect(response.statusCode, equals(200));
      expect(response.data, equals({'key': 'value'}));
      verify(() => mockConnection.connect()).called(1);
    });

    test('handles 404 error gracefully', () async {
      scheduleMicrotask(() {
        final headers = [Header.ascii(':status', '404')];
        fakeStream
          ..pushMessage(HeadersStreamMessage(headers))
          ..closeIncoming();
      });

      final response = await client.request<Map<String, dynamic>>('/api/missing');

      expect(response.statusCode, equals(404));
      expect(response.data, isNull);
    });

    test('request timeout throws TimeoutException', () async {
      // Don't push any messages to simulate delay

      expect(
        () => client.request<Map<String, dynamic>>(
          '/api/delay',
          options: Http2RequestOptions(timeout: const Duration(milliseconds: 100)),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('connection gets disconnected automatically after request is done', () async {
      when(() => mockConnection.status).thenReturn(const ConnectionStatusConnected());

      scheduleMicrotask(() {
        fakeStream.closeIncoming();
      });

      await client.request<void>('/api/test');

      verify(() => mockConnection.disconnect()).called(1);
    });
  });
}
