// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'archive_tile_visibility_provider.r.g.dart';

@Riverpod(keepAlive: true)
class ArchiveTileVisibility extends _$ArchiveTileVisibility {
  @override
  bool build() => false;

  set value(bool value) {
    state = value;
  }
}
