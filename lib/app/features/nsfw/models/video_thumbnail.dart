import 'dart:typed_data';

class VideoThumbnail {
  const VideoThumbnail({
    required this.path,
    required this.bytes,
    required this.videoPath,
  });

  final String path;
  final Uint8List bytes;
  final String videoPath;
}
