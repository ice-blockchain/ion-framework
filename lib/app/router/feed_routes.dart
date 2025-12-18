// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class FeedRoutes {
  static const storyRoutePrefix = 'story';

  static const routes = <TypedRoute<RouteData>>[
    TypedGoRoute<StoryViewerRoute>(path: '$storyRoutePrefix/viewing-fullstack/:pubkey'),
    TypedGoRoute<TrendingVideosRoute>(path: 'trending-videos-fullstack/:eventReference'),
    TypedGoRoute<FeedVideosRoute>(path: 'feed-videos-fullstack/:eventReference'),
    TypedGoRoute<FeedAdvancedSearchVideosRoute>(
      path: 'feed-advanced-search-videos-fullstack/:eventReference',
    ),
    TypedGoRoute<ReplyListVideosRoute>(
      path: 'reply-list-videos-fullstack/:eventReference',
    ),
    TypedGoRoute<PostDetailsRoute>(path: 'post/:eventReference'),
    TypedGoRoute<NotificationsHistoryRoute>(path: 'notifications-history'),
    TypedGoRoute<ArticleDetailsRoute>(path: 'article/:eventReference'),
    TypedGoRoute<ArticleRepliesRoute>(path: 'article/:eventReference/replies'),
    TypedGoRoute<ArticlesFromTopicRoute>(path: 'articles/topic/:topic'),
    TypedGoRoute<ArticlesFromAuthorRoute>(path: 'articles/author/:pubkey'),
    TypedGoRoute<FeedSimpleSearchRoute>(path: 'feed-simple-search'),
    TypedGoRoute<FeedAdvancedSearchRoute>(path: 'feed-advanced-search'),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<FeedVisibleArticleCategoriesRoute>(path: 'feed-visible-article-categories'),
      ],
    ),
    ...AdsRoutes.routes,
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<SwitchAccountRoute>(path: 'switch-account'),
      ],
    ),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<AddBookmarkRoute>(path: 'add-bookmark'),
      ],
    ),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<EntityLanguageWarningRoute>(path: 'entity-language-warning'),
        TypedGoRoute<EntityLanguageRoute>(path: 'entity-language'),
      ],
    ),
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<RepostOptionsModalRoute>(path: 'post-repost-options/:eventReference'),
        TypedGoRoute<CreatePostRoute>(path: 'post-editor/create'),
        TypedGoRoute<EditPostRoute>(path: 'post-editor/edit/:modifiedEvent'),
        TypedGoRoute<CreateReplyRoute>(path: 'post-editor/reply/:parentEvent'),
        TypedGoRoute<EditReplyRoute>(
          path: 'post-editor/edit-reply/:parentEvent/:modifiedEvent',
        ),
        TypedGoRoute<CreateQuoteRoute>(path: 'post-editor/quote/:quotedEvent'),
        TypedGoRoute<EditQuoteRoute>(
          path: 'post-editor/edit-quote/:quotedEvent/:modifiedEvent',
        ),
        TypedGoRoute<CreateVideoRoute>(path: 'post-editor/video'),
        TypedGoRoute<CreateArticleRoute>(path: 'create-article'),
        TypedGoRoute<FeedSearchFiltersRoute>(path: 'feed-search_filters'),
        TypedGoRoute<ArticlePreviewRoute>(path: 'article-preview'),
        TypedGoRoute<SelectTopicsRoute>(path: 'topics'),
        TypedGoRoute<EditArticleRoute>(path: 'create-article/edit/:modifiedEvent'),
        TypedGoRoute<EditArticlePreviewRoute>(path: 'article-preview/edit/:modifiedEvent'),
        TypedGoRoute<FeedContentCreationBlockedModalRoute>(path: 'content-creation-blocked'),
      ],
    ),
    TypedGoRoute<InviteFriendsRoute>(path: 'invite-friends-fullstack'),
  ];
}

class ArticleDetailsRoute extends BaseRouteData with _$ArticleDetailsRoute {
  ArticleDetailsRoute({required this.eventReference})
      : super(
          child: ArticleDetailsPage(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
        );

  final String eventReference;
}

class SelectTopicsRoute extends BaseRouteData with _$SelectTopicsRoute {
  SelectTopicsRoute({required this.feedType})
      : super(
          child: SelectTopicsModal(feedType: feedType),
          type: IceRouteType.bottomSheet,
        );

  final FeedType feedType;
}

class ArticleRepliesRoute extends BaseRouteData with _$ArticleRepliesRoute {
  ArticleRepliesRoute({required this.eventReference})
      : super(
          child: ArticleRepliesPage(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
        );

  final String eventReference;
}

class ArticlesFromTopicRoute extends BaseRouteData with _$ArticlesFromTopicRoute {
  ArticlesFromTopicRoute({required this.topic})
      : super(
          child: ArticlesFromTopicPage(
            topic: topic,
          ),
        );

  final String topic;
}

class ArticlesFromAuthorRoute extends BaseRouteData with _$ArticlesFromAuthorRoute {
  ArticlesFromAuthorRoute({required this.pubkey})
      : super(
          child: ArticlesFromAuthorPage(
            pubkey: pubkey,
          ),
        );

  final String pubkey;
}

class PostDetailsRoute extends BaseRouteData with _$PostDetailsRoute {
  PostDetailsRoute({required this.eventReference})
      : super(
          child: PostDetailsPage(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
        );

  final String eventReference;
}

class NotificationsHistoryRoute extends BaseRouteData with _$NotificationsHistoryRoute {
  NotificationsHistoryRoute()
      : super(
          child: const NotificationsHistoryPage(),
        );
}

class RepostOptionsModalRoute extends BaseRouteData with _$RepostOptionsModalRoute {
  RepostOptionsModalRoute({
    required this.eventReference,
  }) : super(
          child: RepostOptionsModal(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
          type: IceRouteType.bottomSheet,
        );

  final String eventReference;
}

class FeedSimpleSearchRoute extends BaseRouteData with _$FeedSimpleSearchRoute {
  FeedSimpleSearchRoute({this.query = ''})
      : super(
          child: FeedSimpleSearchPage(query: query),
        );

  final String query;
}

class FeedAdvancedSearchRoute extends BaseRouteData with _$FeedAdvancedSearchRoute {
  FeedAdvancedSearchRoute({required this.query})
      : super(
          child: FeedAdvancedSearchPage(query: query),
        );

  final String query;
}

class FeedVisibleArticleCategoriesRoute extends BaseRouteData
    with _$FeedVisibleArticleCategoriesRoute {
  FeedVisibleArticleCategoriesRoute()
      : super(
          child: const FeedVisibleArticleCategoriesModal(),
          type: IceRouteType.bottomSheet,
        );
}

class SwitchAccountRoute extends BaseRouteData with _$SwitchAccountRoute {
  SwitchAccountRoute()
      : super(
          child: const SwitchAccountModal(),
          type: IceRouteType.bottomSheet,
        );
}

class CreatePostRoute extends BaseRouteData with _$CreatePostRoute {
  CreatePostRoute({
    this.content,
    this.attachedMedia,
  }) : super(
          child: PostFormModal.createPost(
            content: content,
            attachedMedia: attachedMedia,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String? content;
  final String? attachedMedia;
}

class EditPostRoute extends BaseRouteData with _$EditPostRoute {
  EditPostRoute({
    required this.modifiedEvent,
    this.content,
    this.attachedMedia,
  }) : super(
          child: PostFormModal.editPost(
            modifiedEvent: EventReference.fromEncoded(modifiedEvent),
            content: content,
            attachedMedia: attachedMedia,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String modifiedEvent;
  final String? content;
  final String? attachedMedia;
}

class EditArticleRoute extends BaseRouteData with _$EditArticleRoute {
  EditArticleRoute({required this.modifiedEvent})
      : super(
          child: ArticleFormModal.edit(modifiedEvent: EventReference.fromEncoded(modifiedEvent)),
          type: IceRouteType.bottomSheet,
        );

  final String modifiedEvent;
}

class EditArticlePreviewRoute extends BaseRouteData with _$EditArticlePreviewRoute {
  EditArticlePreviewRoute({required this.modifiedEvent})
      : super(
          child: ArticlePreviewModal.edit(modifiedEvent: EventReference.fromEncoded(modifiedEvent)),
          type: IceRouteType.bottomSheet,
        );
  final String modifiedEvent;
}

class CreateReplyRoute extends BaseRouteData with _$CreateReplyRoute {
  CreateReplyRoute({
    required this.parentEvent,
    this.content,
    this.attachedMedia,
  }) : super(
          child: PostFormModal.createReply(
            parentEvent: EventReference.fromEncoded(parentEvent),
            content: content,
            attachedMedia: attachedMedia,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String parentEvent;
  final String? content;
  final String? attachedMedia;
}

class EditReplyRoute extends BaseRouteData with _$EditReplyRoute {
  EditReplyRoute({
    required this.parentEvent,
    required this.modifiedEvent,
    this.content,
    this.attachedMedia,
  }) : super(
          child: PostFormModal.editReply(
            parentEvent: EventReference.fromEncoded(parentEvent),
            modifiedEvent: EventReference.fromEncoded(modifiedEvent),
            content: content,
            attachedMedia: attachedMedia,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String parentEvent;
  final String modifiedEvent;
  final String? content;
  final String? attachedMedia;
}

class CreateQuoteRoute extends BaseRouteData with _$CreateQuoteRoute {
  CreateQuoteRoute({
    required this.quotedEvent,
    this.content,
    this.attachedMedia,
  }) : super(
          child: PostFormModal.createQuote(
            quotedEvent: EventReference.fromEncoded(quotedEvent),
            content: content,
            attachedMedia: attachedMedia,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String quotedEvent;
  final String? content;
  final String? attachedMedia;
}

class EditQuoteRoute extends BaseRouteData with _$EditQuoteRoute {
  EditQuoteRoute({
    required this.quotedEvent,
    required this.modifiedEvent,
    this.content,
    this.attachedMedia,
  }) : super(
          child: PostFormModal.editQuote(
            quotedEvent: EventReference.fromEncoded(quotedEvent),
            modifiedEvent: EventReference.fromEncoded(modifiedEvent),
            content: content,
            attachedMedia: attachedMedia,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String quotedEvent;
  final String modifiedEvent;
  final String? content;
  final String? attachedMedia;
}

class CreateVideoRoute extends BaseRouteData with _$CreateVideoRoute {
  CreateVideoRoute({
    required this.videoPath,
    required this.mimeType,
    this.content,
    this.videoThumbPath,
  }) : super(
          child: PostFormModal.video(
            videoPath: videoPath,
            videoThumbPath: videoThumbPath,
            mimeType: mimeType,
            content: content,
          ),
          type: IceRouteType.bottomSheet,
        );

  final String videoPath;
  final String? videoThumbPath;
  final String mimeType;
  final String? content;
}

class CreateArticleRoute extends BaseRouteData with _$CreateArticleRoute {
  CreateArticleRoute()
      : super(
          child: ArticleFormModal.create(),
          type: IceRouteType.bottomSheet,
        );
}

class ArticlePreviewRoute extends BaseRouteData with _$ArticlePreviewRoute {
  ArticlePreviewRoute()
      : super(
          child: ArticlePreviewModal.create(),
          type: IceRouteType.bottomSheet,
        );
}

class FeedSearchFiltersRoute extends BaseRouteData with _$FeedSearchFiltersRoute {
  FeedSearchFiltersRoute()
      : super(
          child: const FeedSearchFiltersPage(),
          type: IceRouteType.bottomSheet,
        );
}

@TypedGoRoute<StoryRecordRoute>(path: '/${FeedRoutes.storyRoutePrefix}/record')
class StoryRecordRoute extends BaseRouteData with _$StoryRecordRoute {
  StoryRecordRoute() : super(child: const StoryRecordPage());
}

@TypedGoRoute<StoryPreviewRoute>(path: '/${FeedRoutes.storyRoutePrefix}/preview/:path')
class StoryPreviewRoute extends BaseRouteData with _$StoryPreviewRoute {
  StoryPreviewRoute({
    required this.path,
    required this.mimeType,
    this.eventReference,
    this.isPostScreenshot = false,
    this.fromEditor = false,
    this.originalFilePath,
  }) : super(
          child: StoryPreviewPage(
            path: path,
            mimeType: mimeType,
            eventReference:
                eventReference != null ? EventReference.fromEncoded(eventReference) : null,
            isPostScreenshot: isPostScreenshot,
            fromEditor: fromEditor,
            originalFilePath: originalFilePath,
          ),
          type: IceRouteType.slideFromLeft,
        );

  final String path;
  final String? mimeType;
  final String? eventReference;
  final bool isPostScreenshot;
  final bool fromEditor;
  final String? originalFilePath;
}

class StoryViewerRoute extends BaseRouteData with _$StoryViewerRoute {
  StoryViewerRoute({
    required this.pubkey,
    this.initialStoryReference,
    this.showOnlySelectedUser = false,
  }) : super(
          child: StoryViewerPage(
            pubkey: pubkey,
            initialStoryReference: initialStoryReference != null
                ? EventReference.fromEncoded(initialStoryReference)
                : null,
            showOnlySelectedUser: showOnlySelectedUser,
          ),
          type: IceRouteType.swipeDismissible,
          isFullscreenMedia: true,
        );

  final String pubkey;
  final String? initialStoryReference;
  final bool showOnlySelectedUser;
}

class TrendingVideosRoute extends BaseRouteData with _$TrendingVideosRoute {
  TrendingVideosRoute({required this.eventReference})
      : super(
          child: TrendingVideosPage(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
          type: IceRouteType.swipeDismissible,
        );

  final String eventReference;
}

class FeedVideosRoute extends BaseRouteData with _$FeedVideosRoute {
  FeedVideosRoute({
    required this.eventReference,
    this.initialMediaIndex = 0,
    this.framedEventReference,
  }) : super(
          child: FeedVideosPage(
            eventReference: EventReference.fromEncoded(eventReference),
            framedEventReference: framedEventReference != null
                ? EventReference.fromEncoded(framedEventReference)
                : null,
            initialMediaIndex: initialMediaIndex,
          ),
          type: IceRouteType.swipeDismissible,
        );

  final String eventReference;
  final int initialMediaIndex;
  final String? framedEventReference;
}

class FeedAdvancedSearchVideosRoute extends BaseRouteData with _$FeedAdvancedSearchVideosRoute {
  FeedAdvancedSearchVideosRoute({
    required this.eventReference,
    required this.query,
    required this.category,
    this.initialMediaIndex = 0,
    this.framedEventReference,
  }) : super(
          child: FeedAdvancedSearchVideosPage(
            query: query,
            category: category,
            eventReference: EventReference.fromEncoded(eventReference),
            initialMediaIndex: initialMediaIndex,
            framedEventReference: framedEventReference != null
                ? EventReference.fromEncoded(framedEventReference)
                : null,
          ),
          type: IceRouteType.swipeDismissible,
        );

  final String query;
  final AdvancedSearchCategory category;
  final String eventReference;
  final int initialMediaIndex;
  final String? framedEventReference;
}

class ReplyListVideosRoute extends BaseRouteData with _$ReplyListVideosRoute {
  ReplyListVideosRoute({
    required this.eventReference,
    required this.parentEventReference,
    this.initialMediaIndex = 0,
    this.framedEventReference,
  }) : super(
          child: ReplyListVideosPage(
            eventReference: EventReference.fromEncoded(eventReference),
            initialMediaIndex: initialMediaIndex,
            parentEventReference: EventReference.fromEncoded(parentEventReference),
            framedEventReference: framedEventReference != null
                ? EventReference.fromEncoded(framedEventReference)
                : null,
          ),
          type: IceRouteType.swipeDismissible,
        );

  final String parentEventReference;
  final String eventReference;
  final int initialMediaIndex;
  final String? framedEventReference;
}

class AddBookmarkRoute extends BaseRouteData with _$AddBookmarkRoute {
  AddBookmarkRoute({
    required this.eventReference,
  }) : super(
          child: AddBookmarkModal(
            eventReference: EventReference.fromEncoded(eventReference),
          ),
          type: IceRouteType.bottomSheet,
        );

  final String eventReference;
}

class EntityLanguageRoute extends BaseRouteData with _$EntityLanguageRoute {
  EntityLanguageRoute()
      : super(
          child: const EntityLanguageModal(),
          type: IceRouteType.bottomSheet,
        );
}

class EntityLanguageWarningRoute extends BaseRouteData with _$EntityLanguageWarningRoute {
  EntityLanguageWarningRoute()
      : super(
          child: const EntityLanguageWarningModal(),
          type: IceRouteType.bottomSheet,
        );
}

class InviteFriendsRoute extends BaseRouteData with _$InviteFriendsRoute {
  InviteFriendsRoute()
      : super(
          child: const InviteFriendsPage(),
        );
}

class FeedContentCreationBlockedModalRoute extends BaseRouteData
    with _$FeedContentCreationBlockedModalRoute {
  FeedContentCreationBlockedModalRoute()
      : super(
          child: const FeedContentCreationBlockedModalPage(),
          type: IceRouteType.bottomSheet,
        );
}
