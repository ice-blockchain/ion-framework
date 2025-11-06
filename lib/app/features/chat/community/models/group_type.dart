// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:ion/app/extensions/build_context.dart';
import 'package:ion/app/features/chat/model/selectable_type.dart';
import 'package:ion/generated/assets.gen.dart';

enum GroupType implements SelectableType {
  public,
  private,
  encrypted;

  @override
  String getTitle(BuildContext context) => switch (this) {
        GroupType.public => context.i18n.common_public,
        GroupType.private => context.i18n.common_private,
        GroupType.encrypted => context.i18n.group_create_type_encrypted,
      };

  @override
  String getDescription(BuildContext context) => switch (this) {
        GroupType.public => context.i18n.group_create_type_public_desc,
        GroupType.private => context.i18n.group_create_type_private_desc,
        GroupType.encrypted => context.i18n.group_create_type_encrypted_desc,
      };

  @override
  String get iconAsset => switch (this) {
        GroupType.public => Assets.svg.iconChannelType,
        GroupType.private => Assets.svg.iconChannelPrivatetype,
        GroupType.encrypted => Assets.svg.iconLoginIdentity,
      };

  int? get maxMembers => switch (this) {
        GroupType.public => null,
        GroupType.private => 200,
        GroupType.encrypted => 5,
      };
}
