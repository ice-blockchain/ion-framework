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
    return 'ion_connect:0:e4ae4d68f1f20e804fe87ebaf2e0dfde16b3755bb1328185280d891ef1cffbae:';
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
