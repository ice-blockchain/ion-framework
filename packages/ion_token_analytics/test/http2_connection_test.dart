// SPDX-License-Identifier: ice License 1.0

import 'package:ion_token_analytics/src/http2_client/http2_connection.dart';
import 'package:ion_token_analytics/src/http2_client/models/http2_connection_status.dart';
import 'package:ion_token_analytics/src/http2_client/http2_exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('Http2Connection', () {
    test(
      'connection status transitions from connecting to connected and then to disconnected',
      () async {
        final connection = Http2Connection('nghttp2.org');

        expect(connection.status, isA<ConnectionStatusDisconnected>());

        final statuses = <ConnectionStatus>[];
        final subscription = connection.statusStream.listen(statuses.add);

        await connection.connect();
        await connection.disconnect();

        await subscription.cancel();

        expect(statuses.length, 4);
        expect(statuses[0], isA<ConnectionStatusConnecting>());
        expect(statuses[1], isA<ConnectionStatusConnected>());
        expect(statuses[2], isA<ConnectionStatusDisconnecting>());
        expect(statuses[3], isA<ConnectionStatusDisconnected>());
      },
    );

    test('connection fails with invalid host', () async {
      final connection = Http2Connection('invalid-host-that-does-not-exist.com');

      expect(connection.status, isA<ConnectionStatusDisconnected>());

      await expectLater(connection.connect(), throwsA(isA<Exception>()));

      expect(connection.status, isA<ConnectionStatusDisconnected>());
      expect(connection.transport, isNull);

      final status = connection.status;
      expect(status, isA<ConnectionStatusDisconnected>());
      expect((status as ConnectionStatusDisconnected).exception, isA<Http2ConnectionException>());
    });
  });
}
