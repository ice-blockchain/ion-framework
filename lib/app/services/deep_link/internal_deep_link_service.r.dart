// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/data/models/entities/modifiable_post_data.f.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/router/app_routes.gr.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_identifier_service.r.dart';
import 'package:ion/app/services/ion_connect/ion_connect_uri_protocol_service.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'internal_deep_link_service.r.g.dart';

/// Service for handling internal deep links with the ionapp:// scheme
///
/// Supports the following deep link patterns:
/// - ionapp://feed - Opens the feed tab
/// - ionapp://chat - Opens the chat tab
/// - ionapp://wallet - Opens the wallet tab
/// - ionapp://profile - Opens the profile tab or ionapp://profile/master_pubkey for specific user
/// - ionapp://invite - Opens the invite friends page
/// - ionapp://post/encoded_event_reference - Opens a post detail
/// - ionapp://article/encoded_event_reference - Opens an article detail
/// - ionapp://story/master_pubkey/encoded_event_reference - Opens a story viewer
@Riverpod(keepAlive: true)
InternalDeepLinkService internalDeepLinkService(Ref ref) {
  return InternalDeepLinkService(ref);
}

final class InternalDeepLinkService {
  InternalDeepLinkService(this._ref);

  final Ref _ref;

  static const String scheme = 'ionapp';

  /// Checks if the given URL is an internal deep link
  bool isInternalDeepLink(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme.toLowerCase() == scheme;
    } catch (e) {
      Logger.error('Error parsing URL: $url, error: $e');
      return false;
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
      final host = uri.host.toLowerCase();
      final pathSegments = uri.pathSegments;

      switch (host) {
        case 'feed':
          FeedRoute().go(context);
        case 'chat':
          ChatRoute().go(context);
        case 'wallet':
          WalletRoute().go(context);
        case 'profile':
          // Check if pubkey is provided in path: ionapp://profile/master_pubkey
          if (pathSegments.isNotEmpty) {
            final pubkey = pathSegments.first;
            ProfileRoute(pubkey: pubkey).go(context);
          } else {
            // No pubkey provided, open own profile
            SelfProfileRoute().go(context);
          }
        case 'invite':
          InviteFriendsRoute().go(context);
        case 'post':
          if (pathSegments.isNotEmpty) {
            final encodedEventReference = pathSegments.first;
            await _handlePostDeepLink(encodedEventReference, context);
          } else {
            Logger.warning('Missing event reference for post deep link');
            return false;
          }
        case 'article':
          if (pathSegments.isNotEmpty) {
            final encodedEventReference = pathSegments.first;
            ArticleDetailsRoute(eventReference: encodedEventReference).go(context);
          } else {
            Logger.warning('Missing event reference for article deep link');
            return false;
          }
        case 'story':
          // ionapp://story/master_pubkey/encoded_event_reference
          if (pathSegments.length >= 2) {
            final pubkey = pathSegments[0];
            final encodedEventReference = pathSegments[1];
            StoryViewerRoute(
              pubkey: pubkey,
              initialStoryReference: encodedEventReference,
            ).go(context);
          } else {
            Logger.warning('Missing parameters for story deep link');
            return false;
          }
        default:
          Logger.warning('Unsupported internal deep link path: $host');
          return false;
      }

      Logger.log('Internal deep link handled: $url');
      return true;
    } catch (error) {
      Logger.error('Error handling internal deep link: $url, error: $error');
      return false;
    }
  }

  Future<void> _handlePostDeepLink(String encodedEventReference, BuildContext context) async {
    try {
      // Decode the event reference to get the entity
      final encodedShareableIdentifier =
          _ref.read(ionConnectUriProtocolServiceProvider).decode(encodedEventReference);

      if (encodedShareableIdentifier == null) {
        Logger.error('Failed to decode event reference: $encodedEventReference');
        if (context.mounted) {
          // Fallback to regular post route
          PostDetailsRoute(eventReference: encodedEventReference).go(context);
        }
        return;
      }

      final shareableIdentifier = _ref
          .read(ionConnectUriIdentifierServiceProvider)
          .decodeShareableIdentifiers(payload: encodedShareableIdentifier);

      final eventReference = EventReference.fromShareableIdentifier(shareableIdentifier);

      // Fetch the entity to determine if it's a story or video post
      final entity =
          await _ref.read(ionConnectEntityProvider(eventReference: eventReference).future);

      if (!context.mounted) return;

      if (entity is ModifiablePostEntity) {
        if (entity.isStory) {
          // Navigate to story viewer
          StoryViewerRoute(
            pubkey: entity.masterPubkey,
            initialStoryReference: encodedEventReference,
          ).go(context);
          return;
        }

        if (entity.data.hasVideo) {
          // Navigate to fullscreen media viewer
          FullscreenMediaRoute(
            eventReference: encodedEventReference,
            initialMediaIndex: 0,
          ).go(context);
          return;
        }
      }

      // Default: navigate to post details
      PostDetailsRoute(eventReference: encodedEventReference).go(context);
    } catch (error) {
      Logger.error('Error handling post deep link: $error');
      // Fallback to regular post route
      PostDetailsRoute(eventReference: encodedEventReference).go(context);
    }
  }
}
