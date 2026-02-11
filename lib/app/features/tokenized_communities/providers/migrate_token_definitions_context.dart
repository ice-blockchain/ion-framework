// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/feed/data/models/entities/article_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/feed/data/models/entities/post_data.f.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/events_metadata.f.dart';
import 'package:ion/app/features/tokenized_communities/models/entities/community_token_definition.f.dart';

class MigrationContext {
  final modifiablePosts = <ModifiablePostEntity>{};
  final modifiablePostEventReferencesHasTokenDefinition = <EventReference>{};

  final posts = <PostEntity>{};
  final postEventReferencesHasTokenDefinition = <EventReference>{};

  final articles = <ArticleEntity>{};
  final articleEventReferencesHasTokenDefinition = <EventReference>{};

  void processEvent(EventMessage event) {
    if (event.kind == ModifiablePostEntity.kind) {
      final entity = ModifiablePostEntity.fromEventMessage(event);
      if ((entity.data.relatedEvents?.isEmpty ?? true) && !entity.isStory) {
        modifiablePosts.add(entity);
      }
    } else if (event.kind == PostEntity.kind) {
      posts.add(PostEntity.fromEventMessage(event));
    } else if (event.kind == ArticleEntity.kind) {
      articles.add(ArticleEntity.fromEventMessage(event));
    } else if (event.kind == EventsMetadataEntity.kind) {
      _processMetadataEvent(event);
    }
  }

  void _processMetadataEvent(EventMessage event) {
    final metadataEntity = EventsMetadataEntity.fromEventMessage(event);

    if (metadataEntity.data.metadata.kind == CommunityTokenDefinitionEntity.kind) {
      final rawDefinition = metadataEntity.data.metadata;
      final definition = CommunityTokenDefinitionEntity.fromEventMessage(rawDefinition).data
          as CommunityTokenDefinitionIon;

      if (definition.kind == ModifiablePostEntity.kind) {
        modifiablePostEventReferencesHasTokenDefinition.add(definition.eventReference);
      } else if (definition.kind == PostEntity.kind) {
        postEventReferencesHasTokenDefinition.add(definition.eventReference);
      } else if (definition.kind == ArticleEntity.kind) {
        articleEventReferencesHasTokenDefinition.add(definition.eventReference);
      }
    }
  }

  List<CommunityTokenDefinitionIon> collectTokenDefinitions(String masterPubkey) {
    final definitions = <CommunityTokenDefinitionIon>[];

    // Modifiable Posts
    for (final modifiablePost in modifiablePosts) {
      if (modifiablePostEventReferencesHasTokenDefinition
          .contains(modifiablePost.toEventReference())) {
        continue;
      }
      definitions.add(
        CommunityTokenDefinitionIon.fromEventReference(
          eventReference: modifiablePost.toEventReference(),
          kind: ModifiablePostEntity.kind,
          type: CommunityTokenDefinitionIonType.original,
        ),
      );
    }

    // Posts
    for (final post in posts) {
      if (postEventReferencesHasTokenDefinition.contains(post.toEventReference())) {
        continue;
      }
      definitions.add(
        CommunityTokenDefinitionIon.fromEventReference(
          eventReference: post.toEventReference(),
          kind: PostEntity.kind,
          type: CommunityTokenDefinitionIonType.original,
        ),
      );
    }

    // Articles
    for (final article in articles) {
      if (articleEventReferencesHasTokenDefinition.contains(article.toEventReference())) {
        continue;
      }
      definitions.add(
        CommunityTokenDefinitionIon.fromEventReference(
          eventReference: article.toEventReference(),
          kind: ArticleEntity.kind,
          type: CommunityTokenDefinitionIonType.original,
        ),
      );
    }

    return definitions;
  }
}
