// SPDX-License-Identifier: ice License 1.0

abstract class UserPreviewEntity {
  String get masterPubkey;
  UserPreviewData get data;
}

abstract class UserPreviewData {
  const UserPreviewData({
    required this.name,
    required this.displayName,
    this.avatarUrl,
  });

  final String name;
  final String displayName;
  final String? avatarUrl;

  String get trimmedDisplayName;
}
