import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

///
/// TODO(ice-kreios): finalize external address prefixes.
/// Current values ('a', 'b', etc.) are temporary placeholders.
///
extension ExternalAddressExtension on ReplaceableEntity {
  String get externalAddress {
    return 'ion_connect:0:2e4cccd551746c503d7877b72ebb982927c91e91f8a977ed561e276fb9ae0301:';
    final String prefix;

    if (data is UserMetadata) {
      prefix = 'a';
      return toEventReference().toString();
    } else if (data is ModifiablePostData) {
      final post = data as ModifiablePostData;
      if (post.hasVideo) {
        prefix = 'b';
      } else {
        prefix = 'c';
      }
    } else if (data is ArticleEntity) {
      prefix = 'd';
    } else {
      throw Exception('Unsupported data type');
    }
    return '$prefix:${toEventReference()}';
  }
}
