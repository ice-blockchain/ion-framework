// SPDX-License-Identifier: ice License 1.0

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ion_content_labeler_provider.r.g.dart';

@Riverpod(keepAlive: true)
IONTextLabeler ionContentLabeler(Ref ref) {
  return IONTextLabeler();
}
