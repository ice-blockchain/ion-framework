// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';

class MasterPubkeyResolver {
  MasterPubkeyResolver._();

  static String resolve(String externalAddress, {EventReference? eventReference}) {
    return eventReference?.masterPubkey ??
        ReplaceableEventReference.fromString(externalAddress).masterPubkey;
  }
}
