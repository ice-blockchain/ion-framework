import 'package:ion/app/features/ion_connect/model/ion_connect_entity.dart';

extension SortableIonConnectEntityList on Iterable<IonConnectEntity> {
  /// Sorts the list of entities, moving the one matching the [pinnedKey] to the top.
  ///
  /// If [pinnedKey] is null or not found, the original order is preserved.
  /// Returns a new sorted [List<IonConnectEntity>].
  List<IonConnectEntity> sortedByPinnedKey(String? pinnedKey) {
    if (pinnedKey == null) {
      return toList();
    }

    // Sort the list so the pinned item comes first.
    final sortedList = toList()
      ..sort((a, b) {
        // Check if item 'a' or 'b' is the one that is pinned.
        final isAPinned = a.toEventReference().toString() == pinnedKey;
        final isBPinned = b.toEventReference().toString() == pinnedKey;

        if (isAPinned) return -1; // 'a' comes before 'b'
        if (isBPinned) return 1; // 'b' comes before 'a'
        return 0; // The relative order of non-pinned items is unchanged.
      });

    return sortedList;
  }
}
