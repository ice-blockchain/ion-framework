// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/overlay_menu/notifiers/overlay_menu_close_signal.dart';
import 'package:ion/app/components/overlay_menu/overlay_menu.dart';

ObjectRef<CloseOverlayMenuCallback?>? useHideOnSignal(
  OverlayMenuCloseSignal? closeSignal,
) {
  if (closeSignal == null) return null;

  final closeMenuRef = useRef<CloseOverlayMenuCallback?>(null);
  useEffect(
    () {
      void listener() => closeMenuRef.value?.call(animate: false);
      closeSignal.addListener(listener);

      return () => closeSignal.removeListener(listener);
    },
    [closeSignal],
  );

  return closeMenuRef;
}
