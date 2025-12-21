// SPDX-License-Identifier: ice License 1.0

enum IonConnectProtocolIdentifierType {
  nsec,
  npub,
  note,
  nprofile,
  nevent,
  naddr;

  static IonConnectProtocolIdentifierType from(String name) =>
      IonConnectProtocolIdentifierType.values.byName(name.toLowerCase());
}

class IonConnectProtocolIdentifierTypeValidator {
  static bool isNostrProfileIdentifier(String? value) =>
      RegExp(r'^nostr:nprofile1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isNostrEventIdentifier(String? value) =>
      RegExp(r'^nostr:nevent1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isNostrAddressIdentifier(String? value) =>
      RegExp(r'^nostr:naddr1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isNostrPrivateKeyIdentifier(String? value) =>
      RegExp(r'^nostr:nsec1[a-z0-9]{58}$').hasMatch(value ?? '');
  static bool isNostrPublicKeyIdentifier(String? value) =>
      RegExp(r'^nostr:npub1[a-z0-9]{58}$').hasMatch(value ?? '');
  static bool isNostrNoteIdentifier(String? value) =>
      RegExp(r'^nostr:note1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isNostrEncryptedPrivateKeyIdentifier(String? value) =>
      RegExp(r'^nostr:ncryptsec1[a-z0-9]+$').hasMatch(value ?? '');

  static bool isIonProfileIdentifier(String? value) =>
      RegExp(r'^ion:nprofile1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isIonEventIdentifier(String? value) =>
      RegExp(r'^ion:nevent1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isIonAddressIdentifier(String? value) =>
      RegExp(r'^ion:naddr1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isIonPrivateKeyIdentifier(String? value) =>
      RegExp(r'^ion:nsec1[a-z0-9]{58}$').hasMatch(value ?? '');
  static bool isIonPublicKeyIdentifier(String? value) =>
      RegExp(r'^ion:npub1[a-z0-9]{58}$').hasMatch(value ?? '');
  static bool isIonNoteIdentifier(String? value) =>
      RegExp(r'^ion:note1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isIonEncryptedPrivateKeyIdentifier(String? value) =>
      RegExp(r'^ion:ncryptsec1[a-z0-9]+$').hasMatch(value ?? '');
}
