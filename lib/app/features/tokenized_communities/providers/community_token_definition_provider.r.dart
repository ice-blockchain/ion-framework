// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/action_source.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_notifier.r.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/constants.dart';
import 'package:ion/app/services/ion_token_analytics/ion_token_analytics_client_provider.r.dart';
import 'package:ion_token_analytics/ion_token_analytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'community_token_definition_provider.r.g.dart';

class CommunityTokenDefinitionRepository {
  CommunityTokenDefinitionRepository({
    required IonConnectNotifier ionConnectNotifier,
    required IonTokenAnalyticsClient analyticsClient,
  })  : _ionConnectNotifier = ionConnectNotifier,
        _analyticsClient = analyticsClient;

  final IonConnectNotifier _ionConnectNotifier;

  final IonTokenAnalyticsClient _analyticsClient;

  Future<CommunityTokenDefinitionEntity?> getTokenDefinition({
    required String externalAddress,
  }) async {
    //TODO: add cache (define cacheKey for CommunityTokenDefinitionEntity)

    final tokenInfo = await _analyticsClient.communityTokens.getTokenInfo(externalAddress);

    if (tokenInfo == null) {
      throw TokenInfoNotFoundException(externalAddress);
    }

    final creatorIonConnectAddress = tokenInfo.creator.addresses?.ionConnect;

    if (creatorIonConnectAddress == null) {
      throw TokenCreatorIonAddressNotFoundException(externalAddress);
    }

    final creatorEventReference = ReplaceableEventReference.fromString(creatorIonConnectAddress);

    final tags = switch (tokenInfo.addresses) {
      Addresses(ionConnect: final String ionConnectAddress) => {
          '#a': [ionConnectAddress],
          '!#t': [communityTokenActionTopic],
        },
      Addresses(twitter: final String twitterAddress) => {
          '#h': [twitterAddress],
        },
      _ => throw TokenAddressNotFoundException(externalAddress),
    };

    return _ionConnectNotifier.requestEntity<CommunityTokenDefinitionEntity>(
      RequestMessage()
        ..addFilter(
          RequestFilter(
            kinds: const [CommunityTokenDefinitionEntity.kind],
            authors: [creatorEventReference.masterPubkey],
            tags: tags,
          ),
        ),
      actionSource: ActionSource.user(creatorEventReference.masterPubkey),
    );
  }
}

@riverpod
Future<CommunityTokenDefinitionRepository> communityTokenDefinitionRepository(Ref ref) async {
  final ionConnectNotifier = ref.watch(ionConnectNotifierProvider.notifier);
  final analyticsClient = await ref.watch(ionTokenAnalyticsClientProvider.future);

  return CommunityTokenDefinitionRepository(
    ionConnectNotifier: ionConnectNotifier,
    analyticsClient: analyticsClient,
  );
}
