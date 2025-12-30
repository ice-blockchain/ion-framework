// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/tokenized_communities/utils/master_pubkey_resolver.dart';
import 'package:ion/app/router/app_routes.gr.dart';

class ProfileNavigationUtils {
  static Future<T?> navigateToProfile<T extends Object?>(
    BuildContext context, {
    String? pubkey,
    String? externalAddress,
    EventReference? eventReference,
  }) {
    assert(
      pubkey != null || externalAddress != null,
      'Either pubkey or externalAddress must be provided',
    );

    final resolvedPubkey =
        pubkey ?? MasterPubkeyResolver.resolve(externalAddress!, eventReference: eventReference);

    final currentState = GoRouterState.of(context);
    final currentPath = currentState.matchedLocation;

    final isCurrentlyOnProfile = currentPath.contains('/user/');

    if (isCurrentlyOnProfile) {
      final currentPubkey = currentState.pathParameters['pubkey'];
      if (currentPubkey == resolvedPubkey) {
        return Future.value();
      }
    }

    return ProfileRoute(pubkey: resolvedPubkey).push<T>(context);
  }
}
