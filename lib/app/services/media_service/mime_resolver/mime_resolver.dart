import 'package:mime/mime.dart';

final ionMimeTypeResolver = MimeTypeResolver.empty()
  ..addMagicNumber(
    [79, 103, 103, 83, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0],
    'audio/ogg',
  )
  ..addMagicNumber(
    [37, 80, 68, 70],
    'application/pdf',
  )
  ..addMagicNumber(
    [171, 108, 216, 80, 193],
    'application/pdf',
  )
  ..addMagicNumber(
    [171, 122, 54, 81, 192],
    'application/pdf',
  )
  ..addMagicNumber(
    [37, 81],
    'application/postscript',
  )
  ..addMagicNumber(
    [70, 79, 82, 77, 0, 0, 0, 0, 65, 73, 70, 70],
    'audio/x-aiff',
    mask: [255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [102, 76, 97, 67],
    'audio/x-flac',
  )
  ..addMagicNumber(
    [82, 73, 70, 70, 0, 0, 0, 0, 87, 65, 86, 69],
    'audio/x-wav',
    mask: [255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [71, 73, 70, 56, 57, 97],
    'image/gif',
  )
  ..addMagicNumber(
    [255, 216],
    'image/jpeg',
  )
  ..addMagicNumber(
    [137, 80, 78, 71, 13, 10, 26, 10],
    'image/png',
  )
  ..addMagicNumber(
    [73, 73, 42, 0],
    'image/tiff',
  )
  ..addMagicNumber(
    [77, 77, 0, 42],
    'image/tiff',
  )
  ..addMagicNumber(
    [255, 241],
    'audio/aac',
  )
  ..addMagicNumber(
    [255, 249],
    'audio/aac',
  )
  ..addMagicNumber(
    [26, 69, 223, 163],
    'audio/weba',
  )
  ..addMagicNumber(
    [73, 68, 51],
    'audio/mpeg',
  )
  ..addMagicNumber(
    [255, 251],
    'audio/mpeg',
  )
  ..addMagicNumber(
    [79, 112, 117],
    'audio/ogg',
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 51, 103, 112, 53],
    'video/3gpp',
    mask: [255, 255, 255, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 97, 118, 99, 49],
    'video/mp4',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 105, 115, 111, 50],
    'video/mp4',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 105, 115, 111, 109],
    'video/mp4',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 109, 112, 52, 49],
    'video/mp4',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 109, 112, 52, 50],
    'video/mp4',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [70, 84, 108, 103],
    'model/gltf-binary',
  )
  ..addMagicNumber(
    [82, 73, 70, 70, 0, 0, 0, 0, 87, 69, 66, 80],
    'image/webp',
    mask: [255, 255, 255, 255, 0, 0, 0, 0, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [119, 79, 70, 50],
    'font/woff2',
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 104, 101, 105, 99],
    'image/heic',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 104, 101, 105, 120],
    'image/heic',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  )
  ..addMagicNumber(
    [0, 0, 0, 0, 102, 116, 121, 112, 109, 105, 102, 49],
    'image/heif',
    mask: [0, 0, 0, 0, 255, 255, 255, 255, 255, 255, 255, 255],
  );
