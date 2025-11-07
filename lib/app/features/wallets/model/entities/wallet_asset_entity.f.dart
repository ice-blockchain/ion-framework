// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/community/models/entities/tags/master_pubkey_tag.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/related_pubkey.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/tags/asset_address_tag.f.dart';
import 'package:ion/app/features/wallets/model/entities/tags/asset_class_tag.f.dart';
import 'package:ion/app/features/wallets/model/entities/tags/network_tag.f.dart';
import 'package:ion/app/features/wallets/model/entities/tags/request_tag.f.dart';

part 'wallet_asset_entity.f.freezed.dart';
part 'wallet_asset_entity.f.g.dart';

@Freezed(equal: false)
class WalletAssetEntity with IonConnectEntity, ImmutableEntity, _$WalletAssetEntity {
  const factory WalletAssetEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required int createdAt,
    required WalletAssetData data,
    EventMessage? eventMessage,
  }) = _WalletAssetEntity;

  const WalletAssetEntity._();

  factory WalletAssetEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    final parsed = WalletAssetEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      createdAt: eventMessage.createdAt,
      data: WalletAssetData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );

    return parsed;
  }

  static const int kind = 1756;

  @override
  String get signature => '';
}

@freezed
class WalletAssetData with _$WalletAssetData {
  const factory WalletAssetData({
    required WalletAssetContent content,
    @JsonKey(name: 'network') required String networkId,
    required String assetClass,
    required String assetAddress,
    String? walletAddress,
    String? pubkey,
    String? request,
  }) = _WalletAssetData;

  const WalletAssetData._();

  factory WalletAssetData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final decodedContent = jsonDecode(eventMessage.content) as Map<String, dynamic>;
    return WalletAssetData(
      content: WalletAssetContent.fromJson(decodedContent),
      pubkey: tags[RelatedPubkey.tagName]?.map(RelatedPubkey.fromTag).first.value,
      networkId: tags[NetworkTag.tagName]!.map(NetworkTag.fromTag).first.value,
      assetClass: tags[AssetClassTag.tagName]!.map(AssetClassTag.fromTag).first.value,
      assetAddress: tags[AssetAddressTag.tagName]!.map(AssetAddressTag.fromTag).first.value,
      request: tags[RequestTag.tagName]?.map(RequestTag.fromTag).first.value,
    );
  }

  EventMessage toEventMessage({
    required String devicePubkey,
    required String masterPubkey,
    FundsRequestEntity? requestEntity,
  }) {
    final tags = [
      MasterPubkeyTag(value: masterPubkey).toTag(),
      NetworkTag(value: networkId).toTag(),
      AssetClassTag(value: assetClass).toTag(),
      AssetAddressTag(value: assetAddress).toTag(),
      if (pubkey != null) RelatedPubkey(value: pubkey!).toTag(),
      if (requestEntity != null) RequestTag(value: requestEntity.data.request!).toTag(),
    ];

    final createdAt = DateTime.now();

    final encodedContent = jsonEncode(content.toJson());

    final rumorId = EventMessage.calculateEventId(
      publicKey: devicePubkey,
      createdAt: createdAt.microsecondsSinceEpoch,
      kind: WalletAssetEntity.kind,
      tags: tags,
      content: encodedContent,
    );

    return EventMessage(
      id: rumorId,
      pubkey: devicePubkey,
      createdAt: createdAt.microsecondsSinceEpoch,
      kind: WalletAssetEntity.kind,
      tags: tags,
      content: encodedContent,
      sig: null,
    );
  }
}

@JsonSerializable(createToJson: true, includeIfNull: false)
class WalletAssetContent {
  const WalletAssetContent({
    required this.txUrl,
    required this.txHash,
    required this.from,
    required this.to,
    this.assetId,
    this.amount,
    this.amountUsd,
  });

  factory WalletAssetContent.fromJson(Map<String, dynamic> json) =>
      _$WalletAssetContentFromJson(json);

  final String txUrl;
  final String txHash;
  final String from; // address
  final String to; // address

  /// the identifier of the NFT in the collection; used only for NFTs
  final String? assetId;

  /// the transfer amount in native discriminator:I.E. if bitcoin, amount is in Satoshi; used only for coins/fungible tokens
  final String? amount;

  /// the decimal value amount priced in USD at the time of the transfer; used only for coins/fungible tokens
  final String? amountUsd;

  Map<String, dynamic> toJson() => _$WalletAssetContentToJson(this);
}
