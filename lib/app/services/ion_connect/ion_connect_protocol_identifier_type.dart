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
  static bool isProfileIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):nprofile1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isEventIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):nevent1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isAddressIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):naddr1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isPrivateKeyIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):nsec1[a-z0-9]{58}$').hasMatch(value ?? '');
  static bool isPublicKeyIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):npub1[a-z0-9]{58}$').hasMatch(value ?? '');
  static bool isNoteIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):note1[a-z0-9]+$').hasMatch(value ?? '');
  static bool isEncryptedPrivateKeyIdentifier(String? value) =>
      RegExp(r'^(nostr|ion):ncryptsec1[a-z0-9]+$').hasMatch(value ?? '');
}
