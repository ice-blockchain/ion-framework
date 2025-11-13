import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:test/test.dart';

void main() {
  group('Http2Connection', () {
    test('connection status transitions from connecting to connected', () async {
      final connection = Http2Connection.connect('nghttp2.org');

      expect(connection.status, isA<ConnectionStatusConnecting>());

      final statuses = <ConnectionStatus>[];
      final subscription = connection.statusStream.listen(statuses.add);

      await connection.waitForConnected();

      expect(connection.status, isA<ConnectionStatusConnected>());
      expect(connection.transport, isNotNull);

      await connection.close();

      expect(connection.status, isA<ConnectionStatusDisconnected>());

      await subscription.cancel();

      expect(statuses.any((s) => s is ConnectionStatusConnected), isTrue);
      expect(statuses.any((s) => s is ConnectionStatusDisconnecting), isTrue);
      expect(statuses.any((s) => s is ConnectionStatusDisconnected), isTrue);
    });

    test('connection fails with invalid host', () async {
      final connection = Http2Connection.connect('invalid-host-that-does-not-exist.com');

      expect(connection.status, isA<ConnectionStatusConnecting>());

      await expectLater(connection.waitForConnected(), throwsA(isA<Http2ConnectionException>()));

      expect(connection.status, isA<ConnectionStatusDisconnected>());
      expect(connection.transport, isNull);

      final status = connection.status;
      expect(status, isA<ConnectionStatusDisconnected>());
      expect((status as ConnectionStatusDisconnected).exception, isA<Http2ConnectionException>());
    });

    test('waitForConnected returns immediately if already connected', () async {
      final connection = Http2Connection.connect('nghttp2.org');

      await connection.waitForConnected();
      expect(connection.status, isA<ConnectionStatusConnected>());

      await connection.waitForConnected();
      expect(connection.status, isA<ConnectionStatusConnected>());

      await connection.close();
    });
  });
}
