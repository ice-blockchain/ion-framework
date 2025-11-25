// SPDX-License-Identifier: ice License 1.0

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/stories/providers/story_pause_provider.r.dart';
import 'package:ion/app/features/feed/stories/providers/story_reply_provider.r.dart';
import 'package:ion/app/features/feed/views/components/toolbar_buttons/toolbar_send_button.dart';
import 'package:ion/app/hooks/use_on_init.dart';

class StoryInputField extends HookConsumerWidget {
  const StoryInputField({
    required this.controller,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String?> onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTextNotEmpty = useState(false);
    final focusNode = useFocusNode();
    final focused = useNodeFocused(focusNode);
    final replyLoading = ref.watch(storyReplyProvider).isLoading;

    final appColors = context.theme.appColors;
    final onPrimaryAccent = appColors.onPrimaryAccent;
    final textTheme = context.theme.appTextThemes;
    final body2 = textTheme.body2;

    useOnInit(
      () {
        if (ref.context.mounted) {
          ref.read(storyPauseControllerProvider.notifier).paused = replyLoading || focused.value;
        }
      },
      [focused.value],
    );

    useEffect(
      () {
        void onTextChanged() => isTextNotEmpty.value = controller.text.isNotEmpty;
        controller.addListener(onTextChanged);
        return () => controller.removeListener(onTextChanged);
      },
      [controller],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: 16.0.s,
            end: 16.0.s,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0.s),
            child: Container(
              constraints: BoxConstraints(minHeight: 36.0.s),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Stack(
                  children: [
                    IonTextField(
                      minLines: 1,
                      maxLines: 4,
                      scrollPhysics: const BouncingScrollPhysics(),
                      cursorColor: onPrimaryAccent,
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: appColors.primaryText.withValues(alpha: 0.5),
                        contentPadding: EdgeInsetsDirectional.only(
                          start: 12.0.s,
                          top: 9.0.s,
                          bottom: 9.0.s,
                          end: 58.0.s,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0.s),
                          borderSide: BorderSide.none,
                        ),
                        hintText: context.i18n.write_a_message,
                        hintStyle: body2.copyWith(color: onPrimaryAccent),
                        isDense: true,
                      ),
                      style: body2.copyWith(color: onPrimaryAccent),
                    ),
                    if (isTextNotEmpty.value)
                      PositionedDirectional(
                        bottom: 4.0.s,
                        end: 4.0.s,
                        child: ToolbarSendButton(
                          enabled: true,
                          onPressed: () => onSubmitted(controller.text),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
