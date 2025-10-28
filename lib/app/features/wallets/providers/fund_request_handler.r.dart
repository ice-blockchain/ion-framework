// SPDX-License-Identifier: ice License 1.0

import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/global_subscription_encrypted_event_message_handler.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_gift_wrap.f.dart';
import 'package:ion/app/features/wallets/data/repository/request_assets_repository.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fund_request_handler.r.g.dart';

class FundsRequestHandler extends GlobalSubscriptionEncryptedEventMessageHandler {
  FundsRequestHandler(this.requestAssetsRepository);

  final RequestAssetsRepository requestAssetsRepository;

  @override
  bool canHandle({required IonConnectGiftWrapEntity entity}) {
    return entity.data.kinds.containsList([FundsRequestEntity.kind.toString()]);
  }

  @override
  Future<EventReference> handle(EventMessage rumor) async {
    final request = FundsRequestEntity.fromEventMessage(rumor);

    final updatedData = request.data.copyWith(request: jsonEncode(rumor.jsonPayload));
    final updatedRequest = request.copyWith(data: updatedData);

    await requestAssetsRepository.saveRequestAsset(updatedRequest);

    return request.toEventReference();
  }
}

@riverpod
Future<FundsRequestHandler> fundsRequestHandler(Ref ref) async {
  final requestAssetsRepository = ref.watch(requestAssetsRepositoryProvider);
  return FundsRequestHandler(requestAssetsRepository);
}
