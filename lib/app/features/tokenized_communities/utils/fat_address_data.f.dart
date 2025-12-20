// SPDX-License-Identifier: ice License 1.0

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/tokenized_communities/utils/fat_address_codec.dart';
import 'package:ion/app/utils/hex_encoding.dart';

part 'fat_address_data.f.freezed.dart';

@freezed
sealed class FatAddressData with _$FatAddressData {
  const FatAddressData._();

  const factory FatAddressData.creator({
    required String symbol,
    required String name,
    required String externalAddress,
    required String externalTypePrefix,
    required String creatorAddress,
    String? affiliateAddress,
  }) = CreatorFatAddressData;

  const factory FatAddressData.content({
    required String symbol,
    required String name,
    required String externalAddress,
    required String externalTypePrefix,
    required String creatorAddress,
    required String creatorTokenAddress,
    String? affiliateAddress,
  }) = ContentFatAddressData;

  String? get creatorTokenAddress => maybeMap(
        content: (c) => c.creatorTokenAddress,
        orElse: () => null,
      );

  Uint8List toFatAddressBytes() {
    return const FatAddressCodec().encode(
      symbol: symbol,
      name: name,
      externalAddress: externalAddress,
      externalTypePrefix: externalTypePrefix,
      creatorAddress: creatorAddress,
      affiliateAddress: affiliateAddress,
      creatorTokenAddress: creatorTokenAddress,
    );
  }

  String toFatAddressHex() {
    return bytesToHex(toFatAddressBytes());
  }
}
