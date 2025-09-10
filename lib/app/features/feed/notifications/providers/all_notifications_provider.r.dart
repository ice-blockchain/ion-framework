// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/comments_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/content_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/followers_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/likes_repository.r.dart';
import 'package:ion/app/features/feed/notifications/data/repository/mentions_repository.r.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'all_notifications_provider.r.g.dart';

@riverpod
Future<List<IonNotification>> allNotifications(Ref ref) async {
  final commentsRepository = ref.watch(commentsRepositoryProvider);
  final contentRepository = ref.watch(contentRepositoryProvider);
  final followersRepository = ref.watch(followersRepositoryProvider);
  final likesRepository = ref.watch(likesRepositoryProvider);
  final mentionsRepository = ref.watch(mentionsRepositoryProvider);
  final (comments, content, likes, followers, mentions) = await (
    commentsRepository.getNotifications(),
    contentRepository.getNotifications(),
    likesRepository.getNotifications(),
    followersRepository.getNotifications(),
    mentionsRepository.getNotifications()
  ).wait;
  return [...comments, ...content, ...likes, ...followers, ...mentions]
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}
