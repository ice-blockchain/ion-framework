// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

class IonBridgeException extends IonSwapException {
  const IonBridgeException([super.message]);
}

class NotEnoughGasOnBscException extends IonBridgeException {
  const NotEnoughGasOnBscException([super.message]);
}
