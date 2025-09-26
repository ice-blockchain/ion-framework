// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/overlay_menu/hooks/use_hide_on_scroll.dart';
import 'package:ion/app/components/overlay_menu/hooks/use_hide_on_tab_change.dart';
import 'package:ion/app/extensions/extensions.dart';

class OverlayMenu extends HookWidget {
  const OverlayMenu({
    required this.child,
    required this.menuBuilder,
    this.onOpen,
    this.onClose,
    this.scrollController,
    this.isNeedHideOnTabChange = false,
    super.key,
  });

  final Widget child;
  final Widget Function(VoidCallback closeMenu) menuBuilder;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final ScrollController? scrollController;
  final bool isNeedHideOnTabChange;

  @override
  Widget build(BuildContext context) {
    final menuKey = useMemoized(GlobalKey.new, []);
    final menuWidth = useState<double>(0);
    final menuHeight = useState<double>(0);

    final overlayPortalController = useMemoized(OverlayPortalController.new);
    final followLink = useMemoized(LayerLink.new);
    final animationController = useAnimationController(duration: const Duration(milliseconds: 400));
    final scaleAnimation = CurvedAnimation(parent: animationController, curve: Curves.easeOutBack);

    useHideOnScroll(context, overlayPortalController, scrollController);

    if (isNeedHideOnTabChange) {
      useHideOnTabChange(context, overlayPortalController);
    }

    final hideMenu = useCallback(
      () {
        animationController.reverse().whenComplete(() {
          overlayPortalController.hide();
          onClose?.call();
        });
      },
      [overlayPortalController],
    );

    final showMenu = useCallback(
      () {
        final isScrolling = scrollController?.position.isScrollingNotifier.value ?? false;
        //prevent opening filters menu if scroll is active
        if (!isScrolling) {
          overlayPortalController.show();
          animationController.forward();
          onOpen?.call();
        }
      },
      [overlayPortalController],
    );

    return OverlayPortal(
      controller: overlayPortalController,
      overlayChildBuilder: (_) {
        final renderBox = context.findRenderObject()! as RenderBox;

        final globalOffset = renderBox.localToGlobal(Offset.zero);
        final screenSize = MediaQuery.sizeOf(context);
        final shouldAlignStart = (globalOffset.dx + menuWidth.value) < screenSize.width;
        final shouldAlignBelow = (globalOffset.dy + menuHeight.value) < screenSize.height;

        final offset = Offset(
          shouldAlignStart ? 6.0.s : renderBox.size.width - 6.0.s,
          shouldAlignBelow ? renderBox.size.height + 6.0.s : -6.0.s,
        );
        final anchorAlignment = (shouldAlignBelow
                ? (shouldAlignStart ? AlignmentDirectional.topStart : AlignmentDirectional.topEnd)
                : (shouldAlignStart
                    ? AlignmentDirectional.bottomStart
                    : AlignmentDirectional.bottomEnd))
            .resolve(TextDirection.ltr);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: hideMenu,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: followLink,
                offset: offset,
                followerAnchor: anchorAlignment,
                showWhenUnlinked: false,
                child: ScaleTransition(
                  alignment: anchorAlignment,
                  scale: scaleAnimation,
                  child: Builder(
                    builder: (ctx) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final kb = menuKey.currentContext;
                        if (kb != null) {
                          final size = (kb.findRenderObject()! as RenderBox).size;
                          if (size.width != menuWidth.value) {
                            menuWidth.value = size.width;
                            menuHeight.value = size.height;
                          }
                        }
                      });
                      return IntrinsicHeight(
                        child: IntrinsicWidth(
                          key: menuKey,
                          child: menuBuilder(hideMenu),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: GestureDetector(
        onTap: showMenu,
        child: CompositedTransformTarget(
          link: followLink,
          child: child,
        ),
      ),
    );
  }
}
