// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/inputs/hooks/use_node_focused.dart';
import 'package:ion/app/components/inputs/text_input/ion_text_field.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/feed/polls/providers/poll_draft_provider.r.dart';
import 'package:ion/generated/assets.gen.dart';

class PollAnswerItem extends HookConsumerWidget {
  const PollAnswerItem({
    required this.index,
    this.isLast = false,
    super.key,
  });

  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.appColors;
    final textThemes = context.theme.appTextThemes;

    final inputContainerKey = useRef(UniqueKey());
    final focusNode = useFocusNode();
    final hasFocus = useNodeFocused(focusNode);

    final answer = ref.watch(pollDraftNotifierProvider).answers[index];
    final textController = useTextEditingController(text: answer.text);

    const characterLimit = 25;
    final remainingCharacters = characterLimit - textController.text.length;

    useEffect(
      () {
        if (textController.text != answer.text) {
          textController.text = answer.text;
        }
        return null;
      },
      [answer.text],
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            key: inputContainerKey.value,
            height: 36.0.s,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.onSecondaryBackground,
                borderRadius: BorderRadius.circular(12.0.s),
                border: Border.all(
                  color: remainingCharacters < 0
                      ? colors.attentionRed
                      : (hasFocus.value ? colors.primaryAccent : Colors.transparent),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0.s),
                child: Row(
                  children: [
                    Flexible(
                      child: IonTextField(
                        controller: textController,
                        focusNode: focusNode,
                        onChanged: (value) {
                          ref.read(pollDraftNotifierProvider.notifier).updateAnswer(index, value);
                        },
                        style: textThemes.body2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: context.i18n.poll_choice_placeholder(index + 1),
                          hintStyle: textThemes.caption,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsetsDirectional.only(bottom: 10),
                        ),
                        cursorColor: colors.primaryAccent,
                        cursorHeight: 22.0.s,
                      ),
                    ),
                    if (hasFocus.value || remainingCharacters < 0) SizedBox(width: 4.0.s),
                    if (hasFocus.value || remainingCharacters < 0)
                      Text(
                        remainingCharacters.toString(),
                        style: textThemes.caption2.copyWith(
                          color:
                              remainingCharacters < 0 ? colors.attentionRed : colors.tertiaryText,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.0.s),
        SizedBox(
          width: 20.0.s,
          height: 20.0.s,
          child: isLast
              ? GestureDetector(
                  onTap: () {
                    ref.read(pollDraftNotifierProvider.notifier).removeAnswer(index);
                  },
                  child: Assets.svg.iconBlockDelete
                      .icon(size: 20.0.s, color: context.theme.appColors.quaternaryText),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
