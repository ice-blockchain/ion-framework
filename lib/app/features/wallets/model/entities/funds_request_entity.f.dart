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
import 'package:ion/app/features/wallets/model/entities/tags/asset_address_tag.f.dart';
import 'package:ion/app/features/wallets/model/entities/tags/asset_class_tag.f.dart';
import 'package:ion/app/features/wallets/model/entities/tags/network_tag.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';

part 'funds_request_entity.f.freezed.dart';
part 'funds_request_entity.f.g.dart';

@Freezed(equal: false)
class FundsRequestEntity with IonConnectEntity, ImmutableEntity, _$FundsRequestEntity {
  const factory FundsRequestEntity({
    required String id,
    required String pubkey,
    required String masterPubkey,
    required int createdAt,
    required FundsRequestData data,
    EventMessage? eventMessage,
  }) = _FundsRequestEntity;

  const FundsRequestEntity._();

  factory FundsRequestEntity.fromEventMessage(EventMessage eventMessage) {
    if (eventMessage.kind != kind) {
      throw IncorrectEventKindException(eventMessage.id, kind: kind);
    }

    final parsed = FundsRequestEntity(
      id: eventMessage.id,
      pubkey: eventMessage.pubkey,
      masterPubkey: eventMessage.masterPubkey,
      createdAt: eventMessage.createdAt,
      data: FundsRequestData.fromEventMessage(eventMessage),
      eventMessage: eventMessage,
    );

    return parsed;
  }

  static const int kind = 1755;

  @override
  String get signature => '';
}

@freezed
class FundsRequestData with _$FundsRequestData {
  const factory FundsRequestData({
    required FundsRequestContent content,
    @JsonKey(name: 'network') required String networkId,
    required String assetClass,
    required String assetAddress,
    String? walletAddress,
    String? pubkey,
    String? request,
    TransactionData? transaction,
    String? transactionId,
    @Default(false) bool deleted,
  }) = _FundsRequestData;

  const FundsRequestData._();

  factory FundsRequestData.fromEventMessage(EventMessage eventMessage) {
    final tags = groupBy(eventMessage.tags, (tag) => tag[0]);
    final decodedContent = jsonDecode(eventMessage.content) as Map<String, dynamic>;

    return FundsRequestData(
      content: FundsRequestContent.fromJson(decodedContent),
      pubkey: tags[RelatedPubkey.tagName]?.map(RelatedPubkey.fromTag).first.value,
      networkId: tags[NetworkTag.tagName]!.map(NetworkTag.fromTag).first.value,
      assetClass: tags[AssetClassTag.tagName]!.map(AssetClassTag.fromTag).first.value,
      assetAddress: tags[AssetAddressTag.tagName]!.map(AssetAddressTag.fromTag).first.value,
      request: jsonEncode(eventMessage.toJson()),
    );
  }

  EventMessage toEventMessage({
    required String devicePubkey,
    required String masterPubkey,
  }) {
    final tags = [
      MasterPubkeyTag(value: masterPubkey).toTag(),
      NetworkTag(value: networkId).toTag(),
      AssetClassTag(value: assetClass).toTag(),
      AssetAddressTag(value: assetAddress).toTag(),
      if (pubkey != null) RelatedPubkey(value: pubkey!).toTag(),
    ];

    final createdAt = DateTime.now();

    final encodedContent = jsonEncode(content.toJson());

    final rumorId = EventMessage.calculateEventId(
      publicKey: devicePubkey,
      createdAt: createdAt.microsecondsSinceEpoch,
      kind: FundsRequestEntity.kind,
      tags: tags,
      content: encodedContent,
    );

    return EventMessage(
      id: rumorId,
      pubkey: devicePubkey,
      createdAt: createdAt.microsecondsSinceEpoch,
      kind: FundsRequestEntity.kind,
      tags: tags,
      content: encodedContent,
      sig: null,
    );
  }
}

@freezed
class FundsRequestContent with _$FundsRequestContent {
  const factory FundsRequestContent({
    required String from,
    required String to,
    @JsonKey(includeIfNull: false) String? assetId,
    @JsonKey(includeIfNull: false) String? amount,
    @JsonKey(includeIfNull: false) String? amountUsd,
  }) = _FundsRequestContent;

  factory FundsRequestContent.fromJson(Map<String, dynamic> json) =>
      _$FundsRequestContentFromJson(json);
}
