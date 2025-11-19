// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class ChatRoutes {
  static const shareRoutePrefix = 'share';

  static const routes = <TypedRoute<RouteData>>[
    TypedGoRoute<AppTestRoute>(path: 'app-test'),
    TypedGoRoute<ChatQuickSearchRoute>(path: 'chat-simple-search'),
    TypedGoRoute<ChatAdvancedSearchRoute>(path: 'chat-advanced-search'),
    TypedGoRoute<ArchivedChatsMainRoute>(path: 'archived-chats'),
    TypedGoRoute<ConversationRoute>(
      path: 'conversation-fullstack',
      routes: [
        TypedGoRoute<ChannelDetailRoute>(path: 'channel-detail'),
        TypedGoRoute<EditChannelRoute>(path: 'edit-channel'),
      ],
    ),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<DeleteConversationRoute>(path: 'delete-conversation'),
        TypedGoRoute<DeleteMessageRoute>(path: 'delete-message'),
        TypedGoRoute<NewChatModalRoute>(path: 'new-chat'),
        TypedGoRoute<NewChannelModalRoute>(path: 'new-channel'),
        TypedGoRoute<ChatLearnMoreModalRoute>(path: 'learn-more'),
        TypedGoRoute<SendProfileModalRoute>(path: 'send-profile'),
        TypedGoRoute<ChatAddPollModalRoute>(path: 'add-poll'),
        TypedGoRoute<SearchEmojiRoute>(path: 'search-emoji'),
        TypedGoRoute<AddParticipantsToGroupModalRoute>(path: 'add-participants-to-group'),
        TypedGoRoute<CreateGroupModalRoute>(path: 'create-group'),
        TypedGoRoute<ShareViaMessageModalRoute>(path: '$shareRoutePrefix/:eventReference'),
        TypedGoRoute<PaymentSelectionChatRoute>(path: 'select-payment-type'),
        TypedGoRoute<SelectCoinChatRoute>(path: 'coin-selector-chat'),
        TypedGoRoute<SelectNetworkChatRoute>(path: 'network-selector-chat'),
        TypedGoRoute<SendCoinsFormChatRoute>(path: 'send-coins-form-chat'),
        TypedGoRoute<SelectContactChatRoute>(path: 'select-contact-chat'),
        TypedGoRoute<CoinSendScanChatRoute>(path: 'scan-receiver-wallet-chat'),
        TypedGoRoute<SendCoinsConfirmationChatRoute>(path: 'send-form-confirmation-chat'),
        TypedGoRoute<CoinTransactionResultChatRoute>(path: 'coin-transaction-result-chat'),
        TypedGoRoute<CoinTransactionDetailsChatRoute>(path: 'coin-transaction-details-chat'),
        TypedGoRoute<ExploreTransactionDetailsChatRoute>(path: 'coin-transaction-explore-chat'),
        TypedGoRoute<RequestCoinsFormChatRoute>(path: 'request-coins-form-chat'),
        TypedGoRoute<AddressNotFoundChatRoute>(path: 'address-not-found'),
        TypedGoRoute<DeviceKeypairDialogRoute>(path: 'device-keypair-dialog'),
      ],
    ),
  ];
}

class ConversationRoute extends BaseRouteData with _$ConversationRoute {
  ConversationRoute({
    this.conversationId,
    this.receiverMasterPubkey,
  }) : super(
          child: ConversationPage(
            conversationId: conversationId,
            receiverMasterPubkey: receiverMasterPubkey,
          ),
          canPop: true,
        );

  final String? conversationId;
  final String? receiverMasterPubkey;
}

class ChannelDetailRoute extends BaseRouteData with _$ChannelDetailRoute {
  ChannelDetailRoute({required this.uuid})
      : super(
          child: ChannelDetailPage(uuid: uuid),
        );

  final String uuid;
}

class EditChannelRoute extends BaseRouteData with _$EditChannelRoute {
  EditChannelRoute({required this.uuid})
      : super(
          child: EditChannelPage(uuid: uuid),
        );

  final String uuid;
}

class AppTestRoute extends BaseRouteData with _$AppTestRoute {
  AppTestRoute() : super(child: const AppTestPage());
}

class ChatQuickSearchRoute extends BaseRouteData with _$ChatQuickSearchRoute {
  ChatQuickSearchRoute({this.query = ''})
      : super(
          child: ChatQuickSearchPage(query: query),
        );

  final String query;
}

class ChatAdvancedSearchRoute extends BaseRouteData with _$ChatAdvancedSearchRoute {
  ChatAdvancedSearchRoute({required this.query})
      : super(
          child: ChatAdvancedSearchPage(query: query),
        );

  final String query;
}

class ArchivedChatsMainRoute extends BaseRouteData with _$ArchivedChatsMainRoute {
  ArchivedChatsMainRoute()
      : super(
          child: const ArchivedChatsMainPage(),
          type: IceRouteType.slideFromLeft,
        );
}

class DeleteConversationRoute extends BaseRouteData with _$DeleteConversationRoute {
  DeleteConversationRoute({required this.conversationIds})
      : super(
          child: DeleteConversationModal(conversationIds: conversationIds),
          type: IceRouteType.bottomSheet,
        );

  final List<String> conversationIds;
}

class DeleteMessageRoute extends BaseRouteData with _$DeleteMessageRoute {
  DeleteMessageRoute({required this.isMe})
      : super(
          child: DeleteMessageModal(isMe: isMe),
          type: IceRouteType.bottomSheet,
        );

  final bool isMe;
}

class NewChatModalRoute extends BaseRouteData with _$NewChatModalRoute {
  NewChatModalRoute()
      : super(
          child: const NewChatModal(),
          type: IceRouteType.bottomSheet,
        );
}

class NewChannelModalRoute extends BaseRouteData with _$NewChannelModalRoute {
  NewChannelModalRoute()
      : super(
          child: const CreateChannelModal(),
          type: IceRouteType.bottomSheet,
        );
}

class ChatLearnMoreModalRoute extends BaseRouteData with _$ChatLearnMoreModalRoute {
  ChatLearnMoreModalRoute()
      : super(
          child: const ChatLearnMoreModal(),
          type: IceRouteType.bottomSheet,
        );
}

class SendProfileModalRoute extends BaseRouteData with _$SendProfileModalRoute {
  SendProfileModalRoute()
      : super(
          child: const SendProfileModal(),
          type: IceRouteType.bottomSheet,
        );
}

class ChatAddPollModalRoute extends BaseRouteData with _$ChatAddPollModalRoute {
  ChatAddPollModalRoute()
      : super(
          child: const ChatAddPollModal(),
          type: IceRouteType.bottomSheet,
        );
}

class AddParticipantsToGroupModalRoute extends BaseRouteData
    with _$AddParticipantsToGroupModalRoute {
  AddParticipantsToGroupModalRoute()
      : super(
          child: const AddGroupParticipantsModal(),
          type: IceRouteType.bottomSheet,
        );
}

class CreateGroupModalRoute extends BaseRouteData with _$CreateGroupModalRoute {
  CreateGroupModalRoute()
      : super(
          child: const CreateGroupModal(),
          type: IceRouteType.bottomSheet,
        );
}

class SearchEmojiRoute extends BaseRouteData with _$SearchEmojiRoute {
  SearchEmojiRoute()
      : super(
          child: const SearchEmojiModal(),
          type: IceRouteType.bottomSheet,
        );
}

class ShareViaMessageModalRoute extends BaseRouteData with _$ShareViaMessageModalRoute {
  ShareViaMessageModalRoute({required this.eventReference})
      : super(
          child: ShareViaMessageModal(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
          type: IceRouteType.bottomSheet,
        );

  final String eventReference;
}

class PaymentSelectionChatRoute extends BaseRouteData with _$PaymentSelectionChatRoute {
  PaymentSelectionChatRoute({
    required this.pubkey,
  }) : super(
          child: PaymentSelectionModal(
            pubkey: pubkey,
            selectCoinRouteLocationBuilder: (paymentType) =>
                SelectCoinChatRoute(paymentType: paymentType).location,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String pubkey;
}

class SelectCoinChatRoute extends BaseRouteData with _$SelectCoinChatRoute {
  SelectCoinChatRoute({required this.paymentType})
      : super(
          child: switch (paymentType) {
            PaymentType.send => SendCoinModalPage(
                selectNetworkRouteLocationBuilder: () =>
                    SelectNetworkChatRoute(paymentType: paymentType).location,
              ),
            PaymentType.request => RequestCoinsModalPage(
                selectNetworkLocationRouteBuilder: (paymentType) =>
                    SelectNetworkChatRoute(paymentType: paymentType).location,
              ),
          },
          type: IceRouteType.bottomSheet,
        );

  final PaymentType paymentType;
}

class SelectNetworkChatRoute extends BaseRouteData with _$SelectNetworkChatRoute {
  SelectNetworkChatRoute({required this.paymentType})
      : super(
          child: NetworkListView(
            type: switch (paymentType) {
              PaymentType.send => NetworkListViewType.send,
              PaymentType.request => NetworkListViewType.request,
            },
            sendFormRouteLocationBuilder: () => switch (paymentType) {
              PaymentType.send => SendCoinsFormChatRoute().location,
              PaymentType.request => RequestCoinsFormChatRoute().location,
            },
          ),
          type: IceRouteType.bottomSheet,
        );

  final PaymentType paymentType;
}

class AddressNotFoundChatRoute extends BaseRouteData with _$AddressNotFoundChatRoute {
  AddressNotFoundChatRoute()
      : super(
          child: AddressNotFoundChatModal(
            onWalletCreated: (context) => RequestCoinsFormChatRoute().replace(context),
          ),
          type: IceRouteType.bottomSheet,
        );
}

class CoinSendScanChatRoute extends BaseRouteData with _$CoinSendScanChatRoute {
  CoinSendScanChatRoute()
      : super(
          child: const WalletScanModalPage(),
          type: IceRouteType.bottomSheet,
        );
}

class SendCoinsFormChatRoute extends BaseRouteData with _$SendCoinsFormChatRoute {
  SendCoinsFormChatRoute()
      : super(
          child: SendCoinsForm(
            selectCoinRouteLocationBuilder: () =>
                SelectCoinChatRoute(paymentType: PaymentType.send).location,
            selectNetworkRouteLocationBuilder: () =>
                SelectNetworkChatRoute(paymentType: PaymentType.send).location,
            selectContactRouteLocationBuilder: (networkId) =>
                SelectContactChatRoute(networkId: networkId).location,
            scanAddressRouteLocationBuilder: () => CoinSendScanChatRoute().location,
            confirmRouteLocationBuilder: () => SendCoinsConfirmationChatRoute().location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class SelectContactChatRoute extends BaseRouteData with _$SelectContactChatRoute {
  SelectContactChatRoute({required this.networkId})
      : super(
          child: ContactPickerModal(
            networkId: networkId,
            validatorType: ContactPickerValidatorType.networkWallet,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String networkId;
}

class SendCoinsConfirmationChatRoute extends BaseRouteData with _$SendCoinsConfirmationChatRoute {
  SendCoinsConfirmationChatRoute()
      : super(
          child: ConfirmationSheet(
            successRouteLocationBuilder: (walletViewId, txHash) =>
                CoinTransactionResultChatRoute(walletViewId: walletViewId, txHash: txHash).location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

class CoinTransactionResultChatRoute extends BaseRouteData with _$CoinTransactionResultChatRoute {
  CoinTransactionResultChatRoute({
    required this.walletViewId,
    required this.txHash,
  }) : super(
          child: TransactionResultSheet(
            walletViewId: walletViewId,
            txHash: txHash,
            transactionDetailsRouteLocationBuilder: (walletViewId, txHash) =>
                CoinTransactionDetailsChatRoute(walletViewId: walletViewId, txHash: txHash)
                    .location,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String walletViewId;
  final String txHash;
}

class CoinTransactionDetailsChatRoute extends BaseRouteData with _$CoinTransactionDetailsChatRoute {
  CoinTransactionDetailsChatRoute({
    required this.walletViewId,
    required this.txHash,
  }) : super(
          child: TransactionDetailsPage(
            walletViewId: walletViewId,
            txHash: txHash,
            exploreRouteLocationBuilder: (url) =>
                ExploreTransactionDetailsChatRoute(url: url).location,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String walletViewId;
  final String txHash;
}

class ExploreTransactionDetailsChatRoute extends BaseRouteData
    with _$ExploreTransactionDetailsChatRoute {
  ExploreTransactionDetailsChatRoute({required this.url})
      : super(
          child: ExploreTransactionDetailsModal(url: url),
          type: IceRouteType.bottomSheet,
        );

  final String url;
}

class RequestCoinsFormChatRoute extends BaseRouteData with _$RequestCoinsFormChatRoute {
  RequestCoinsFormChatRoute()
      : super(
          child: RequestCoinsFormModal(
            addressNotFoundRouteLocationBuilder: () => AddressNotFoundChatRoute().location,
          ),
          type: IceRouteType.bottomSheet,
        );
}

@TypedGoRoute<ChatMediaRoute>(path: '/chat-media/:eventReference/:initialIndex')
class ChatMediaRoute extends BaseRouteData with _$ChatMediaRoute {
  ChatMediaRoute({
    required this.eventReference,
    required this.initialIndex,
  }) : super(
          child: ChatMediaPage(
            eventReference: EventReference.fromEncoded(eventReference),
            initialIndex: initialIndex,
          ),
          type: IceRouteType.swipeDismissible,
          isFullscreenMedia: true,
        );

  final String eventReference;
  final int initialIndex;
}

class DeviceKeypairDialogRoute extends BaseRouteData with _$DeviceKeypairDialogRoute {
  DeviceKeypairDialogRoute({required this.state})
      : super(
          child: DeviceKeypairDialog(state: state),
          type: IceRouteType.bottomSheet,
        );

  final DeviceKeypairState state;
}
