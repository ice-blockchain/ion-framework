// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/entity_published_at.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/ion_connect/model/quoted_event.f.dart';

mixin SoftDeletableEntity<T extends SoftDeletableEntityData> on IonConnectEntity {
  T get data;

  bool get isDeleted {
    return data.content.isEmpty && createdAt != data.publishedAt.value && data.quotedEvent == null;
  }
}

mixin SoftDeletableEntityData {
  String get content;
  EntityPublishedAt get publishedAt;
  QuotedEvent? get quotedEvent;
}
