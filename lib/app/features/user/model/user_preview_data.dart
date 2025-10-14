// SPDX-License-Identifier: ice License 1.0

abstract class UserPreviewData {
  const UserPreviewData({
    required this.name,
    required this.displayName,
    this.picture,
  });

  final String name;
  final String displayName;
  final String? picture;
}
