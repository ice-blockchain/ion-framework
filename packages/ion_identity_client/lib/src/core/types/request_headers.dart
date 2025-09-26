// SPDX-License-Identifier: ice License 1.0

class RequestHeaders {
  static const ionIdentityClientId = 'X-Client-ID';
  static const ionIdentityKeyName = 'X-Username';
  static const deviceIdentificationRequestId = 'X-Device-Identification-Request-ID';
  static const ionIdentityUserAction = 'X-Useraction';
  static const authorization = 'Authorization';

  static Map<String, String> getAuthorizationHeaders({
    required String token,
    required String username,
  }) {
    return {
      ...getTokenHeader(token: token),
      ...getIONIdentityKeyNameHeader(username: username),
    };
  }

  static Map<String, String> getTokenHeader({
    required String token,
  }) {
    return {
      authorization: 'Bearer $token',
    };
  }

  static Map<String, String> getIONIdentityKeyNameHeader({
    required String username,
  }) {
    return {
      ionIdentityKeyName: username,
    };
  }
}
