// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'archive_tile_visibility_provider.r.g.dart';

@riverpod
class ArchiveTileVisibility extends _$ArchiveTileVisibility {
  @override
  bool build() {
    keepAliveWhenAuthenticated(ref);

    return false;
  }

  set value(bool value) {
    state = value;
  }
}
