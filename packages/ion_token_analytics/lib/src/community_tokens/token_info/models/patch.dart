// SPDX-License-Identifier: ice License 1.0

// Mixin for models that can merge partial updates into a complete model.
abstract mixin class Patch<T> {
  // Merges this patch with the original model, returning a new complete model.
  // Fields present in the patch override the original, fields absent in the patch
  // are preserved from the original.
  T merge(T original);

  // If the original model is null, this tries to build a full model.
  // Default: cannot build → return null.
  T? toEntityOrNull() => null;
}
