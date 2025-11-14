// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reply_input_focus_provider.r.g.dart';

@riverpod
class ReplyInputFocusController extends _$ReplyInputFocusController {
  @override
  bool build(EventReference eventReference) => false;

  set focused(bool focused) => state = focused;
}
