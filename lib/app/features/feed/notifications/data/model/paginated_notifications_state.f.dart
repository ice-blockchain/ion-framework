// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';

part 'paginated_notifications_state.f.freezed.dart';

@freezed
class PaginatedNotificationsState with _$PaginatedNotificationsState {
  const factory PaginatedNotificationsState({
    @Default([]) List<IonNotification> notifications,
    DateTime? lastNotificationTime,
    @Default(false) bool hasMore,
    @Default(false) bool isLoading,
    @Default(false) bool isInitialLoading,
  }) = _PaginatedNotificationsState;
}
