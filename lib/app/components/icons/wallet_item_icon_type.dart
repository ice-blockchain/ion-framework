// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

sealed class WalletItemIconType {
  //  Custom size
  const factory WalletItemIconType.custom({required double size}) = _CustomSize;

  // Predefined sizes
  factory WalletItemIconType.tiny() => const _PredefinedSize(12);
  factory WalletItemIconType.small() => const _PredefinedSize(16);
  factory WalletItemIconType.medium() => const _PredefinedSize(24);
  factory WalletItemIconType.big() => const _PredefinedSize(36);
  factory WalletItemIconType.huge() => const _PredefinedSize(46);

  const WalletItemIconType._(this._size);

  final double _size;

  // Since network or coin icons may already have rounding as part of the image,
  // we need to use dynamic borderRadius here to avoid image distortion.
  BorderRadius get borderRadius => BorderRadius.circular(_size * 0.3);

  double get size => _size.s;
}

class _PredefinedSize extends WalletItemIconType {
  const _PredefinedSize(super._size) : super._();
}

class _CustomSize extends WalletItemIconType {
  const _CustomSize({required double size}) : super._(size);
}
