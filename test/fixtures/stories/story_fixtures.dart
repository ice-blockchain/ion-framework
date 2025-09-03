// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/core/model/media_type.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';

import '../posts/post_fixtures.dart';

class StoryFixtures {
  StoryFixtures._();

  static const alice = 'alice';
  static const bob = 'bob';
  static const charlie = 'charlie';

  static ModifiablePostEntity userStory({
    String pubkey = alice,
    MediaType mediaType = MediaType.image,
  }) {
    return buildPost('single_story', author: pubkey, mediaType: mediaType);
  }

  static List<ModifiablePostEntity> stories({
    String pubkey = alice,
    int count = 3,
    MediaType mediaType = MediaType.image,
  }) {
    return List.generate(
      count,
      (i) => buildPost('${pubkey}_story_$i', author: pubkey, mediaType: mediaType),
    );
  }
}
