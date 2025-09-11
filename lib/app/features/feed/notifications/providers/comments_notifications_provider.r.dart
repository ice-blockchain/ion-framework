// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/feed/notifications/data/repository/comments_repository.r.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_notifications_provider.r.g.dart';

@riverpod
Future<List<CommentIonNotification>> commentsNotifications(Ref ref) async {
  final commentsRepository = ref.watch(commentsRepositoryProvider);
  return commentsRepository.getCommentNotifications();
}
