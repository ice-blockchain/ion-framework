// SPDX-License-Identifier: ice License 1.0

///
/// It defines the type of the community token.
///
enum CommunityTokenType {
  profile(prefix: 'a'),
  post(prefix: 'b'),
  video(prefix: 'c'),
  article(prefix: 'd');

  const CommunityTokenType({required this.prefix});

  final String prefix;
}

enum CommunityTokenSource {
  ionConnect,
  twitter;

  bool get isIonConnect => this == CommunityTokenSource.ionConnect;
  bool get isTwitter => this == CommunityTokenSource.twitter;
}
