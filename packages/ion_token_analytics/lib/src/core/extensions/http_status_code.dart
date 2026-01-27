// SPDX-License-Identifier: ice License 1.0

extension HttpStatusCodeExtension on int {
  bool get isSuccessStatusCode => this >= 200 && this < 300;
}
