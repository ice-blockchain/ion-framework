// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/features/ion_connect/model/entity_label.f.dart';

// Converts EntityLabel (storage format) to instance map (restore format)
// Returns map of pubkey -> set of instance numbers that should display with market cap
// Example: values=['alice','bob','alice'] + additionalElements={'0':['0'],'2':['1']}
//          → {'alice': {0,1}, 'bob': {}} (alice instances 0&1, bob has none)
Map<String, Set<int>> buildInstanceMapFromLabel(EntityLabel? label) {
  final instanceMap = <String, Set<int>>{};

  if (label == null) {
    return instanceMap;
  }

  // Iterate through each labeled pubkey
  for (var i = 0; i < label.values.length; i++) {
    final pubkey = label.values[i];
    // Extract additional elements (4th+ tag elements) for this label position
    final extras = label.additionalElements?[i.toString()];

    if (extras != null && extras.isNotEmpty) {
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
