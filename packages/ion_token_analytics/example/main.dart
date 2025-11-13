import 'package:ion_token_analytics/ion_token_analytics.dart';

Future<void> main() async {
  // Example 1: Making HTTP/2 requests
  final client = Http2Client('example.com');

  try {
    // Simple GET request
    final response = await client.request<Map<String, dynamic>>(
      '/api/data',
      options: Http2RequestOptions(),
    );
    print('Response status: ${response.statusCode}');
    print('Response data: ${response.data}');

    // POST request with data and query parameters
    final postResponse = await client.request<Map<String, dynamic>>(
      '/api/users',
      data: {'name': 'John Doe', 'email': 'john@example.com'},
      queryParameters: {'filter': 'active'},
      options: Http2RequestOptions(
        method: 'POST',
        timeout: const Duration(seconds: 10),
        headers: {'authorization': 'Bearer token123'},
      ),
    );
    print('POST response: ${postResponse.data}');
  } catch (e) {
    print('Request error: $e');
  }

  // Example 2: WebSocket subscription
  try {
    print('\nSubscribing to WebSocket stream...');
    await for (final message in client.subscribe<String>(
      '/api/stream',
      queryParameters: {'channel': 'updates'},
      headers: {'authorization': 'Bearer token123'},
    )) {
      print('Received message: $message');

      // Break after receiving a few messages for demo purposes
      // In a real application, you would continue listening
    }
  } catch (e) {
    print('WebSocket error: $e');
  } finally {
    await client.close();
  }
}
