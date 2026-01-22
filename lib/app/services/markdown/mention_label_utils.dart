// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';

// Converts EntityLabel (storage format) to instance map (restore format)
// Returns map of pubkey -> set of instance numbers that should display with market cap
// Example: values=[LabelValue('alice', ['0']), LabelValue('bob'), LabelValue('alice', ['1'])]
//          → {'alice': {0,1}, 'bob': {}} (alice instances 0&1, bob has none)
Map<String, Set<int>> buildInstanceMapFromLabel(EntityLabel? label) {
  final instanceMap = <String, Set<int>>{};

  if (label == null) {
    return instanceMap;
  }

  // Iterate through each labeled value
  for (final labelValue in label.values) {
    final pubkey = labelValue.value;
    final extras = labelValue.additionalElements;

    if (extras.isNotEmpty) {
      // Parse instance number from first additional element (e.g., '0', '1', '2')
      final instanceNumber = int.tryParse(extras.first);
      if (instanceNumber != null) {
        // Add this instance number to the set for this pubkey (creates set if not exists)
        instanceMap.putIfAbsent(pubkey, () => <int>{}).add(instanceNumber);
      }
    }
  }

  return instanceMap;
}

/// Parses a cashtag market cap label into a restore map.
///
/// Storage format (NIP-32 labels):
///   namespace: community.token.marketcap.show.cashtag
///   value: symbolGroup (without '$')
///   additionalElements: [externalAddress, instanceIndex]
///
/// Restore format:
///   symbolGroup -> { instanceIndex -> externalAddress }
Map<String, Map<int, String>> buildCashtagExternalAddressMapFromLabel(EntityLabel? label) {
  final out = <String, Map<int, String>>{};

  if (label == null) {
    return out;
  }

  for (final labelValue in label.values) {
    final symbolGroup = labelValue.value;
    final extras = labelValue.additionalElements;
    if (symbolGroup.isEmpty || extras.length < 2) continue;

    final externalAddress = extras[0].trim();
    final instanceIndex = int.tryParse(extras[1]);
    if (externalAddress.isEmpty || instanceIndex == null) continue;

    out.putIfAbsent(symbolGroup, () => <int, String>{})[instanceIndex] = externalAddress;
  }

  return out;
}
