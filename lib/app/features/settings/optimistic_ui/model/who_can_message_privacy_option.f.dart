// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/features/optimistic_ui/core/optimistic_model.dart';
import 'package:ion/app/features/settings/model/privacy_options.dart';

part 'who_can_message_privacy_option.f.freezed.dart';

@freezed
class WhoCanMessagePrivacyOption with _$WhoCanMessagePrivacyOption implements OptimisticModel {
  const factory WhoCanMessagePrivacyOption({
    required String masterPubkey,
    required UserVisibilityPrivacyOption visibility,
  }) = _WhoCanMessagePrivacyOption;

  const WhoCanMessagePrivacyOption._();

  @override
  String get optimisticId => masterPubkey;
}
