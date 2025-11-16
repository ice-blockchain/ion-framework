// SPDX-License-Identifier: ice License 1.0

class TopHolder {
  const TopHolder({
    required this.displayName,
    required this.handle,
    required this.amount,
    required this.percentShare,
    this.avatarUrl,
  });

  final String displayName;
  final String handle; // e.g. @janedoe
  final String? avatarUrl;
  final double amount; // holder balance/count
  final double percentShare; // 0..100
}
