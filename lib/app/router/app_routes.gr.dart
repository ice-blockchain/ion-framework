// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/pages/discover_creators/discover_creators.dart';
import 'package:ion/app/features/auth/views/pages/fill_profile/fill_profile.dart';
import 'package:ion/app/features/auth/views/pages/get_started/get_started.dart';
import 'package:ion/app/features/auth/views/pages/intro_page/intro_page.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/recover_user_page.dart';
import 'package:ion/app/features/auth/views/pages/recover_user_page/recover_user_success_page.dart';
import 'package:ion/app/features/auth/views/pages/restore_creds/restore_creds.dart';
import 'package:ion/app/features/auth/views/pages/restore_from_cloud/components/restore_from_cloud_no_keys_available_modal.dart';
import 'package:ion/app/features/auth/views/pages/restore_from_cloud/restore_from_cloud_page.dart';
import 'package:ion/app/features/auth/views/pages/restore_menu/restore_menu.dart';
import 'package:ion/app/features/auth/views/pages/select_languages/select_languages.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_early_access/sign_up_early_access.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_passkey/sign_up_passkey.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_password/sign_up_password.dart';
import 'package:ion/app/features/auth/views/pages/sign_up_restricted/sign_up_restricted.dart';
import 'package:ion/app/features/auth/views/pages/turn_on_notifications/turn_on_notifications.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/channel_detail_page/channel_detail_page.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/create_channel_modal/create_channel_modal.dart';
import 'package:ion/app/features/chat/community/channel/views/pages/edit_channel_page/edit_channel_page.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/delete_conversation_modal/delete_conversation_modal.dart';
import 'package:ion/app/features/chat/recent_chats/views/pages/delete_message_modal/delete_message_modal.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/money_message/components/address_not_found_chat_modal.dart';
import 'package:ion/app/features/chat/views/pages/chat_add_poll_modal/chat_add_poll_modal.dart';
import 'package:ion/app/features/chat/views/pages/chat_learn_more_modal/chat_learn_more_modal.dart';
import 'package:ion/app/features/chat/views/pages/chat_main_modal/chat_main_modal_page.dart';
import 'package:ion/app/features/chat/views/pages/chat_main_page/arhived_chats_main_page.dart';
import 'package:ion/app/features/chat/views/pages/chat_main_page/chat_main_page.dart';
import 'package:ion/app/features/chat/views/pages/chat_media_page/chat_media_page.dart';
import 'package:ion/app/features/chat/views/pages/conversation_page/conversation_page.dart';
import 'package:ion/app/features/chat/views/pages/new_chat_modal/new_chat_modal.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/pages/add_group_participants_modal.dart';
import 'package:ion/app/features/chat/views/pages/new_group_modal/pages/create_group_modal.dart';
import 'package:ion/app/features/chat/views/pages/send_profile_modal/send_profile_modal.dart';
import 'package:ion/app/features/chat/views/pages/share_via_message_modal/share_via_message_modal.dart';
import 'package:ion/app/features/core/views/pages/app_test_page/app_test_page.dart';
import 'package:ion/app/features/core/views/pages/error_page.dart';
import 'package:ion/app/features/core/views/pages/search_emoji_modal/search_emoji_modal.dart';
import 'package:ion/app/features/core/views/pages/splash_page.dart';
import 'package:ion/app/features/dapps/views/pages/dapp_details/dapp_details_modal.dart';
import 'package:ion/app/features/dapps/views/pages/dapps.dart';
import 'package:ion/app/features/dapps/views/pages/dapps_list/dapps_list.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_form_modal/article_form_modal.dart';
import 'package:ion/app/features/feed/create_article/views/pages/article_preview_modal/article_preview_modal.dart';
import 'package:ion/app/features/feed/create_post/views/pages/compress_test_page.f.dart';
import 'package:ion/app/features/feed/create_post/views/pages/post_form_modal/post_form_modal.dart';
import 'package:ion/app/features/feed/data/models/feed_type.dart';
import 'package:ion/app/features/feed/notifications/views/notifications_history_page/notifications_history_page.dart';
import 'package:ion/app/features/feed/stories/views/pages/story_preview_page.dart';
import 'package:ion/app/features/feed/stories/views/pages/story_record_page.dart';
import 'package:ion/app/features/feed/stories/views/pages/story_viewer_page.dart';
import 'package:ion/app/features/feed/views/pages/add_bookmark_modal/add_bookmark_modal.dart';
import 'package:ion/app/features/feed/views/pages/article_details_page/article_details_page.dart';
import 'package:ion/app/features/feed/views/pages/article_replies_page/article_replies_page.dart';
import 'package:ion/app/features/feed/views/pages/articles_from_author_page/articles_from_author_page.dart';
import 'package:ion/app/features/feed/views/pages/articles_from_topic_page/articles_from_topic_page.dart';
import 'package:ion/app/features/feed/views/pages/boost_post_modal/boost_post_modal.dart';
import 'package:ion/app/features/feed/views/pages/content_creation_blocked_page/content_creation_blocked_modal_page.dart';
import 'package:ion/app/features/feed/views/pages/entity_language_modal/entity_language_modal.dart';
import 'package:ion/app/features/feed/views/pages/entity_language_modal/entity_language_warning_modal.dart';
import 'package:ion/app/features/feed/views/pages/feed_article_categories/feed_visible_article_categories_modal.dart';
import 'package:ion/app/features/feed/views/pages/feed_main_modal/feed_main_modal_page.dart';
import 'package:ion/app/features/feed/views/pages/feed_page/feed_page.dart';
import 'package:ion/app/features/feed/views/pages/fullscreen_media/fullscreen_media_page.dart';
import 'package:ion/app/features/feed/views/pages/invite_friends_page/invite_friends_page.dart';
import 'package:ion/app/features/feed/views/pages/post_details_page/post_details_page.dart';
import 'package:ion/app/features/feed/views/pages/repost_options_modal/repost_options_modal.dart';
import 'package:ion/app/features/feed/views/pages/topics_modal/select_topics_modal.dart';
import 'package:ion/app/features/gallery/views/pages/album_selection_page.dart';
import 'package:ion/app/features/gallery/views/pages/gallery_camera_page.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_page.dart';
import 'package:ion/app/features/gallery/views/pages/media_picker_type.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/device_keypair_dialog_state.f.dart';
import 'package:ion/app/features/ion_connect/views/components/device_keypair_dialog.dart';
import 'package:ion/app/features/protect_account/authenticator/views/pages/delete_authenticator/authenticator_delete_page.dart';
import 'package:ion/app/features/protect_account/authenticator/views/pages/delete_authenticator/authenticator_delete_success.dart';
import 'package:ion/app/features/protect_account/authenticator/views/pages/setup_authenticator/step_pages.dart';
import 'package:ion/app/features/protect_account/backup/views/components/errors/secure_account_error_alert.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/backup_options_page.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/backup_recovery_keys_modal.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/backup_with_cloud_page/backup_with_cloud_page.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/backup_with_cloud_page/backup_with_cloud_success_page.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/backup_with_cloud_page/components/cloud_disabled_modal.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/create_recover_key_page/create_recovery_key_page.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/recovery_keys_success_page.dart';
import 'package:ion/app/features/protect_account/backup/views/pages/validate_recovery_key_page.dart';
import 'package:ion/app/features/protect_account/email/data/model/email_steps.dart';
import 'package:ion/app/features/protect_account/email/views/pages/delete_email/email_delete_page.dart';
import 'package:ion/app/features/protect_account/email/views/pages/edit_email/email_edit_page.dart';
import 'package:ion/app/features/protect_account/email/views/pages/setup_email/email_setup_page.dart';
import 'package:ion/app/features/protect_account/phone/models/phone_steps.dart';
import 'package:ion/app/features/protect_account/phone/views/components/countries/select_country_page.dart';
import 'package:ion/app/features/protect_account/phone/views/pages/delete_phone/phone_delete_page.dart';
import 'package:ion/app/features/protect_account/phone/views/pages/edit_phone/phone_edit_page.dart';
import 'package:ion/app/features/protect_account/phone/views/pages/setup_phone/phone_setup_page.dart';
import 'package:ion/app/features/protect_account/secure_account/views/pages/secure_account_modal.dart';
import 'package:ion/app/features/protect_account/secure_account/views/pages/secure_account_options_page.dart';
import 'package:ion/app/features/search/model/advanced_search_category.dart';
import 'package:ion/app/features/search/views/pages/chat/chat_advanced_search_page/chat_advanced_search_page.dart';
import 'package:ion/app/features/search/views/pages/chat/chat_quick_search_page/chat_quick_search_page.dart';
import 'package:ion/app/features/search/views/pages/dapps_simple_search_page/dapps_simple_search_page.dart';
import 'package:ion/app/features/search/views/pages/feed_advanced_search_page/feed_advanced_search_page.dart';
import 'package:ion/app/features/search/views/pages/feed_search_filters_page/feed_search_filters_page.dart';
import 'package:ion/app/features/search/views/pages/feed_simple_search_page/feed_simple_search_page.dart';
import 'package:ion/app/features/settings/views/account_settings_modal.dart';
import 'package:ion/app/features/settings/views/app_language_modal.dart';
import 'package:ion/app/features/settings/views/blocked_users_modal.dart';
import 'package:ion/app/features/settings/views/content_language_modal.dart';
import 'package:ion/app/features/settings/views/delegate_access_modal.dart';
import 'package:ion/app/features/settings/views/delegate_user_selected_modal.dart';
import 'package:ion/app/features/settings/views/logout_confirm_modal.dart';
import 'package:ion/app/features/settings/views/privacy_settings_modal.dart';
import 'package:ion/app/features/settings/views/push_notifications_settings.dart';
import 'package:ion/app/features/settings/views/select_delegate_user_modal.dart';
import 'package:ion/app/features/settings/views/settings_modal.dart';
import 'package:ion/app/features/settings/views/switch_user_account_modal.dart';
import 'package:ion/app/features/user/model/follow_type.dart';
import 'package:ion/app/features/user/model/payment_type.dart';
import 'package:ion/app/features/user/model/tab_entity_type.dart';
import 'package:ion/app/features/user/pages/avatar_overlay_page/avatar_overlay_page.dart';
import 'package:ion/app/features/user/pages/bookmarks_page/bookmarks_page.dart';
import 'package:ion/app/features/user/pages/creator_tokens/views/creator_tokens_page/creator_tokens_page.dart';
import 'package:ion/app/features/user/pages/edit_bookmarks_page/edit_bookmarks_page.dart';
import 'package:ion/app/features/user/pages/profile_edit_page/pages/category_select_modal/category_select_modal.dart';
import 'package:ion/app/features/user/pages/profile_edit_page/profile_edit_page.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/follow_list_modal/follow_list_modal.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/payment_selection_modal/payment_selection_modal.dart';
import 'package:ion/app/features/user/pages/profile_page/pages/request_coins_form_modal/request_coins_form_modal.dart';
import 'package:ion/app/features/user/pages/profile_page/profile_page.dart';
import 'package:ion/app/features/user/pages/profile_page/self_profile_page.dart';
import 'package:ion/app/features/user/pages/switch_account_modal/switch_account_modal.dart';
import 'package:ion/app/features/video/views/pages/feed_advanced_search_videos_page.dart';
import 'package:ion/app/features/video/views/pages/feed_videos_page.dart';
import 'package:ion/app/features/video/views/pages/profile_videos_page.dart';
import 'package:ion/app/features/video/views/pages/reply_list_videos_page.dart';
import 'package:ion/app/features/video/views/pages/trending_videos_page.dart';
import 'package:ion/app/features/wallets/model/crypto_asset_type.dart';
import 'package:ion/app/features/wallets/views/pages/address_not_found_wallet_modal.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_details/coin_details_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/coin_receive_modal/coin_receive_modal.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/contact_picker/contact_picker_modal.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/network_list/network_list_view.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/components/share_address_view.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/receive_coins/receive_coin_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/request_coins/request_coins_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/confirmation/confirmation_sheet.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/confirmation/transaction_result_sheet.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/components/send_coins_form.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/send_coins/send_coin_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/swap_coins_confirmation_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/swap_coins_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/coins_flow/swap_coins/swap_select_coin_page.dart';
import 'package:ion/app/features/wallets/views/pages/contact_modal_page/contact_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/create_new_wallet_modal.dart';
import 'package:ion/app/features/wallets/views/pages/delete_wallet_modal.dart';
import 'package:ion/app/features/wallets/views/pages/edit_wallet_modal.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/components/select_network_list.dart';
import 'package:ion/app/features/wallets/views/pages/import_token_page/import_token_page.dart';
import 'package:ion/app/features/wallets/views/pages/manage_coins/manage_coins_page.dart';
import 'package:ion/app/features/wallets/views/pages/manage_nfts/manage_nfts_page.dart';
import 'package:ion/app/features/wallets/views/pages/manage_wallets_modal.dart';
import 'package:ion/app/features/wallets/views/pages/nft_details/nft_details_page.dart';
import 'package:ion/app/features/wallets/views/pages/receive_nft/components/share_address_view.dart';
import 'package:ion/app/features/wallets/views/pages/receive_nft/select_nft_network_page.dart';
import 'package:ion/app/features/wallets/views/pages/send_nft_confirm.dart';
import 'package:ion/app/features/wallets/views/pages/send_nft_form.dart';
import 'package:ion/app/features/wallets/views/pages/share_token_creator/share_token_creator_page.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/explore_transaction_details_modal.dart';
import 'package:ion/app/features/wallets/views/pages/transaction_details/transaction_details.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_main_modal/wallet_main_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_page.dart';
import 'package:ion/app/features/wallets/views/pages/wallet_scan_modal_page.dart';
import 'package:ion/app/features/wallets/views/pages/wallets_modal.dart';
import 'package:ion/app/router/base_route_data.dart';
import 'package:ion/app/router/components/modal_wrapper/modal_wrapper.dart';
import 'package:ion/app/router/main_tabs/main_tab_navigation.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

part 'app_routes.gr.g.dart';
part 'auth_routes.dart';
part 'chat_routes.dart';
part 'dapps_routes.dart';
part 'feed_routes.dart';
part 'media_picker_routes.dart';
part 'profile_routes.dart';
part 'protect_account_routes.dart';
part 'settings_routes.dart';
part 'wallet_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final bottomBarNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tabNav');

@TypedStatefulShellRoute<AppShellRouteData>(
  branches: [
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<FeedRoute>(
          path: '/feed',
          routes: [
            ...FeedRoutes.routes,
            TypedGoRoute<FeedMainModalRoute>(path: 'main-modal'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<ChatRoute>(
          path: '/chat',
          routes: [
            ...ChatRoutes.routes,
            TypedGoRoute<ChatMainModalRoute>(path: 'main-modal'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<WalletRoute>(
          path: '/wallet',
          routes: [
            ...WalletRoutes.routes,
            TypedGoRoute<WalletMainModalRoute>(path: 'main-modal'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch(
      routes: [
        TypedGoRoute<SelfProfileRoute>(
          path: '/profile',
          routes: [
            ...ProfileRoutes.routes,
            TypedGoRoute<ProfileMainModalRoute>(path: 'main-modal'),
          ],
        ),
      ],
    ),
  ],
)
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  static final $navigatorKey = bottomBarNavigatorKey;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return MainTabNavigation(
      key: state.pageKey,
      shell: navigationShell,
      state: state,
    );
  }
}

class ModalShellRouteData extends ShellRouteData {
  const ModalShellRouteData();

  static final $parentNavigatorKey = rootNavigatorKey;

  @override
  Page<void> pageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget navigator,
  ) {
    return ModalSheetPage(
      key: state.pageKey,
      child: ModalWrapper(child: navigator),
      barrierColor: context.theme.appColors.backgroundSheet,
      transitionCurve: Easing.standardDecelerate,
      swipeDismissible: true,
      swipeDismissSensitivity: SwipeDismissSensitivity(
        minFlingVelocityRatio: 3,
        minDragDistance: 300.0.s,
      ),
    );
  }
}

@TypedGoRoute<SplashRoute>(path: '/splash')
class SplashRoute extends BaseRouteData with _$SplashRoute {
  SplashRoute()
      : super(
          child: const SplashPage(),
        );
}

class FeedRoute extends BaseRouteData with _$FeedRoute {
  FeedRoute() : super(child: const FeedPage());
}

class ChatRoute extends BaseRouteData with _$ChatRoute {
  ChatRoute() : super(child: const ChatMainPage());
}

class WalletRoute extends BaseRouteData with _$WalletRoute {
  WalletRoute() : super(child: const WalletPage());
}

class SelfProfileRoute extends BaseRouteData with _$SelfProfileRoute {
  SelfProfileRoute() : super(child: const SelfProfilePage());
}

@TypedGoRoute<ErrorRoute>(path: '/error')
class ErrorRoute extends BaseRouteData with _$ErrorRoute {
  ErrorRoute({this.message})
      : super(
          child: ErrorPage(message: message),
        );

  final String? message;
}

@TypedGoRoute<IntroRoute>(
  path: '/intro',
  routes: [...AuthRoutes.routes],
)
class IntroRoute extends BaseRouteData with _$IntroRoute {
  IntroRoute() : super(child: const IntroPage(), type: IceRouteType.singleWithoutTransition);
}

class FeedMainModalRoute extends BaseRouteData with _$FeedMainModalRoute {
  FeedMainModalRoute()
      : super(
          child: const FeedMainModalPage(),
          type: IceRouteType.mainModalSheet,
        );
}

class ProfileMainModalRoute extends BaseRouteData with _$ProfileMainModalRoute {
  ProfileMainModalRoute()
      : super(
          child: const FeedMainModalPage(),
          type: IceRouteType.mainModalSheet,
        );
}

class ChatMainModalRoute extends BaseRouteData with _$ChatMainModalRoute {
  ChatMainModalRoute()
      : super(
          child: const ChatMainModalPage(),
          type: IceRouteType.mainModalSheet,
        );
}

class WalletMainModalRoute extends BaseRouteData with _$WalletMainModalRoute {
  WalletMainModalRoute()
      : super(
          child: const WalletMainModalPage(),
          type: IceRouteType.mainModalSheet,
        );
}

@TypedGoRoute<AvatarOverlayRoute>(path: '/avatar-overlay/:pubkey')
class AvatarOverlayRoute extends BaseRouteData with _$AvatarOverlayRoute {
  AvatarOverlayRoute({
    required this.pubkey,
  }) : super(
          child: AvatarOverlayPage(pubkey: pubkey),
          type: IceRouteType.overlay,
        );

  final String pubkey;
}

@TypedGoRoute<CompressTestRoute>(path: '/compress-test')
class CompressTestRoute extends BaseRouteData with _$CompressTestRoute {
  CompressTestRoute() : super(child: const CompressTestPage());
}
