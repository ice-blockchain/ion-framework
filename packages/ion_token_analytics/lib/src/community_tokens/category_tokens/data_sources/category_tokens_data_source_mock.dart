// SPDX-License-Identifier: ice License 1.0

/// MOCK DATA SOURCE: Returns raw JSON data for category tokens viewing session.
/// This simulates REST API responses that will be parsed by the repository.
class CategoryTokensDataSourceMock {
  /// Returns raw JSON for viewing session creation.
  /// JSON format: {"id": "someUUID", "ttl": 3600000}
  Future<Map<String, dynamic>> createViewingSession(String type) async {
    // type is 'trending' or 'top' (from TokenCategoryType.value)
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Return JSON matching API response
    return {
      'id': 'mock-viewing-session-${DateTime.now().millisecondsSinceEpoch}',
      'ttl': 3600000, // 1 hour in milliseconds
    };
  }
}
