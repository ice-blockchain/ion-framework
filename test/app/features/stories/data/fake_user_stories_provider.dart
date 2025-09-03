// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/stories/providers/user_stories_provider.r.dart';

class FakeUserStories extends UserStories {
  FakeUserStories(this._stories);

  final Iterable<ModifiablePostEntity> _stories;

  @override
  Iterable<ModifiablePostEntity> build(String pubkey) => _stories;
}
