// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion/app/extensions/extensions.dart';

sealed class WalletItemIconType {
  //  Custom size
  const factory WalletItemIconType.custom({required double size}) = _CustomSize;

  // Predefined sizes
  factory WalletItemIconType.tiny() => _PredefinedSize(12.s);
  factory WalletItemIconType.small() => _PredefinedSize(16.s);
  factory WalletItemIconType.medium() => _PredefinedSize(24.s);
  factory WalletItemIconType.big() => _PredefinedSize(36.s);
  factory WalletItemIconType.huge() => _PredefinedSize(46.s);

  const WalletItemIconType._(this.size);

  final double size;

  // Since network or coin icons may already have rounding as part of the image,
  // we need to use dynamic borderRadius here to avoid image distortion.
  BorderRadius get borderRadius => BorderRadius.circular(size * 0.3);
}

class _PredefinedSize extends WalletItemIconType {
  const _PredefinedSize(super.size) : super._();
}

class _CustomSize extends WalletItemIconType {
  const _CustomSize({required double size}) : super._(size);
}
