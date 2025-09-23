// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_utils.dart';
import 'package:ion/app/services/ion_connect/ed25519_key_store.dart';
import 'package:ion/app/services/storage/secure_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_event_signer_provider.r.g.dart';

@Riverpod(keepAlive: true)
class IonConnectEventSigner extends _$IonConnectEventSigner {
  @override
  Future<EventSigner?> build(String identityKeyName) async {
    final storage = ref.watch(secureStorageProvider);
    final storedKey = await storage.getString(key: _storageKey);
    if (storedKey != null) {
      return Ed25519KeyStore.fromPrivate(storedKey);
    }
    return null;
  }

  Future<void> delete() async {
    await ref.read(secureStorageProvider).remove(key: _storageKey);
  }

  Future<EventSigner?> initEventSigner() async {
    final currentUserIonConnectEventSigner = await future;
    if (currentUserIonConnectEventSigner != null) {
      // Event signer already exists, reuse it
      return currentUserIonConnectEventSigner;
    }

    // if we previously created a keypair while username was empty (used for
    // device-identifications preflight), adopt that keypair for the now-known identity
    // and delete it from the pending location.
    final adopted = await _adoptPendingSignerIfAny();
    if (adopted != null) {
      return adopted;
    }

    final deviceKeypairAttachment = await DeviceKeypairUtils.findDeviceKeypairAttachment(ref: ref);
    if (deviceKeypairAttachment != null) {
      // There's an uploaded keypair - return null and restore it later (LinkNewDevice)
      return null;
    }

    // Generate a new event signer
    return _generate();
  }

  /// If a keypair was created under the empty-username storage key ("_ion_connect_key_store")
  /// during pre-login flows, move it under the current identity's key and return it.
  /// Returns null if nothing to adopt.
  Future<EventSigner?> _adoptPendingSignerIfAny() async {
    if (identityKeyName.isEmpty) {
      return null;
    }
    final storage = ref.read(secureStorageProvider);
    final pendingKey = _storageKeySuffix;
    final pendingPrivate = await storage.getString(key: pendingKey);
    if (pendingPrivate == null) {
      return null;
    }

    // Persist under the user-specific key and remove the pending one.
    await storage.setString(key: _storageKey, value: pendingPrivate);
    await storage.remove(key: pendingKey);

    final signer = await Ed25519KeyStore.fromPrivate(pendingPrivate);
    state = AsyncData(signer);
    return signer;
  }

  /// Restores an event signer from a private key string
  /// This is used for device keypair restoration from uploaded
  Future<EventSigner> restoreFromPrivateKey(String privateKey) async {
    final keyStore = await Ed25519KeyStore.fromPrivate(privateKey);
    return _setEventSigner(keyStore);
  }

  Future<EventSigner> _generate() async {
    final keyStore = await Ed25519KeyStore.generate();
    return _setEventSigner(keyStore);
  }

  Future<EventSigner> _setEventSigner(EventSigner signer) async {
    final storage = ref.read(secureStorageProvider);
    await storage.setString(key: _storageKey, value: signer.privateKey);
    state = AsyncData(signer);
    return signer;
  }

  String get _storageKeySuffix => '_ion_connect_key_store';

  String get _storageKey => '$identityKeyName$_storageKeySuffix';
}

@Riverpod(keepAlive: true)
Future<EventSigner?> currentUserIonConnectEventSigner(Ref ref) async {
  final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentIdentityKeyName == null) {
    return null;
  }
  return ref.watch(ionConnectEventSignerProvider(currentIdentityKeyName).future);
}
