// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/icons/coin_icon.dart';
import 'package:ion/app/components/icons/wallet_item_icon_type.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/extensions/object.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/providers/coin_group_provider.r.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/model/money_message_type.dart';
import 'package:ion/app/features/chat/recent_chats/providers/money_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/components.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/money_message/components/money_message_button.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/wallets/model/coin_data.f.dart';
import 'package:ion/app/features/wallets/model/entities/funds_request_entity.f.dart';
import 'package:ion/app/features/wallets/model/entities/wallet_asset_entity.f.dart';
import 'package:ion/app/features/wallets/model/network_data.f.dart';
import 'package:ion/app/features/wallets/providers/coins_provider.r.dart';
import 'package:ion/app/features/wallets/providers/networks_provider.r.dart';
import 'package:ion/app/features/wallets/views/utils/crypto_formatter.dart';
import 'package:ion/app/utils/num.dart';

part 'components/amount_display.dart';

class MoneyMessage extends StatelessWidget {
  const MoneyMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    super.key,
  });

  final VoidCallback? onTapReply;
  final EventMessage eventMessage;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context) {
    final eventReference =
        EventReference.fromEncoded(eventMessage.content) as ImmutableEventReference;

    return switch (eventReference.kind) {
      FundsRequestEntity.kind => _RequestedMoneyMessage(
          margin: margin,
          eventMessage: eventMessage,
          eventReference: eventReference,
          onTapReply: onTapReply,
        ),
      WalletAssetEntity.kind => _SentMoneyMessage(
          margin: margin,
          eventMessage: eventMessage,
          eventReference: eventReference,
          onTapReply: onTapReply,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _RequestedMoneyMessage extends ConsumerWidget {
  const _RequestedMoneyMessage({
    required this.eventMessage,
    required this.eventReference,
    required this.margin,
    this.onTapReply,
  });

  final EdgeInsetsDirectional? margin;
  final VoidCallback? onTapReply;
  final EventMessage eventMessage;
  final ImmutableEventReference eventReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));

    final fundsRequest = ref.watch(fundsRequestForMessageProvider(eventMessage)).value;

    if (fundsRequest == null) {
      return const SizedBox.shrink();
    }

    final networkId = fundsRequest.data.networkId;
    final network = ref.watch(networkByIdProvider(networkId.emptyOrValue)).value;

    final assetId = fundsRequest.data.content.assetId?.emptyOrValue;
    final coin = ref.watch(coinByIdProvider(assetId.emptyOrValue)).value;

    final amount = fundsRequest.data.content.amount?.let(double.parse) ?? 0.0;
    final equivalentUsd = fundsRequest.data.content.amountUsd?.let(double.parse) ?? 0.0;
    final isPaid = fundsRequest.data.transaction != null || fundsRequest.data.transactionId != null;

    return _MoneyMessageContent(
      isMe: isMe,
      margin: margin,
      type: MoneyMessageType.requested,
      amount: amount,
      equivalentUsd: equivalentUsd,
      network: network,
      coin: coin,
      eventMessage: eventMessage,
      eventId: eventReference.eventId,
      button: RequestedMoneyMessageButton(
        isMe: isMe,
        eventId: eventReference.eventId,
        isPaid: isPaid,
        isDeleted: fundsRequest.data.deleted,
        request: fundsRequest,
        eventMessage: eventMessage,
      ),
      onTapReply: onTapReply,
    );
  }
}

class _SentMoneyMessage extends ConsumerWidget {
  const _SentMoneyMessage({
    required this.eventMessage,
    required this.eventReference,
    required this.margin,
    this.onTapReply,
  });

  final EventMessage eventMessage;
  final ImmutableEventReference eventReference;
  final VoidCallback? onTapReply;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventReference.masterPubkey));

    final transactionData = ref.watch(transactionDataForMessageProvider(eventMessage)).value;

    if (transactionData == null) {
      return const SizedBox.shrink();
    }

    final network = transactionData.network;
    final asset = transactionData.cryptoAsset.mapOrNull(coin: (asset) => asset);

    final coin = asset?.coin;

    final amount = asset?.amount ?? 0.0;
    final equivalentUsd = asset?.amountUSD ?? 0.0;

    return _MoneyMessageContent(
      isMe: isMe,
      margin: margin,
      type: MoneyMessageType.sent,
      amount: amount,
      equivalentUsd: equivalentUsd,
      network: network,
      coin: coin,
      eventMessage: eventMessage,
      eventId: eventReference.eventId,
      button: ViewTransactionButton(transactionData: transactionData),
      onTapReply: onTapReply,
    );
  }
}

class _MoneyMessageContent extends HookConsumerWidget {
  const _MoneyMessageContent({
    required this.isMe,
    required this.type,
    required this.amount,
    required this.equivalentUsd,
    required this.network,
    required this.coin,
    required this.eventMessage,
    required this.eventId,
    required this.button,
    required this.margin,
    this.onTapReply,
  });

  final bool isMe;
  final EdgeInsetsDirectional? margin;
  final MoneyMessageType type;
  final double amount;
  final double equivalentUsd;
  final NetworkData? network;
  final CoinData? coin;
  final EventMessage eventMessage;
  final String eventId;
  final Widget button;
  final VoidCallback? onTapReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinGroup = ref.watch(coinGroupByCoinIdProvider(coin?.id)).valueOrNull;

    final textColor = switch (isMe) {
      true => context.theme.appColors.onPrimaryAccent,
      false => context.theme.appColors.primaryText,
    };

    final title = switch ((type, isMe)) {
      (MoneyMessageType.sent, false) => context.i18n.chat_money_received_title,
      (MoneyMessageType.sent, true) => context.i18n.chat_money_sent_title,
      (MoneyMessageType.requested, false) => context.i18n.chat_money_request_title,
      (MoneyMessageType.requested, true) => context.i18n.chat_money_my_request_title,
    };

    final messageItem = ChatMessageInfoItem.money(
      eventMessage: eventMessage,
      contentDescription: title,
    );

    final repliedEventMessage = ref.watch(repliedMessageListItemProvider(messageItem));

    final repliedMessageItem = getRepliedMessageListItem(
      ref: ref,
      repliedEventMessage: repliedEventMessage.valueOrNull,
    );

    return MessageItemWrapper(
      margin: margin,
      messageItem: messageItem,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12.0.s,
        vertical: 12.0.s,
      ),
      isMe: isMe,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (repliedMessageItem != null)
                  ReplyMessage(messageItem, repliedMessageItem, onTapReply),
                Text(
                  title,
                  style: context.theme.appTextThemes.body2.copyWith(color: textColor),
                ),
                SizedBox(height: 10.0.s),
                Row(
                  children: [
                    CoinIconWidget(
                      imageUrl: coinGroup?.iconUrl ?? coin?.iconUrl ?? '',
                      type: WalletItemIconType.big(),
                    ),
                    SizedBox(width: 8.0.s),
                    Expanded(
                      child: _AmountDisplay(
                        amount: amount,
                        equivalentUsd: equivalentUsd,
                        chain: network?.displayName ?? '',
                        coin: coin?.abbreviation,
                        isMe: isMe,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.0.s),
                button,
                MessageReactions(
                  isMe: isMe,
                  eventMessage: eventMessage,
                ),
              ],
            ),
          ),
          MessageMetadata(eventMessage: eventMessage),
        ],
      ),
    );
  }
}
