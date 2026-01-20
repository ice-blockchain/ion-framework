// SPDX-License-Identifier: ice License 1.0

enum SwapStatus {
  pending,
  succeeded,
  failed;

  static SwapStatus? fromString(String? value) {
    if (value == null) return null;
    return SwapStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SwapStatus.pending,
    );
  }
}
