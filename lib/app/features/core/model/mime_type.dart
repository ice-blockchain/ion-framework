// SPDX-License-Identifier: ice License 1.0

enum MimeType {
  image('image/webp'),
  gif('image/gif+webp'),
  video('video/mp4'),
  audio('audio/ogg'),
  brotli('application/brotli'),
  generic('application/octet-stream');

  const MimeType(this.value);

  final String value;
}

enum LocalMimeType {
  gif('image/gif'),
  jpeg('image/jpeg');

  const LocalMimeType(this.value);

  final String value;
}
