// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fund_request_tag_handler.r.g.dart';

/// Handles a funds request (1755) embedded as a tag on an 30014
class FundsRequestTagHandler {
  FundsRequestTagHandler(this._repo);

  final RequestAssetsRepository _repo;

  /// Looks for the `paymentRequested` tag, rebuilds the 1755 EventMessage from JSON,
  /// and persists it to the wallets DB
  Future<void> handle(EventMessage? event) async {
    if (event == null) {
      return;
    }
    try {
      final tag = event.tags.firstWhereOrNull(
        (t) =>
            t.isNotEmpty && t.first == ReplaceablePrivateDirectMessageData.paymentRequestedTagName,
      );
      if (tag == null || tag.length < 2) {
        return;
      }

      final rawJson = tag[1];
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final requestEvent = EventMessage.fromPayloadJson(decoded);
      final request = FundsRequestEntity.fromEventMessage(requestEvent);

      final updated = request.copyWith(
        data: request.data.copyWith(request: rawJson),
      );

      await _repo.saveRequestAsset(updated);
      Logger.log('[FundsRequestTagHandler] persisted 1755 from tag: ${request.id}');
    } catch (e, _) {
      Logger.log('[FundsRequestTagHandler] failed to persist 1755 from tag: $e');
    }
  }
}

@riverpod
Future<FundsRequestTagHandler> fundsRequestTagHandler(Ref ref) async {
  final requestAssetsRepository = ref.watch(requestAssetsRepositoryProvider);
  return FundsRequestTagHandler(requestAssetsRepository);
}
