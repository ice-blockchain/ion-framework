// SPDX-License-Identifier: ice License 1.0

///
/// It defines the type of the community token.
///
enum CommunityTokenType {
  profile,
  post,
  video,
  article,
  anyPost;

  /// Returns true if this token type is a creator token (profile).
  /// Creator tokens are profile tokens, all other types are content tokens.
  bool get isCreatorToken => this == CommunityTokenType.profile;
}

enum CommunityTokenSource {
  ionConnect,
  twitter;

  bool get isIonConnect => this == CommunityTokenSource.ionConnect;
  bool get isTwitter => this == CommunityTokenSource.twitter;
}
