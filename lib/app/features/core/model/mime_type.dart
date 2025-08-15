// SPDX-License-Identifier: ice License 1.0

/// MIME types used for ION Connect network communication.
///
/// These MIME types are sent over the network to ION Connect and other
/// network endpoints. They represent the standardized format that the ION Connect
/// protocol expects for different media types.
enum MimeType {
  /// WebP format for images sent to ION Connect
  image('image/webp'),

  /// Special format for GIFs converted to WebP for network transmission
  gif('image/gif+webp'),

  /// MP4 format for videos sent to ION Connect
  video('video/mp4'),

  /// OGG format for audio sent to ION Connect
  audio('audio/ogg'),

  /// Brotli compressed format for ION Connect
  brotli('application/brotli'),

  /// Generic binary format for ION Connect
  generic('application/octet-stream');

  const MimeType(this.value);

  final String value;
}

/// MIME types used internally within the app for local processing.
///
/// These MIME types are used for runtime operations, local file handling,
/// and platform-specific features within the app. They never get transmitted
/// over the network to ION Connect or other external services.
enum LocalMimeType {
  /// Standard GIF format for local file handling and platform features
  gif('image/gif'),

  /// JPEG format used for local processing (e.g., push notifications)
  jpeg('image/jpeg');

  const LocalMimeType(this.value);

  final String value;
}
