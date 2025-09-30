// SPDX-License-Identifier: ice License 1.0

enum FFmpegVideoCodecArg {
  libx264(name: 'H.264', codec: 'libx264'),
  libvpx(name: 'VP8', codec: 'libvpx'),
  h264(name: 'H.264', codec: 'h264'),
  hevc(name: 'H.265', codec: 'hevc'),
  h264VideoToolbox(name: 'H.264 (VideoToolbox)', codec: 'h264_videotoolbox');

  const FFmpegVideoCodecArg({
    required this.name,
    required this.codec,
  });

  final String name;
  final String codec;
}
