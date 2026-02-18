// SPDX-License-Identifier: ice License 1.0

import 'package:android_nav_setting/android_nav_setting.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

///
/// Returns true if the device has a button navigation bar, false otherwise.
///
bool useHasAndroidButtonNavBar() {
  final result = useState(false);

  useEffect(
    () {
      AndroidNavSetting().isGestureNavigationEnabled().then((isGesture) {
        result.value = !isGesture;
      });

      return null;
    },
    const [],
  );

  return result.value;
}
