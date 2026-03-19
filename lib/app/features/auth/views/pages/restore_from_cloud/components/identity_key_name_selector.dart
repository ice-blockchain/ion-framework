// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/views/pages/restore_from_cloud/components/identity_key_name_selector_input.dart';
import 'package:ion/app/theme/app_colors.dart';
import 'package:ion/app/theme/app_text_themes.dart';

class IdentityKeyNameSelector extends HookWidget {
  const IdentityKeyNameSelector({
    required this.availableOptions,
    required this.textController,
    this.initialValue,
    super.key,
  });

  final Set<String> availableOptions;
  final TextEditingController textController;
  final String? initialValue;

  static double get height => 58.0.s;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.appColors;
    final textStyles = context.theme.appTextThemes;

    final isOpened = useState(false);
    final menuEnabled = availableOptions.length > 1;
    final scrollController = useScrollController();
    final optionsNotifier = useState<List<String>>(availableOptions.toList()..sort());

    final layerLink = useMemoized(LayerLink.new);
    final fieldKey = useMemoized(GlobalKey.new);
    final overlayEntryRef = useRef<OverlayEntry?>(null);
    final stateRef = useRef<FormFieldState<String?>?>(null);
    final pendingPostFrameUpdate = useRef(false);
    final nextOptionsRef = useRef<List<String>>(availableOptions.toList()..sort());

    void closeMenu() {
      if (!isOpened.value) return;
      isOpened.value = false;
      overlayEntryRef.value?.remove();
      overlayEntryRef.value = null;
    }

    double computeMaxMenuHeight(
      RenderBox fieldBox, {
      required BuildContext mediaQueryContext,
    }) {
      final fieldOrigin = fieldBox.localToGlobal(Offset.zero);
      final fieldBottom = fieldOrigin.dy + fieldBox.size.height;

      final gap = 6.0.s;
      final bottomMargin = 48.0.s;
      final screenHeight = MediaQuery.sizeOf(mediaQueryContext).height;
      final viewInsetsBottom = MediaQuery.viewInsetsOf(mediaQueryContext).bottom;
      final safeBottom = MediaQuery.paddingOf(mediaQueryContext).bottom;

      final available =
          screenHeight - fieldBottom - gap - safeBottom - viewInsetsBottom - bottomMargin;
      return available.clamp(0.0, screenHeight);
    }

    void markOverlayNeedsBuild() => overlayEntryRef.value?.markNeedsBuild();

    void openMenu({
      required FormFieldState<String?> state,
    }) {
      if (!menuEnabled) return;
      if (isOpened.value) return;

      final overlay = Overlay.of(context, rootOverlay: true);

      final fieldContext = fieldKey.currentContext;
      final fieldBox = fieldContext?.findRenderObject() as RenderBox?;
      if (fieldBox == null || !fieldBox.hasSize) return;

      isOpened.value = true;

      overlayEntryRef.value = OverlayEntry(
        builder: (overlayContext) {
          final options = optionsNotifier.value;
          final fieldContextNow = fieldKey.currentContext;
          final fieldBoxNow = fieldContextNow?.findRenderObject() as RenderBox?;
          final fieldSize = fieldBoxNow?.size ?? fieldBox.size;

          final maxHeight = (fieldBoxNow != null && fieldBoxNow.hasSize)
              ? computeMaxMenuHeight(fieldBoxNow, mediaQueryContext: overlayContext)
              : computeMaxMenuHeight(fieldBox, mediaQueryContext: overlayContext);

          final overlayWidth = fieldSize.width;
          return _IdentityKeyNameDropdownOverlay(
            options: options,
            layerLink: layerLink,
            closeMenu: closeMenu,
            scrollController: scrollController,
            maxHeight: maxHeight,
            overlayWidth: overlayWidth,
            colors: colors,
            textStyles: textStyles,
            onSelect: (identityKeyName) {
              state
                ..didChange(identityKeyName)
                ..save()
                ..validate();
              textController.text = identityKeyName;
              closeMenu();
            },
          );
        },
      );

      overlay.insert(overlayEntryRef.value!);
    }

    useEffect(
      () {
        if (isOpened.value) {
          WidgetsBinding.instance.addPostFrameCallback((_) => markOverlayNeedsBuild());
        }
        return null;
      },
      [
        MediaQuery.viewInsetsOf(context).bottom,
        MediaQuery.sizeOf(context).height,
        MediaQuery.paddingOf(context).bottom,
        isOpened.value,
      ],
    );

    useEffect(
      () {
        if (!menuEnabled) return null;

        void listener() {
          final nextFilteredOptions = availableOptions.where((option) {
            return option.toLowerCase().contains(textController.text.toLowerCase());
          }).toSet();

          final nextOptions =
              (nextFilteredOptions.isNotEmpty ? nextFilteredOptions : availableOptions).toList()
                ..sort();

          nextOptionsRef.value = nextOptions;
          if (pendingPostFrameUpdate.value) return;

          pendingPostFrameUpdate.value = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            pendingPostFrameUpdate.value = false;
            if (!context.mounted) return;

            optionsNotifier.value = nextOptionsRef.value;

            if (optionsNotifier.value.isEmpty) {
              closeMenu();
              return;
            }

            // Only update UI if the menu is already open.
            // This prevents reopening after selection (programmatic text updates).
            if (isOpened.value) {
              markOverlayNeedsBuild();
            }
          });
        }

        textController.addListener(listener);
        return () => textController.removeListener(listener);
      },
      [textController, menuEnabled, availableOptions],
    );

    useEffect(
      () => closeMenu,
      const [],
    );

    return FormField<String?>(
      validator: (option) => !availableOptions.contains(option)
          ? context.i18n.restore_from_cloud_select_available_identity_key_name_error
          : null,
      initialValue: initialValue,
      builder: (state) {
        stateRef.value = state;
        return SizedBox(
          width: double.infinity,
          height: height,
          child: SizedBox(
            key: fieldKey,
            width: double.infinity,
            height: height,
            child: CompositedTransformTarget(
              link: layerLink,
              child: SizedBox(
                width: double.infinity,
                height: height,
                child: IdentityKeyNameSelectorInput(
                  textController: textController,
                  isOpened: isOpened,
                  menuEnabled: availableOptions.length > 1,
                  errorText: state.errorText,
                  onToggleMenu: () {
                    if (!menuEnabled) return;
                    if (isOpened.value) {
                      closeMenu();
                    } else if (optionsNotifier.value.isNotEmpty) {
                      openMenu(state: state);
                    }
                  },
                  onChanged: (value) {
                    state
                      ..didChange(value)
                      ..save()
                      ..validate();
                  },
                  onFocused: menuEnabled
                      ? (hasFocus) {
                          if (hasFocus && optionsNotifier.value.isNotEmpty) {
                            openMenu(state: state);
                          } else {
                            closeMenu();
                          }
                        }
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IdentityKeyNameDropdownOverlay extends StatelessWidget {
  const _IdentityKeyNameDropdownOverlay({
    required this.options,
    required this.layerLink,
    required this.closeMenu,
    required this.onSelect,
    required this.scrollController,
    required this.maxHeight,
    required this.overlayWidth,
    required this.colors,
    required this.textStyles,
  });

  final List<String> options;
  final LayerLink layerLink;
  final VoidCallback closeMenu;
  final ValueChanged<String> onSelect;
  final ScrollController scrollController;
  final double maxHeight;
  final double overlayWidth;
  final AppColorsExtension colors;
  final AppTextThemesExtension textStyles;

  @override
  Widget build(BuildContext context) {
    final gap = 6.0.s;
    const itemExtentBase = 48.0;
    final itemExtent = itemExtentBase.s;
    final contentHeight = options.length * itemExtent;
    final isScrollable = contentHeight > maxHeight;
    final desiredHeight = contentHeight < maxHeight ? contentHeight : maxHeight;

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: closeMenu,
            child: const SizedBox.expand(),
          ),
          CompositedTransformFollower(
            link: layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, IdentityKeyNameSelector.height + gap),
            child: Material(
              color: colors.secondaryBackground,
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: colors.strokeElements,
                  width: 1.0.s,
                ),
                borderRadius: BorderRadius.circular(12.0.s),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: overlayWidth,
                  maxWidth: overlayWidth,
                  maxHeight: maxHeight,
                ),
                child: SizedBox(
                  height: desiredHeight,
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: isScrollable,
                    thickness: 3.0.s,
                    radius: Radius.circular(999.0.s),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      itemExtent: itemExtent,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final identityKeyName = options[index];
                        return InkWell(
                          onTap: () => onSelect(identityKeyName),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0.s),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                identityKeyName,
                                style: textStyles.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
