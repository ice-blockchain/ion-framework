// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/wallets/data/database/wallets_database.m.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/transaction_data.f.dart';

class FundsRequestMapper {
  FundsRequest toDatabase(FundsRequestEntity entity) {
    return FundsRequest(
      eventId: entity.id,
      pubkey: entity.pubkey,
      createdAt: entity.createdAt,
      networkId: entity.data.networkId,
      assetClass: entity.data.assetClass,
      assetAddress: entity.data.assetAddress,
      from: entity.data.content.from,
      to: entity.data.content.to,
      walletAddress: entity.data.walletAddress,
      userPubkey: entity.data.pubkey,
      assetId: entity.data.content.assetId,
      amount: entity.data.content.amount,
      amountUsd: entity.data.content.amountUsd,
      request: entity.data.request,
      transactionId: entity.data.transaction?.id,
      deleted: false,
    );
  }

  List<FundsRequest> listToDatabase(List<FundsRequestEntity> entities) {
    return entities.map(toDatabase).toList();
  }

  FundsRequestEntity toDomain(FundsRequest db, TransactionData? transaction) {
    return FundsRequestEntity(
      id: db.eventId,
      pubkey: db.pubkey,
      masterPubkey: db.pubkey,
      createdAt: db.createdAt,
      data: FundsRequestData(
        content: FundsRequestContent(
          from: db.from,
          to: db.to,
          assetId: db.assetId,
          amount: db.amount,
          amountUsd: db.amountUsd,
        ),
        networkId: db.networkId,
        assetClass: db.assetClass,
        assetAddress: db.assetAddress,
        walletAddress: db.walletAddress,
        pubkey: db.userPubkey,
        request: db.request,
        transaction: transaction,
        transactionId: db.transactionId,
        deleted: db.deleted,
      ),
    );
  }

  bool isDeleted(FundsRequest db) {
    return db.deleted;
  }
}
