// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/features/feed/providers/feed_config_provider.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'registration_restrictions_provider.r.g.dart';

enum RegistrationRestrictionType { fullyAllowed, earlyAccessOnly, restricted }

@riverpod
Future<RegistrationRestrictionType> registrationRestriction(Ref ref) async {
  final feedConfig = await ref.watch(feedConfigProvider.future);

  if (feedConfig.enableEarlyAccessRegistrations == true) {
    return RegistrationRestrictionType.earlyAccessOnly;
  }

  return RegistrationRestrictionType.fullyAllowed;
}
