// SPDX-License-Identifier: ice License 1.0

///
/// It defines the type of the community token.
///
enum CommunityTokenType { profile, post, video, article }

enum CommunityTokenSource {
  ionConnect,
  twitter;

  bool get isIonConnect => this == CommunityTokenSource.ionConnect;
  bool get isTwitter => this == CommunityTokenSource.twitter;
}
