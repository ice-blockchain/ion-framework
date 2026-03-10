// SPDX-License-Identifier: ice License 1.0

/// Class representing the content type of the native media view.
///
/// [contentName] The name of the content type.
enum NativeMediaViewContentType {
  /// Auto content type.
  auto._(contentName: 'auto'),

  /// NoVideo content type.
  noVideo._(contentName: 'static'),

  /// Video content type.
  video._(contentName: 'video');

  const NativeMediaViewContentType._({required this.contentName});

  final String contentName;
}
