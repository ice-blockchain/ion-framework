// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internal_deep_link_service.r.g.dart';

/// Enum representing the available internal deep link host routes
enum InternalDeepLinkHost {
  feed('feed'),
  chat('chat'),
  wallet('wallet'),
  profile('profile'),
  invite('invite'),
  post('post'),
  article('article'),
  story('story'),
  video('video');

  const InternalDeepLinkHost(this.value);

  final String value;

  /// Parses a string to an [InternalDeepLinkHost] enum value
  static InternalDeepLinkHost? fromString(String value) {
    try {
      return InternalDeepLinkHost.values.firstWhere(
        (host) => host.value == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Service for handling internal deep links with the ionapp:// scheme
///
/// Supports the following deep link patterns:
/// - ionapp://feed - Opens the feed tab
/// - ionapp://chat - Opens the chat tab
/// - ionapp://chat/master_pubkey - Opens a specific conversation
/// - ionapp://wallet - Opens the wallet tab
/// - ionapp://profile - Opens the profile tab or ionapp://profile/master_pubkey for specific user
/// - ionapp://invite - Opens the invite friends page
/// - ionapp://post/encoded_event_reference - Opens a post detail
/// - ionapp://article/encoded_event_reference - Opens an article detail
/// - ionapp://story/master_pubkey/encoded_event_reference - Opens a story viewer
/// - ionapp://video/encoded_event_reference - Opens fullscreen video viewer
@Riverpod(keepAlive: true)
InternalDeepLinkService internalDeepLinkService(Ref ref) {
  return InternalDeepLinkService(ref);
}

final class InternalDeepLinkService {
  InternalDeepLinkService(this._ref);

  final Ref _ref;

  /// Checks if the given URL is an internal deep link
  bool isInternalDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      final internalScheme =
          _ref.read(envProvider.notifier).get<String>(EnvVariable.ION_INTERNAL_DEEP_LINK_SCHEME);

      final scheme = uri.scheme.toLowerCase();
      final isInternalScheme = scheme == internalScheme.toLowerCase();
      final isInternalHost = InternalDeepLinkHost.fromString(uri.host) != null;
      final usesCustomScheme = scheme != 'http' && scheme != 'https';

      return isInternalScheme || (isInternalHost && usesCustomScheme);
    } catch (e) {
      Logger.error('Error parsing URL: $url, error: $e');
      return false;
    }
  }

  /// Extracts the route location from internal deep link parameters
  /// Returns null if the route cannot be determined
  String? getRouteLocation(String host, List<String> pathSegments) {
    try {
      final internalHost = InternalDeepLinkHost.values.firstWhere(
        (h) => h.value.toLowerCase() == host.toLowerCase(),
      );

      return switch (internalHost) {
        InternalDeepLinkHost.feed => FeedRoute().location,
        InternalDeepLinkHost.chat => pathSegments.isNotEmpty
            ? ConversationRoute(receiverMasterPubkey: pathSegments.first).location
            : ChatRoute().location,
        InternalDeepLinkHost.wallet => WalletRoute().location,
        InternalDeepLinkHost.profile => pathSegments.isNotEmpty
            ? ProfileRoute(pubkey: pathSegments.first).location
            : SelfProfileRoute().location,
        InternalDeepLinkHost.invite => InviteFriendsRoute().location,
        InternalDeepLinkHost.story => pathSegments.length >= 2
            ? StoryViewerRoute(
                pubkey: pathSegments[0],
                initialStoryReference: pathSegments[1],
              ).location
            : null,
        InternalDeepLinkHost.article => pathSegments.isNotEmpty
            ? ArticleDetailsRoute(eventReference: pathSegments.first).location
            : null,
        InternalDeepLinkHost.post => pathSegments.isNotEmpty
            ? PostDetailsRoute(eventReference: pathSegments.first).location
            : null,
        InternalDeepLinkHost.video => pathSegments.isNotEmpty
            ? FullscreenMediaRoute(eventReference: pathSegments.first, initialMediaIndex: 0)
                .location
            : null,
      };
    } catch (e) {
      Logger.error('Error extracting route location from host: $host, error: $e');
      return null;
    }
  }

  /// Handles an internal deep link by navigating to the appropriate route
  ///
  /// Returns true if the deep link was handled successfully, false otherwise
  Future<bool> handleInternalDeepLink(String url, BuildContext context) async {
    if (!isInternalDeepLink(url)) {
      return false;
    }

    try {
      final uri = Uri.parse(url);
      final host = InternalDeepLinkHost.fromString(uri.host);
      final pathSegments = uri.pathSegments;

      if (host == null) {
        Logger.warning('Unsupported internal deep link path: ${uri.host}');
        return false;
      }

      await _ref.read(appReadyProvider.future);

      final location = switch (host) {
        InternalDeepLinkHost.feed => FeedRoute().location,
        // ionapp://chat/master_pubkey for direct conversation
        InternalDeepLinkHost.chat => pathSegments.isNotEmpty
            ? ConversationRoute(receiverMasterPubkey: pathSegments.first).location
            : ChatRoute().location,
        InternalDeepLinkHost.wallet => WalletRoute().location,
        // Check if pubkey is provided in path: ionapp://profile/master_pubkey
        // if no pubkey provided, open own profile
        InternalDeepLinkHost.profile => pathSegments.isNotEmpty
            ? ProfileRoute(pubkey: pathSegments.first).location
            : SelfProfileRoute().location,
        InternalDeepLinkHost.invite => InviteFriendsRoute().location,
        // ionapp://story/master_pubkey/encoded_event_reference
        InternalDeepLinkHost.story => pathSegments.length >= 2
            ? StoryViewerRoute(
                pubkey: pathSegments[0],
                initialStoryReference: pathSegments[1],
              ).location
            : null,
        InternalDeepLinkHost.article => pathSegments.isNotEmpty
            ? ArticleDetailsRoute(eventReference: pathSegments.first).location
            : null,
        InternalDeepLinkHost.post => pathSegments.isNotEmpty && context.mounted
            ? await _handlePostDeepLink(pathSegments.first, context)
            : null,
        // ionapp://video/encoded_event_reference for fullscreen video viewer
        InternalDeepLinkHost.video => pathSegments.isNotEmpty && context.mounted
            ? await _handleVideoDeepLink(pathSegments.first, context)
            : null,
      };

      if (location != null) {
        _ref.read(deeplinkPathProvider.notifier).path = location;
      }

      Logger.log('Internal deep link handled: $url');
      return true;
    } catch (error) {
      Logger.error('Error handling internal deep link: $url, error: $error');
      return false;
    }
  }

  Future<String?> _handlePostDeepLink(String encodedEventReference, BuildContext context) async {
    try {
      // Decode the event reference to get the entity
      final encodedShareableIdentifier =
          _ref.read(ionConnectUriProtocolServiceProvider).decode(encodedEventReference);

      if (encodedShareableIdentifier == null) {
        Logger.error('Failed to decode event reference: $encodedEventReference');
        // Fallback to regular post route
        return PostDetailsRoute(eventReference: encodedEventReference).location;
      }

      final shareableIdentifier = _ref
          .read(ionConnectUriIdentifierServiceProvider)
          .decodeShareableIdentifiers(payload: encodedShareableIdentifier);

      final eventReference = EventReference.fromShareableIdentifier(shareableIdentifier);

      // Fetch the entity to determine if it's a story or video post
      final entity =
          await _ref.read(ionConnectEntityProvider(eventReference: eventReference).future);

      if (!context.mounted) return null;

      if (entity is ModifiablePostEntity) {
        if (entity.isStory) {
          // Navigate to story viewer
          return StoryViewerRoute(
            pubkey: entity.masterPubkey,
            initialStoryReference: encodedEventReference,
          ).location;
        }

        if (entity.data.hasVideo) {
          // Navigate to fullscreen media viewer
          return FullscreenMediaRoute(
            eventReference: encodedEventReference,
            initialMediaIndex: 0,
          ).location;
        }
      }

      // Default: navigate to post details
      return PostDetailsRoute(eventReference: encodedEventReference).location;
    } catch (error) {
      Logger.error('Error handling post deep link: $error');
      // Fallback to regular post route
      if (context.mounted) {
        PostDetailsRoute(eventReference: encodedEventReference).go(context);
      }
    }
    return null;
  }

  Future<String?> _handleVideoDeepLink(String encodedEventReference, BuildContext context) async {
    try {
      // Decode the event reference to get the entity
      final encodedShareableIdentifier =
          _ref.read(ionConnectUriProtocolServiceProvider).decode(encodedEventReference);

      if (encodedShareableIdentifier == null) {
        Logger.error('Failed to decode event reference: $encodedEventReference');
        // Fallback to fullscreen media route
        return FullscreenMediaRoute(
          eventReference: encodedEventReference,
          initialMediaIndex: 0,
        ).location;
      }

      final shareableIdentifier = _ref
          .read(ionConnectUriIdentifierServiceProvider)
          .decodeShareableIdentifiers(payload: encodedShareableIdentifier);

      final eventReference = EventReference.fromShareableIdentifier(shareableIdentifier);

      // Fetch the entity to verify it's a video post
      final entity =
          await _ref.read(ionConnectEntityProvider(eventReference: eventReference).future);

      if (!context.mounted) return null;

      if (entity is ModifiablePostEntity && entity.data.hasVideo) {
        // Navigate to fullscreen media viewer
        return FullscreenMediaRoute(
          eventReference: encodedEventReference,
          initialMediaIndex: 0,
        ).location;
      }

      // Fallback to post details if not a video
      Logger.warning('Video deep link used for non-video post, falling back to post details');
      return PostDetailsRoute(eventReference: encodedEventReference).location;
    } catch (error) {
      Logger.error('Error handling video deep link: $error');
      // Fallback to fullscreen media route
      if (context.mounted) {
        FullscreenMediaRoute(
          eventReference: encodedEventReference,
          initialMediaIndex: 0,
        ).go(context);
      }
    }
    return null;
  }
}
