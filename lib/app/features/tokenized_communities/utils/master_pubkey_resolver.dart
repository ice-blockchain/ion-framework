// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';

class MasterPubkeyResolver {
  MasterPubkeyResolver._();

  static String resolve(String externalAddress, {EventReference? eventReference}) {
    if (eventReference != null) {
      return eventReference.masterPubkey;
    } else {
      return ReplaceableEventReference.fromString(externalAddress).masterPubkey;
    }
  }

  static String creatorExternalAddressFromExternal(String externalAddress) {
    final masterPubkey = resolve(externalAddress);
    return ReplaceableEventReference(
      kind: UserMetadataEntity.kind,
      masterPubkey: masterPubkey,
    ).toString();
  }
}
