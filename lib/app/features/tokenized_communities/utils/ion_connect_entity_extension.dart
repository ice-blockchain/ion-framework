// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/generic_repost.f.dart';
import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_action.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';

extension IsTokenizedCommunityEntityExtension on IonConnectEntity {
  bool get isTokenizedCommunityEntity {
    return this is CommunityTokenActionEntity ||
        this is CommunityTokenDefinitionEntity ||
        (this is GenericRepostEntity &&
            ((this as GenericRepostEntity).data.kind ==
                    GenericRepostEntity.communityTokenDefinitionRepostKind ||
                (this as GenericRepostEntity).data.kind ==
                    GenericRepostEntity.communityTokenActionRepostKind));
  }
}
