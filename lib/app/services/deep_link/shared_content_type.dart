// SPDX-License-Identifier: ice License 1.0

enum SharedContentType {
  story,
  post,
  postWithVideo,
  article,
  profile;

  String get value {
    return switch (this) {
      SharedContentType.story => 'story',
      SharedContentType.post => 'post',
      SharedContentType.postWithVideo => 'post_with_video',
      SharedContentType.article => 'article',
      SharedContentType.profile => 'profile',
    };
  }

  static SharedContentType fromValue(String value) {
    return switch (value) {
      'story' => SharedContentType.story,
      'post' => SharedContentType.post,
      'post_with_video' => SharedContentType.postWithVideo,
      'article' => SharedContentType.article,
      'profile' => SharedContentType.profile,
      _ => throw ArgumentError('Unknown shared content type: $value'),
    };
  }
}
