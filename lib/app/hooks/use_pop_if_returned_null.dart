// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';

typedef PopIfNullCallback<T> = Future<void> Function(Future<T?> Function());

PopIfNullCallback<T> usePopIfReturnedNull<T>() {
  final context = useContext();
  return useCallback<PopIfNullCallback<T>>(
    (Future<T?> Function() func) async {
      final result = await func();
      if (result == null && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.maybePop();
          }
        });
      }
    },
    [context],
  );
}
