// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ion_identity_client/src/core/types/ion_exception.dart';

DioException responseError(Object? data, {int statusCode = 409}) {
  final options = RequestOptions(path: '/auth/registration/delegated');
  return DioException.badResponse(
    statusCode: statusCode,
    requestOptions: options,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: data,
    ),
  );
}

void main() {
  group('UserAlreadyExistsException', () {
    for (final message in [
      'User already exists',
      'User already exists.',
      'User has already registered.',
      ' USER HAS ALREADY REGISTERED. ',
    ]) {
      final data = {
        'error': {'message': message},
      };
      test('recognizes map response: $message', () {
        expect(UserAlreadyExistsException.isMatch(responseError(data)), isTrue);
      });
      test('recognizes legacy string response: $message', () {
        expect(UserAlreadyExistsException.isMatch(responseError(jsonEncode(data))), isTrue);
      });
    }

    for (final status in [400, 401, 403, 429, 500, 503]) {
      test('does not treat HTTP $status as an account conflict', () {
        expect(
          UserAlreadyExistsException.isMatch(
            responseError(
              {
                'error': {'message': 'User has already registered.'},
              },
              statusCode: status,
            ),
          ),
          isFalse,
        );
      });
    }

    for (final data in <Object?>[
      null,
      '',
      '<html>Bad Gateway</html>',
      'not json',
      '[]',
      'null',
      <String, dynamic>{},
      {'error': 'User has already registered.'},
      {'error': <String, dynamic>{}},
      {
        'error': {'message': 409},
      },
      {
        'error': {'message': 'Wallet already exists.'},
      },
      {
        'error': {'message': 'User has not registered.'},
      },
      {
        'error': {'message': 'User has already registered. Permission denied.'},
      },
    ]) {
      test('rejects unrelated or malformed response: $data', () {
        expect(UserAlreadyExistsException.isMatch(responseError(data)), isFalse);
      });
    }

    test('does not classify transport errors as existing accounts', () {
      expect(
        UserAlreadyExistsException.isMatch(
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 15),
            requestOptions: RequestOptions(path: '/auth/registration/delegated'),
          ),
        ),
        isFalse,
      );
    });
  });
}
