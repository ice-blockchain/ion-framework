// SPDX-License-Identifier: ice License 1.0

import 'package:ion_swap_client/exceptions/ion_swap_exception.dart';

class ExolixException extends IonSwapException {
  const ExolixException([super.message]);
}

class ExolixBelowMinimumException extends ExolixException {
  const ExolixBelowMinimumException({
    required this.minAmount,
    required this.message,
  }) : super(message);

  final num minAmount;
  @override
  final String message;
}
