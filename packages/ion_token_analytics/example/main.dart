import 'package:ion_token_analytics/ion_token_analytics.dart';

Future<void> main() async {
  try {
    // Connect to the HTTP/2 server
    final connection = await Http2Connection.connect('51.75.87.132', port: 4443);
    print('HTTP/2 connection established');

    // Create a WebSocket connection
    final websocket = await Http2WebSocket.fromHttp2Connection(connection);
    print('WebSocket connection established');

    // Listen for messages with error handling
    websocket.stream.listen(
      (message) {
        if (message.type == WebSocketMessageType.text) {
          print('Received text: ${message.asText}');
        } else {
          print('Received binary: ${message.asBinary.length} bytes');
        }
      },
      onError: (error, stackTrace) {
        if (error is WebSocketException) {
          print('WebSocket error ${error.code}: ${error.message}');
        } else {
          print('Unexpected error: $error');
        }
      },
      onDone: () => print('WebSocket connection closed'),
    );

    // Send a test message
    websocket.add('Hello HTTP/2 WebSocket!');
    print('Message sent');

    // Keep the connection alive for 60 seconds
    await Future<void>.delayed(const Duration(seconds: 60));

    // Clean up
    websocket.close();
    await connection.close();
    print('Connections closed');
  } catch (e, stackTrace) {
    print('Something went wrong: $e\n$stackTrace');
  }
}
