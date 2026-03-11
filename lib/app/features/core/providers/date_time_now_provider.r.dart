// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'date_time_now_provider.r.g.dart';

@Riverpod(keepAlive: true)
DateTime dateTimeNow(Ref ref) {
  return DateTime.now();
}
