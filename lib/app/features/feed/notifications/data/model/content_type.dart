// SPDX-License-Identifier: ice License 1.0

enum ContentType {
  posts(0),
  stories(1),
  articles(2),
  videos(3),
  tokenizedCommunitiesTransactions(4);

  const ContentType(this.value);
  final int value;

  static ContentType fromValue(int value) {
    return ContentType.values.firstWhere((type) => type.value == value);
  }
}
