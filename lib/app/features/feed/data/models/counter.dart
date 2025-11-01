// SPDX-License-Identifier: ice License 1.0

import 'dart:math';

class Counter {
  Counter({
    required this.limit,
  }) : _current = 0;

  final int limit;
  int _current;

  bool get isReached => _current >= limit;

  int get triesLeft => max(limit - _current, 0);

  void increment() {
    _current++;
  }
}
