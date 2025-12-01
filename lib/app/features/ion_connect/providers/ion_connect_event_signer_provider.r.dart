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
abstract class EventSignerService {
  EventSignerService({
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
  Future<bool> shouldSkipInitialization(Ref ref);

  /// Get the storage key for this signer
  String getStorageKey() => '${identityKeyName}_$storageKeySuffix';
}

/// Ed25519 implementation of IonConnectEventSigner
class Ed25519IonConnectEventSignerService extends EventSignerService {
  Ed25519IonConnectEventSignerService({
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
class Secp256k1IonConnectEventSignerService extends EventSignerService {
  Secp256k1IonConnectEventSignerService({
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

  @override
  Future<bool> shouldSkipInitialization(Ref<Object?> ref) {
    return Future.value(false);
  }
}

@Riverpod(keepAlive: true)
class Ed25519IonConnectEventSigner extends _$Ed25519IonConnectEventSigner {
  late final EventSignerService _signer;

  @override
  Future<EventSigner?> build(String identityKeyName) async {
    _signer = Ed25519IonConnectEventSignerService(identityKeyName: identityKeyName);
    return _loadFromStorage();
  }

  Future<void> delete() async {
    await _deleteFromStorage();
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
    await _saveToStorage(signer);
    state = AsyncData(signer);
    return signer;
  }

  Future<EventSigner?> _loadFromStorage() async {
    final storage = ref.read(secureStorageProvider);
    final storedKey = await storage.getString(key: _signer.getStorageKey());
    if (storedKey != null) {
      return _signer.createSignerFromPrivateKey(storedKey);
    }
    return null;
  }

  Future<void> _saveToStorage(EventSigner signer) async {
    final storage = ref.read(secureStorageProvider);
    await storage.setString(key: _signer.getStorageKey(), value: signer.privateKey);
  }

  Future<void> _deleteFromStorage() async {
    final storage = ref.read(secureStorageProvider);
    await storage.remove(key: _signer.getStorageKey());
  }
}

@Riverpod(keepAlive: true)
class Secp256k1IonConnectEventSigner extends _$Secp256k1IonConnectEventSigner {
  late final EventSignerService _signer;

  @override
  Future<EventSigner?> build(String identityKeyName) async {
    _signer = Secp256k1IonConnectEventSignerService(identityKeyName: identityKeyName);
    return _loadFromStorage();
  }

  Future<void> delete() async {
    await _deleteFromStorage();
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
    await _saveToStorage(signer);
    state = AsyncData(signer);
    return signer;
  }

  Future<EventSigner?> _loadFromStorage() async {
    final storage = ref.read(secureStorageProvider);
    final storedKey = await storage.getString(key: _signer.getStorageKey());
    if (storedKey != null) {
      return _signer.createSignerFromPrivateKey(storedKey);
    }
    return null;
  }

  Future<void> _saveToStorage(EventSigner signer) async {
    final storage = ref.read(secureStorageProvider);
    await storage.setString(key: _signer.getStorageKey(), value: signer.privateKey);
  }

  Future<void> _deleteFromStorage() async {
    final storage = ref.read(secureStorageProvider);
    await storage.remove(key: _signer.getStorageKey());
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
      await ref.watch(ed25519IonConnectEventSignerProvider(currentIdentityKeyName).future),
    SigningAlgorithm.secp256k1Schnorr =>
      await ref.watch(secp256k1IonConnectEventSignerProvider(currentIdentityKeyName).future),
  };

  // If signer doesn't exist, initialize it
  if (eventSigner == null) {
    return switch (algorithm) {
      SigningAlgorithm.ed25519 => await ref
          .read(ed25519IonConnectEventSignerProvider(currentIdentityKeyName).notifier)
          .initEventSigner(),
      SigningAlgorithm.secp256k1Schnorr => await ref
          .read(secp256k1IonConnectEventSignerProvider(currentIdentityKeyName).notifier)
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
  final eventSigner = await ref.watch(ed25519IonConnectEventSignerProvider(identityKeyName).future);
  return eventSigner;
}
