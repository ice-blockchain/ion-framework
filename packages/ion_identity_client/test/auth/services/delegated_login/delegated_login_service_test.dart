// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion_identity_client/ion_identity.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/data_sources/delegated_login_data_source.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/delegated_login_service.dart';
import 'package:ion_identity_client/src/auth/services/delegated_login/models/delegated_login_response.f.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';

void main() {
  group('DelegatedLoginService', () {
    late MockDelegatedLoginDataSource mockDataSource;
    late MockTokenStorage mockTokenStorage;
    late DelegatedLoginService service;
    const testUsername = 'test_user@example.com';
    const initialToken = UserToken(
      username: testUsername,
      token: 'old_token',
      refreshToken: 'old_refresh_token',
    );

    setUp(() {
      mockDataSource = MockDelegatedLoginDataSource();
      mockTokenStorage = MockTokenStorage();
      service = DelegatedLoginService(
        dataSource: mockDataSource,
        tokenStorage: mockTokenStorage,
      );
      mockTokenStorage.setTokenSync(
        username: testUsername,
        token: initialToken,
      );
    });

    tearDown(() {
      mockDataSource.reset();
      mockTokenStorage.reset();
    });

    test('delegatedLogin succeeds and updates token', () async {
      // Arrange
      const newToken = 'new_access_token';
      mockDataSource.responseToReturn = const DelegatedLoginResponse(token: newToken);

      // Act
      final result = await service.delegatedLogin(username: testUsername);

      // Assert
      expect(result.token, equals(newToken));
      expect(result.username, equals(testUsername));
      expect(mockTokenStorage.setTokenCalled, isTrue);
      expect(mockTokenStorage.setTokenUsername, equals(testUsername));
      expect(mockTokenStorage.setTokenNewToken, equals(newToken));
      expect(mockTokenStorage.removeTokenCalled, isFalse);
    });

    test(
      'delegatedLogin removes tokens when dataSource throws UnauthenticatedException',
      () async {
        mockDataSource
          ..shouldThrow = true
          ..exceptionToThrow = const UnauthenticatedException();

        try {
          await service.delegatedLogin(username: testUsername);
          fail('Expected UnauthenticatedException to be thrown');
        } catch (e) {
          expect(e, isA<UnauthenticatedException>());
        }

        expect(mockTokenStorage.removeTokenCalled, isTrue);
        expect(mockTokenStorage.removedUsername, equals(testUsername));
        expect(mockTokenStorage.getToken(username: testUsername), isNull);
      },
    );

    test(
      'delegatedLogin removes tokens when dataSource throws RequestExecutionException',
      () async {
        mockDataSource
          ..shouldThrow = true
          ..exceptionToThrow = RequestExecutionException(
            Exception('Network error'),
            StackTrace.current,
          );

        try {
          await service.delegatedLogin(username: testUsername);
          fail('Expected RequestExecutionException to be thrown');
        } catch (e) {
          expect(e, isA<RequestExecutionException>());
        }

        expect(mockTokenStorage.removeTokenCalled, isTrue);
        expect(mockTokenStorage.removedUsername, equals(testUsername));
        expect(mockTokenStorage.getToken(username: testUsername), isNull);
      },
    );

    test(
      'delegatedLogin removes tokens when dataSource throws any exception',
      () async {
        mockDataSource
          ..shouldThrow = true
          ..exceptionToThrow = Exception('Generic error');

        try {
          await service.delegatedLogin(username: testUsername);
          fail('Expected Exception to be thrown');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        expect(mockTokenStorage.removeTokenCalled, isTrue);
        expect(mockTokenStorage.removedUsername, equals(testUsername));
        expect(mockTokenStorage.getToken(username: testUsername), isNull);
      },
    );

    test(
      'delegatedLogin removes tokens when setToken fails',
      () async {
        const newToken = 'new_access_token';
        mockDataSource.responseToReturn = const DelegatedLoginResponse(token: newToken);
        mockTokenStorage
          ..shouldThrowOnSetToken = true
          ..exceptionToThrowOnSetToken = Exception('Storage error');

        try {
          await service.delegatedLogin(username: testUsername);
          fail('Expected Exception to be thrown');
        } catch (e) {
          // Assert - verify correct exception type
          expect(e, isA<Exception>());
        }

        // Verify tokens were removed
        expect(mockTokenStorage.removeTokenCalled, isTrue);
        expect(mockTokenStorage.removedUsername, equals(testUsername));
        expect(mockTokenStorage.getToken(username: testUsername), isNull);
      },
    );

    test(
      'delegatedLogin removes tokens when getToken returns null after setToken',
      () async {
        const newToken = 'new_access_token';
        mockDataSource.responseToReturn = const DelegatedLoginResponse(token: newToken);
        mockTokenStorage.shouldReturnNullOnGetToken = true;

        try {
          await service.delegatedLogin(username: testUsername);
          fail('Expected UnauthenticatedException to be thrown');
        } catch (e) {
          expect(e, isA<UnauthenticatedException>());
        }

        // Verify tokens were removed
        expect(mockTokenStorage.removeTokenCalled, isTrue);
        expect(mockTokenStorage.removedUsername, equals(testUsername));
      },
    );
  });
}

/// Mock implementation of DelegatedLoginDataSource for testing
class MockDelegatedLoginDataSource extends DelegatedLoginDataSource {
  MockDelegatedLoginDataSource()
      : super(
          networkClient: NetworkClient(dio: Dio()),
          tokenStorage: TokenStorage(
            secureStorage: const FlutterSecureStorage(),
          ),
        );

  bool shouldThrow = false;
  Exception? exceptionToThrow;
  DelegatedLoginResponse? responseToReturn;

  void reset() {
    shouldThrow = false;
    exceptionToThrow = null;
    responseToReturn = null;
  }

  @override
  Future<DelegatedLoginResponse> delegatedLogin({
    required String username,
  }) async {
    if (shouldThrow && exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseToReturn ?? const DelegatedLoginResponse(token: 'new_access_token');
  }
}

class MockTokenStorage extends TokenStorage {
  MockTokenStorage()
      : super(
          secureStorage: const FlutterSecureStorage(),
        );

  final Map<String, UserToken> _tokens = {};
  bool removeTokenCalled = false;
  String? removedUsername;
  bool setTokenCalled = false;
  String? setTokenUsername;
  String? setTokenNewToken;
  bool shouldThrowOnSetToken = false;
  Exception? exceptionToThrowOnSetToken;
  bool shouldReturnNullOnGetToken = false;

  void reset() {
    _tokens.clear();
    removeTokenCalled = false;
    removedUsername = null;
    setTokenCalled = false;
    setTokenUsername = null;
    setTokenNewToken = null;
    shouldThrowOnSetToken = false;
    exceptionToThrowOnSetToken = null;
    shouldReturnNullOnGetToken = false;
  }

  void setTokenSync({
    required String username,
    required UserToken token,
  }) {
    _tokens[username] = token;
  }

  @override
  UserToken? getToken({required String username}) {
    if (shouldReturnNullOnGetToken) {
      return null;
    }
    return _tokens[username];
  }

  @override
  Future<void> setToken({
    required String username,
    required String newToken,
  }) async {
    setTokenCalled = true;
    setTokenUsername = username;
    setTokenNewToken = newToken;

    if (shouldThrowOnSetToken && exceptionToThrowOnSetToken != null) {
      throw exceptionToThrowOnSetToken!;
    }

    final existingToken = _tokens[username];
    if (existingToken != null) {
      _tokens[username] = UserToken(
        username: existingToken.username,
        token: newToken,
        refreshToken: existingToken.refreshToken,
      );
    } else {
      _tokens[username] = UserToken(
        username: username,
        token: newToken,
        refreshToken: 'refresh_token',
      );
    }
  }

  @override
  Future<void> removeToken({required String username}) async {
    removeTokenCalled = true;
    removedUsername = username;
    _tokens.remove(username);
  }
}
