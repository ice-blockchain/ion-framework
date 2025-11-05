// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert';

import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_direct_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/send_chat_message_service.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/request_coins_form_data.f.dart';
import 'package:ion/app/features/user/providers/request_coins_form_provider.r.dart';
import 'package:ion/app/features/user/providers/user_delegation_provider.r.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/features/wallets/domain/transactions/send_transaction_to_relay_service.r.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'request_coins_submit_notifier.r.g.dart';

typedef _PubkeysRecord = ({
  String masterPubkey,
  List<String> devicePubkeys,
});

typedef _PubkeysCollection = ({
  _PubkeysRecord sender,
  _PubkeysRecord receiver,
});

const _formName = 'RequestCoinsForm';

@riverpod
class RequestCoinsSubmitNotifier extends _$RequestCoinsSubmitNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> submitRequest() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final formData = ref.read(requestCoinsFormControllerProvider);
      _validateFormData(formData);

      final currentUserPubkey = ref.read(currentPubkeySelectorProvider);
      if (currentUserPubkey == null) {
        throw const CurrentUserNotFoundException();
      }

      final request = await _buildFundsRequestData(formData, currentUserPubkey);
      final pubkeys = await _collectPubkeys(formData.contactPubkey!, currentUserPubkey);

      final sendToRelayService = await ref.read(sendTransactionToRelayServiceProvider.future);
      final event = await sendToRelayService.sendTransactionEntity(
        createEventMessage: (devicePubkey, masterPubkey) => request.toEventMessage(
          devicePubkey: devicePubkey,
          masterPubkey: masterPubkey,
        ),
        senderPubkeys: pubkeys.sender,
        receiverPubkeys: pubkeys.receiver,
      );

      final eventReference = ImmutableEventReference(
        eventId: event.id,
        masterPubkey: currentUserPubkey,
        kind: event.kind,
      );

      final content = eventReference.encode();
      final tag = eventReference.toTag();

      final paymentRequestedTag = [
        EncryptedDirectMessageData.paymentRequestedTagName,
        jsonEncode(event.jsonPayload),
      ];

      final chatService = await ref.read(sendChatMessageServiceProvider.future);
      await chatService.send(
        kind: event.kind,
        receiverPubkey: pubkeys.receiver.masterPubkey,
        content: content,
        tags: [tag, paymentRequestedTag],
      );
    });
  }

  void _validateFormData(RequestCoinsFormData formData) {
    final errors = <String>[];

    if (formData.assetData == null) {
      errors.add('Asset data is required');
    }
    if (formData.network == null) {
      errors.add('Network is required');
    }
    if (formData.contactPubkey == null) {
      errors.add('Contact pubkey is required');
    }

    final toWalletAddress = formData.toWallet?.address;
    final fromWalletAddress = formData.toWallet?.address;

    if (toWalletAddress == null) {
      errors.add('toWallet address is required');
    }
    if (fromWalletAddress == null) {
      errors.add('fromWallet address is required');
    }

    final amount = formData.assetData?.amount;
    if (amount != null && amount <= 0) {
      errors.add('Amount must be greater than 0');
    }

    if (errors.isNotEmpty) {
      throw FormException(errors.join(', '), formName: _formName);
    }
  }

  Future<FundsRequestData> _buildFundsRequestData(
    RequestCoinsFormData formData,
    String currentUserPubkey,
  ) async {
    final RequestCoinsFormData(:assetData, :network, :contactPubkey, :toWallet) = formData;

    final user = await ref.read(userMetadataProvider(contactPubkey!).future);

    final toWalletAddress = toWallet!.address!;
    final fromWalletAddress = user!.data.wallets![network!.id]!;

    final content = FundsRequestContent(
      from: fromWalletAddress,
      to: toWalletAddress,
      assetId: assetData!.selectedOption!.coin.id,
      amount: assetData.amount > 0 ? assetData.amount.toString() : null,
      amountUsd: assetData.amountUSD > 0 ? assetData.amountUSD.toString() : null,
    );

    final contractAddress = assetData.selectedOption!.coin.contractAddress;
    final isNative = contractAddress.isEmpty;

    return FundsRequestData(
      networkId: network.id,
      assetClass: isNative ? 'native' : 'token',
      assetAddress: contractAddress,
      pubkey: currentUserPubkey,
      walletAddress: toWalletAddress,
      content: content,
    );
  }

  Future<_PubkeysCollection> _collectPubkeys(String contactPubkey, String currentUserPubkey) async {
    final currentUserDelegation = await ref.read(currentUserDelegationProvider.future);
    final contactDelegation = await ref.read(userDelegationProvider(contactPubkey).future);

    final senderDevicePubkeys =
        currentUserDelegation?.data.delegates.map((e) => e.pubkey).toList() ?? [];
    final receiverDevicePubkeys =
        contactDelegation?.data.delegates.map((e) => e.pubkey).toList() ?? [];

    if (senderDevicePubkeys.isEmpty && receiverDevicePubkeys.isEmpty) {
      throw FormException(
        'No device pubkeys found for either sender or receiver',
        formName: _formName,
      );
    }

    return (
      sender: (
        masterPubkey: currentUserPubkey,
        devicePubkeys: senderDevicePubkeys,
      ),
      receiver: (
        masterPubkey: contactPubkey,
        devicePubkeys: receiverDevicePubkeys,
      ),
    );
  }
}
