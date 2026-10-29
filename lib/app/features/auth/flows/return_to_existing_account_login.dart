// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';

void returnToExistingAccountLogin(BuildContext context) {
  // The sign-in caller treats false as a request for password registration.
  Navigator.of(context).pop(true);
}
