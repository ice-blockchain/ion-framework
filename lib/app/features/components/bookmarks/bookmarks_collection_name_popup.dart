// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/button/button.dart';
import 'package:ion/app/components/card/info_card.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_clear_button.dart';
import 'package:ion/app/components/inputs/text_input/components/text_input_icons.dart';
import 'package:ion/app/components/inputs/text_input/text_input.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/screen_offset/screen_bottom_offset.dart';
import 'package:ion/app/components/screen_offset/screen_side_offset.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/router/components/navigation_app_bar/navigation_close_button.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ion/generated/assets.gen.dart';

const int _collectionNameMaxLength = 50;

class BookmarksCollectionNamePopup extends HookConsumerWidget {
  const BookmarksCollectionNamePopup({
    required this.onAction,
    required this.title,
    required this.desc,
    required this.action,
    this.initialValue = '',
    super.key,
  });

  final String initialValue;
  final String title;
  final String desc;
  final String action;
  final Future<void> Function(String collectionName) onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionName = useState(initialValue);
    final isProcessing = useState(false);
    final controller = useTextEditingController(text: initialValue);
    final formKey = useRef(GlobalKey<FormState>());

    useEffect(
      () {
        void onControllerChange() {
          collectionName.value = controller.text;
        }

        controller.addListener(onControllerChange);
        return () => controller.removeListener(onControllerChange);
      },
      [controller],
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          padding: EdgeInsetsDirectional.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Form(
            key: formKey.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(top: 30.0.s, bottom: 6.0.s),
                  child: InfoCard(
                    iconAsset: Assets.svg.actionWalletName,
                    title: title,
                    description: desc,
                  ),
                ),
                SizedBox(height: 20.0.s),
                ScreenSideOffset.large(
                  child: TextInput(
                    controller: controller,
                    isLive: true,
                    labelText: context.i18n.bookmarks_collection_name,
                    suffixIcon: collectionName.value.isEmpty
                        ? null
                        : TextInputIcons(
                            icons: [
                              TextInputClearButton(
                                controller: controller,
                              ),
                            ],
                          ),
                    validator: (String? value) {
                      if (Validators.isEmpty(value)) return '';

                      if (Validators.isInvalidLength(value, maxLength: _collectionNameMaxLength)) {
                        return context.i18n.error_input_length_max(_collectionNameMaxLength);
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 25.0.s),
                ScreenSideOffset.small(
                  child: Button(
                    onPressed: () async {
                      if (formKey.value.currentState!.validate()) {
                        isProcessing.value = true;
                        try {
                          await onAction(controller.text.trim());
                          if (context.mounted) {
                            context.pop();
                          }
                        } finally {
                          isProcessing.value = false;
                        }
                      }
                    },
                    label: Text(action),
                    trailingIcon: isProcessing.value ? const IONLoadingIndicator() : null,
                    disabled: collectionName.value.isEmpty || isProcessing.value,
                    type: collectionName.value.isEmpty ? ButtonType.disabled : ButtonType.primary,
                    mainAxisSize: MainAxisSize.max,
                  ),
                ),
                ScreenBottomOffset(),
              ],
            ),
          ),
        ),
        PositionedDirectional(
          top: 12.0.s,
          end: 10.0.s,
          child: NavigationCloseButton(
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
