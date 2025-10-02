// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/signing_algorithm.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_utils.dart';
import 'package:ion/app/services/ion_connect/ed25519_key_store.dart';
import 'package:ion/app/services/ion_connect/secp256k1_schnorr_key_store.dart';
import 'package:ion/app/services/storage/secure_storage.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_connect_event_signer_provider.r.g.dart';

/// Abstract base class for IonConnect event signers
abstract class GenericEventSigner {
  GenericEventSigner({
    required this.identityKeyName,
  });

  final String identityKeyName;

  /// Algorithm-specific storage key suffix
  String get storageKeySuffix;

  /// Create signer from private key
  Future<EventSigner> createSignerFromPrivateKey(String privateKey);

  /// Generate new signer
  Future<EventSigner> generateSigner();

  /// Check if signer initialization should be skipped (e.g., for device keypair restoration)
  Future<bool> shouldSkipInitialization(Ref ref) async => false;

  /// Get the storage key for this signer
  String getStorageKey() => '${identityKeyName}_$storageKeySuffix';

  /// Load signer from storage
  Future<EventSigner?> loadFromStorage(SecureStorage storage) async {
    final storedKey = await storage.getString(key: getStorageKey());
    if (storedKey != null) {
      return createSignerFromPrivateKey(storedKey);
    }
    return null;
  }

  /// Save signer to storage
  Future<void> saveToStorage(SecureStorage storage, EventSigner signer) async {
    await storage.setString(key: getStorageKey(), value: signer.privateKey);
  }

  /// Delete signer from storage
  Future<void> deleteFromStorage(SecureStorage storage) async {
    await storage.remove(key: getStorageKey());
  }
}

/// Ed25519 implementation of IonConnectEventSigner
class Ed25519IonConnectEventSigner extends GenericEventSigner {
  Ed25519IonConnectEventSigner({
    required super.identityKeyName,
  });

  @override
  String get storageKeySuffix => 'ion_connect_key_store';

  @override
  Future<EventSigner> createSignerFromPrivateKey(String privateKey) async {
    return Ed25519KeyStore.fromPrivate(privateKey);
  }

  @override
  Future<EventSigner> generateSigner() async {
    return Ed25519KeyStore.generate();
  }

  @override
  Future<bool> shouldSkipInitialization(Ref ref) async {
    final deviceKeypairAttachment = await DeviceKeypairUtils.findDeviceKeypairAttachment(ref: ref);
    // If there's an uploaded keypair, skip initialization and restore it later (LinkNewDevice)
    return deviceKeypairAttachment != null;
  }
}

/// Secp256k1 Schnorr implementation of IonConnectEventSigner
class Secp256k1IonConnectEventSigner extends GenericEventSigner {
  Secp256k1IonConnectEventSigner({
    required super.identityKeyName,
  });

  @override
  String get storageKeySuffix => 'ion_connect_secp256k1_key_store';

  @override
  Future<EventSigner> createSignerFromPrivateKey(String privateKey) async {
    return Secp256k1SchnorrKeyStore.fromPrivate(privateKey);
  }

  @override
  Future<EventSigner> generateSigner() async {
    return Secp256k1SchnorrKeyStore.generate();
  }
}

@Riverpod(keepAlive: true)
class Ed25519IonConnectEventSignerProvider extends _$Ed25519IonConnectEventSignerProvider {
  late final GenericEventSigner _signer;

  @override
  Future<EventSigner?> build(String identityKeyName) async {
    _signer = Ed25519IonConnectEventSigner(identityKeyName: identityKeyName);
    final storage = ref.watch(secureStorageProvider);
    return _signer.loadFromStorage(storage);
  }

  Future<void> delete() async {
    final storage = ref.read(secureStorageProvider);
    await _signer.deleteFromStorage(storage);
  }

  Future<EventSigner?> initEventSigner() async {
    final currentEventSigner = await future;
    if (currentEventSigner != null) {
      return currentEventSigner;
    }

    if (await _signer.shouldSkipInitialization(ref)) {
      return null;
    }

    return _generate();
  }

  Future<EventSigner> restoreFromPrivateKey(String privateKey) async {
    final keyStore = await _signer.createSignerFromPrivateKey(privateKey);
    return _setEventSigner(keyStore);
  }

  Future<EventSigner> _generate() async {
    final signer = await _signer.generateSigner();
    return _setEventSigner(signer);
  }

  Future<EventSigner> _setEventSigner(EventSigner signer) async {
    final storage = ref.read(secureStorageProvider);
    await _signer.saveToStorage(storage, signer);
    state = AsyncData(signer);
    return signer;
  }
}

@Riverpod(keepAlive: true)
class Secp256k1IonConnectEventSignerProvider extends _$Secp256k1IonConnectEventSignerProvider {
  late final GenericEventSigner _signer;

  @override
  Future<EventSigner?> build(String identityKeyName) async {
    _signer = Secp256k1IonConnectEventSigner(identityKeyName: identityKeyName);
    final storage = ref.watch(secureStorageProvider);
    return _signer.loadFromStorage(storage);
  }

  Future<void> delete() async {
    final storage = ref.read(secureStorageProvider);
    await _signer.deleteFromStorage(storage);
  }

  Future<EventSigner?> initEventSigner() async {
    final currentEventSigner = await future;
    if (currentEventSigner != null) {
      return currentEventSigner;
    }

    return _generate();
  }

  Future<EventSigner> restoreFromPrivateKey(String privateKey) async {
    final keyStore = await _signer.createSignerFromPrivateKey(privateKey);
    return _setEventSigner(keyStore);
  }

  Future<EventSigner> _generate() async {
    final signer = await _signer.generateSigner();
    return _setEventSigner(signer);
  }

  Future<EventSigner> _setEventSigner(EventSigner signer) async {
    final storage = ref.read(secureStorageProvider);
    await _signer.saveToStorage(storage, signer);
    state = AsyncData(signer);
    return signer;
  }
}

@Riverpod(keepAlive: true)
Future<EventSigner?> currentUserEventSigner(Ref ref, SigningAlgorithm algorithm) async {
  final currentIdentityKeyName = ref.watch(currentIdentityKeyNameSelectorProvider);
  if (currentIdentityKeyName == null) {
    return null;
  }

  // Get the signer from the algorithm-specific provider
  final eventSigner = switch (algorithm) {
    SigningAlgorithm.ed25519 =>
      await ref.watch(ed25519IonConnectEventSignerProviderProvider(currentIdentityKeyName).future),
    SigningAlgorithm.secp256k1Schnorr => await ref
        .watch(secp256k1IonConnectEventSignerProviderProvider(currentIdentityKeyName).future),
  };

  // If signer doesn't exist, initialize it
  if (eventSigner == null) {
    return switch (algorithm) {
      SigningAlgorithm.ed25519 => await ref
          .read(ed25519IonConnectEventSignerProviderProvider(currentIdentityKeyName).notifier)
          .initEventSigner(),
      SigningAlgorithm.secp256k1Schnorr => await ref
          .read(secp256k1IonConnectEventSignerProviderProvider(currentIdentityKeyName).notifier)
          .initEventSigner(),
    };
  }

  return eventSigner;
}

// Backward compatibility - keep the old name
@Riverpod(keepAlive: true)
Future<EventSigner?> currentUserIonConnectEventSigner(Ref ref) async {
  return ref.watch(currentUserEventSignerProvider(SigningAlgorithm.ed25519).future);
}

// Backward compatibility - keep the old name
@Riverpod(keepAlive: true)
Future<EventSigner?> ionConnectEventSigner(Ref ref, String identityKeyName) async {
  final eventSigner =
      await ref.watch(ed25519IonConnectEventSignerProviderProvider(identityKeyName).future);
  return eventSigner;
}
