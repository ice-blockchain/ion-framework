// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/global_notification_bar/providers/global_notification_notifier_provider.r.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/core/views/pages/error_modal.dart';
import 'package:ion/app/features/feed/create_article/providers/create_article_provider.r.dart';
import 'package:ion/app/features/feed/create_post/model/create_post_option.dart';
import 'package:ion/app/features/feed/create_post/providers/create_post_notifier.m.dart';
import 'package:ion/app/features/feed/global_notifications/models/feed_global_notification.f.dart';
import 'package:ion/app/features/feed/providers/repost_notifier.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';

void setupFeedGlobalNotificationsListeners(WidgetRef ref) {
  ref
    ..listen(createPostNotifierProvider(CreatePostOption.plain), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.post);
    })
    ..listen(createPostNotifierProvider(CreatePostOption.quote), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.post);
    })
    ..listen(createPostNotifierProvider(CreatePostOption.reply), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.reply);
    })
    ..listen(createPostNotifierProvider(CreatePostOption.video), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.video);
    })
    ..listen(createPostNotifierProvider(CreatePostOption.story), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.story);
    })
    ..listen(createPostNotifierProvider(CreatePostOption.modify), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.modify);
    })
    ..listen(createPostNotifierProvider(CreatePostOption.softDelete), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.delete);
    })
    ..listen(createArticleProvider(CreateArticleOption.plain), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.article);
    })
    ..listen(createArticleProvider(CreateArticleOption.softDelete), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.delete);
    })
    ..listen(createArticleProvider(CreateArticleOption.modify), (_, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.modify);
    })
    ..listen(repostNotifierProvider, (previous, next) {
      _handleNotification(ref, state: next, type: FeedNotificationContentType.repost);
    });
}

void _handleNotification(
  WidgetRef ref, {
  required AsyncValue<void> state,
  required FeedNotificationContentType type,
}) {
  final isAuthenticated = ref.read(
        authProvider.select((state) => state.valueOrNull?.isAuthenticated),
      ) ??
      false;
  if (!isAuthenticated) {
    return;
  }

  final loadingNotificationKey = type;

  if (state.isLoading) {
    ref
        .read(globalNotificationNotifierProvider.notifier)
        .show(type.loading(), isPermanent: true, key: loadingNotificationKey);
  } else if (state.hasError && state.error != null) {
    ref.read(globalNotificationNotifierProvider.notifier).hide(key: loadingNotificationKey);
    showErrorModal(rootNavigatorKey.currentContext!, state.error!);
  } else if (state.hasValue) {
    ref.read(globalNotificationNotifierProvider.notifier).hide(key: loadingNotificationKey);

    ref.read(globalNotificationNotifierProvider.notifier).show(type.ready());
  }
}
