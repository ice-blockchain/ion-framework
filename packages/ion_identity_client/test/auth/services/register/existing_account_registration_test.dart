// SPDX-License-Identifier: ice License 1.0

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion_identity_client/src/auth/services/register/data_sources/register_data_source.dart';
import 'package:ion_identity_client/src/auth/services/register/register_service.dart';
import 'package:ion_identity_client/src/core/network/network_client.dart';
import 'package:ion_identity_client/src/core/storage/token_storage.dart';
import 'package:ion_identity_client/src/core/types/ion_exception.dart';
import 'package:ion_identity_client/src/signer/identity_signer.dart';

class _ExistingCredentialSigner implements IdentitySigner {
  @override
  Future<bool> isPasskeyAvailable() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Existing-account conflict must not invoke ${invocation.memberName}');
  }
}

class _UnchangedTokenStorage implements TokenStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('Existing-account conflict must not invoke ${invocation.memberName}');
  }
}

void main() {
  for (final passwordFlow in [false, true]) {
    test('registration conflict preserves credentials and tokens (password: $passwordFlow)',
        () async {
      final requests = <String>[];
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options.path);
            handler.reject(
              DioException.badResponse(
                statusCode: 409,
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'error': {'message': 'User has already registered.'},
                  },
                ),
              ),
            );
          },
        ),
      );
      final service = RegisterService(
        username: 'existing_account',
        dataSource: RegisterDataSource(networkClient: NetworkClient(dio: dio)),
        identitySigner: _ExistingCredentialSigner(),
        tokenStorage: _UnchangedTokenStorage(),
      );

      await expectLater(
        passwordFlow
            ? service.registerWithPassword('unused-password', null)
            : service.registerUser(null),
        throwsA(isA<UserAlreadyExistsException>()),
      );
      expect(requests, [RegisterDataSource.registerInitPath]);
    });
  }
}
