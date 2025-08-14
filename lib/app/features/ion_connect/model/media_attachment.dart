// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/ion_connect/model/file_alt.dart';
import 'package:ion/app/services/media_service/media_service.m.dart';
import 'package:ion/app/utils/validators.dart';

/// Media attachments (images, videos, and other files) may be added to events by including
/// a URL in the event content, along with a matching imeta tag.
///
/// https://github.com/nostr-protocol/nips/blob/master/92.md
class MediaAttachment {
  MediaAttachment({
    required this.url,
    required this.mimeType,
    required this.originalFileHash,
    this.dimension,
    this.alt,
    this.encryptionKey,
    this.encryptionNonce,
    this.encryptionMac,
    this.thumb,
    this.image,
    this.blurhash,
    this.duration,
  });

  factory MediaAttachment.fromMediaFile(MediaFile mediaFile) {
    return MediaAttachment(
      url: mediaFile.path,
      mimeType: mediaFile.mimeType ?? '',
      dimension: '${mediaFile.width}x${mediaFile.height}',
      alt: FileAlt.message,
      originalFileHash: '',
      image: mediaFile.path,
      blurhash: mediaFile.blurhash,
      thumb: mediaFile.path,
      duration: mediaFile.duration,
    );
  }

  /// https://github.com/nostr-protocol/nips/blob/master/92.md#example
  factory MediaAttachment.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }

    String? url;
    String? mimeType;
    String? dimension;
    String? thumb;
    String? image;
    String? alt;
    String? originalFileHash;
    String? encryptionKey;
    String? encryptionNonce;
    String? encryptionMac;
    String? blurhash;
    int? duration;

    for (final params in tag.skip(1)) {
      final pair = params.split(' ');
      final value = pair[1];
      switch (pair[0]) {
        case 'url':
          {
            if (!Validators.isInvalidUrl(value)) {
              url = value;
            }
          }
        case 'm':
          mimeType = value;
        case 'dim':
          dimension = value;
        case 'thumb':
          thumb = value;
        case 'image':
          image = value;
        case 'alt':
          alt = value;
        case 'blurhash':
          blurhash = value;
        case 'ox':
          originalFileHash = value;
        case 'encryption-key':
          {
            final [key, secretKey, nonce, mac, algorithm] = pair;
            encryptionKey = secretKey;
            encryptionNonce = nonce;
            encryptionMac = mac;
          }
        case 'duration':
          duration = int.tryParse(value);
      }
    }

    return MediaAttachment(
      url: url!,
      mimeType: mimeType!,
      dimension: dimension,
      alt: EnumExtensions.fromShortString(FileAlt.values, alt!),
      originalFileHash: originalFileHash!,
      thumb: thumb,
      image: image,
      encryptionKey: encryptionKey,
      encryptionNonce: encryptionNonce,
      encryptionMac: encryptionMac,
      blurhash: blurhash,
      duration: duration,
    );
  }

  //add for all props tojson and fromjson
  factory MediaAttachment.fromJson(Map<String, dynamic> json) => MediaAttachment(
        url: json['url'] as String,
        mimeType: json['mimeType'] as String,
        dimension: json['dimension'] as String?,
        alt: EnumExtensions.fromShortString(FileAlt.values, json['alt'] as String),
        originalFileHash: json['originalFileHash'] as String,
        encryptionKey: json['encryptionKey'] as String?,
        encryptionNonce: json['encryptionNonce'] as String?,
        encryptionMac: json['encryptionMac'] as String?,
        thumb: json['thumb'] as String?,
        image: json['image'] as String?,
        blurhash: json['blurhash'] as String?,
        duration: json['duration'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'mimeType': mimeType,
        if (dimension != null) 'dimension': dimension,
        if (alt != null) 'alt': alt!.toShortString(),
        'originalFileHash': originalFileHash,
        'encryptionKey': encryptionKey,
        'encryptionNonce': encryptionNonce,
        'encryptionMac': encryptionMac,
        'thumb': thumb,
        'blurhash': blurhash,
        if (duration != 0) 'duration': duration,
      };

  final String url;

  final String mimeType;

  final String? dimension;

  final FileAlt? alt;

  final String originalFileHash;

  final String? thumb;

  final String? image;

  final String? encryptionKey;

  final String? encryptionNonce;

  final String? encryptionMac;

  late double? aspectRatio = _aspectRatioFromDimension(dimension);

  late MediaType mediaType = _parseMediaType(url: url, mimeType: mimeType);

  final String? blurhash;

  final int? duration;

  /// Calculates the aspect ratio from a given dimension string.
  ///
  /// This method takes a dimension string in the format of "WIDTHxHEIGHT"
  /// and returns the aspect ratio (WIDTH divided by HEIGHT) as a double.
  /// If the input string is null, not in the correct format, or contains
  /// invalid dimensions (e.g., zero or non-numeric values), it returns null.
  static double? _aspectRatioFromDimension(String? dimension) {
    if (dimension == null) {
      return null;
    }

    final dimensionRegExp = RegExp(r'(\d+)x(\d+)');

    if (!dimensionRegExp.hasMatch(dimension)) {
      return null;
    }

    final match = dimensionRegExp.firstMatch(dimension);
    final width = double.tryParse(match?.group(1) ?? '0').zeroOrValue;
    final height = double.tryParse(match?.group(2) ?? '0').zeroOrValue;

    return width != 0 && height != 0 ? width / height : null;
  }

  static MediaType _parseMediaType({required String url, String? mimeType}) {
    final mediaTypeFromMime = MediaType.fromMimeType(mimeType.emptyOrValue);
    if (mediaTypeFromMime != MediaType.unknown) {
      return mediaTypeFromMime;
    }
    return MediaType.fromUrl(url);
  }

  List<String> toTag() {
    return [
      tagName,
      'url $url',
      'm $mimeType',
      if (dimension != null) 'dim $dimension',
      if (alt != null) 'alt ${alt!.toShortString()}',
      'ox $originalFileHash',
      if (encryptionKey != null && encryptionNonce != null)
        'encryption-key $encryptionKey $encryptionNonce $encryptionMac aes-gcm',
      if (thumb != null) 'thumb $thumb',
      if (image != null) 'image $image',
      if (blurhash != null) 'blurhash $blurhash',
      if (duration.zeroOrValue > 0) 'duration $duration',
    ];
  }

  static const String tagName = 'imeta';

  @override
  String toString() {
    return 'MediaAttachment(url: $url, mimeType: $mimeType, dimension: $dimension, alt: $alt, originalFileHash: $originalFileHash, thumb: $thumb, image: $image, blurhash: $blurhash, duration: $duration)';
  }

  MediaAttachment copyWith({
    String? url,
    String? mimeType,
    String? dimension,
    FileAlt? alt,
    String? originalFileHash,
    String? thumb,
    String? image,
    String? encryptionKey,
    String? encryptionNonce,
    String? encryptionMac,
    String? blurhash,
    int? duration,
  }) {
    return MediaAttachment(
      url: url ?? this.url,
      mimeType: mimeType ?? this.mimeType,
      dimension: dimension ?? this.dimension,
      alt: alt ?? this.alt,
      originalFileHash: originalFileHash ?? this.originalFileHash,
      thumb: thumb ?? this.thumb,
      image: image ?? this.image,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      encryptionNonce: encryptionNonce ?? this.encryptionNonce,
      encryptionMac: encryptionMac ?? this.encryptionMac,
      blurhash: blurhash ?? this.blurhash,
      duration: duration ?? this.duration,
    );
  }
}
