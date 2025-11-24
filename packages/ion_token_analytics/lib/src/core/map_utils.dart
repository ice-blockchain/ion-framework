/// Deeply merges two JSON-like maps.
///
/// [original] is the base map.
/// [patch] is the map containing updates.
///
/// Returns a new map with the merged content.
Map<String, dynamic> deepMerge(
  Map<String, dynamic> original,
  Map<String, dynamic> patch,
) {
  final result = Map<String, dynamic>.from(original);

  patch.forEach((key, value) {
    if (value is Map<String, dynamic> && result.containsKey(key) && result[key] is Map<String, dynamic>) {
      result[key] = deepMerge(result[key] as Map<String, dynamic>, value);
    } else {
      result[key] = value;
    }
  });

  return result;
}
