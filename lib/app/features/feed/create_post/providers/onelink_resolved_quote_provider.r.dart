// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onelink_resolved_quote_provider.r.g.dart';

/// Holds the [EventReference] resolved from a OneLink URL pasted in the post editor.
///
/// This provider is set when the user pastes an AppsFlyer OneLink URL that resolves
/// to a post, and is read by [PostSubmitButton] to include the quoted event when
/// creating the post.
///
/// Reset when the post form modal opens.
@riverpod
class OneLinkResolvedQuoteNotifier extends _$OneLinkResolvedQuoteNotifier {
  @override
  EventReference? build() => null;

  set resolvedQuote(EventReference? value) {
    state = value;
  }
}
