// SPDX-License-Identifier: ice License 1.0

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_location_provider.r.g.dart';

@Riverpod(keepAlive: true)
class RouteLocation extends _$RouteLocation {
  @override
  String build() {
    return '';
  }

  void setLocation(String location) {
    if (state != location) {
      state = location;
    }
  }
}
