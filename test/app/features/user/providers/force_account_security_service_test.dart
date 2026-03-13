// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/features/user/providers/force_account_security_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

void main() {
  group('ForceAccountSecurityService', () {
    test('shows modal after delay for newly created unsecured account', () async {
      var emitCount = 0;
      final service = ForceAccountSecurityService(
        enforceDelay: const Duration(milliseconds: 30),
        emitDialog: () => emitCount++,
        hasNavigatorContext: () => true,
      )
        ..onUserMetadata(_metadata(registeredAt: DateTime.now()))
        ..onRouteChanged(FeedRoute().location)
        ..onSecured(secured: false);

      expect(emitCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(emitCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(emitCount, 1);

      service.dispose();
    });

    test('shows modal immediately after recovery even when account is new', () {
      var emitCount = 0;
      final service = ForceAccountSecurityService(
        enforceDelay: const Duration(days: 1),
        emitDialog: () => emitCount++,
        hasNavigatorContext: () => true,
      )
        ..onUserMetadata(_metadata(registeredAt: DateTime.now()))
        ..onRouteChanged(FeedRoute().location)
        ..onSecured(secured: false);

      expect(emitCount, 0);

      service.onPostRecoveryBackupRequiredChanged(required: true);

      expect(emitCount, 1);

      service.dispose();
    });

    test('post-recovery bypass cancels pending delay timer and does not emit twice', () async {
      var emitCount = 0;
      final service = ForceAccountSecurityService(
        enforceDelay: const Duration(minutes: 1),
        emitDialog: () => emitCount++,
        hasNavigatorContext: () => true,
      )
        ..onUserMetadata(_metadata(registeredAt: DateTime.now()))
        ..onRouteChanged(FeedRoute().location)
        ..onSecured(secured: false);

      expect(emitCount, 0);

      service.onPostRecoveryBackupRequiredChanged(required: true);
      expect(emitCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(emitCount, 1);

      service.dispose();
    });
  });
}

UserMetadataEntity _metadata({
  required DateTime registeredAt,
}) {
  return UserMetadataEntity(
    id: 'id',
    pubkey: 'pubkey',
    masterPubkey: 'masterPubkey',
    signature: 'signature',
    createdAt: DateTime.now().microsecondsSinceEpoch,
    data: UserMetadata(
      registeredAt: registeredAt.microsecondsSinceEpoch,
    ),
  );
}
