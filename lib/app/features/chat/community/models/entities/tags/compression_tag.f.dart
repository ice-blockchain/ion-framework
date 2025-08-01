// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:nip44/nip44.dart';

part 'compression_tag.f.freezed.dart';

@freezed
class CompressionTag with _$CompressionTag {
  const factory CompressionTag({
    required String value,
  }) = _CompressionTag;

  factory CompressionTag.fromTag(List<String> tag) {
    if (tag[0] != tagName) {
      throw IncorrectEventTagNameException(actual: tag[0], expected: tagName);
    }
    if (tag.length != 2) {
      throw IncorrectEventTagException(tag: tag.toString());
    }

    return CompressionTag(value: tag[1]);
  }

  const CompressionTag._();

  CompressionAlgorithm get algorithm {
    return CompressionAlgorithm.values.firstWhere(
      (element) => element.name == value,
      orElse: () => CompressionAlgorithm.none,
    );
  }

  static const String tagName = 'payload-compression';

  List<String> toTag() {
    return [tagName, value];
  }
}
