// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/optimistic_ui/core/optimistic_intent.dart';
import 'package:ion/app/features/optimistic_ui/features/bookmark/model/bookmark.f.dart';

final class ToggleBookmarkIntent implements OptimisticIntent<Bookmark> {
  @override
  Bookmark optimistic(Bookmark current) => current.copyWith(bookmarked: !current.bookmarked);

  @override
  Future<Bookmark> sync(Bookmark prev, Bookmark next) =>
      throw UnimplementedError('Sync is handled by the bookmark sync strategy');
}
