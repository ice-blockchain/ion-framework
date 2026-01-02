// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/notifications/data/model/ion_notification.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

abstract class IonNotificationRepository<N extends IonNotification> {
  Future<void> save(IonConnectEntity entity);
}
