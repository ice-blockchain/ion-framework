// SPDX-License-Identifier: ice License 1.0

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/auth/providers/auth_provider.m.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/private_direct_message_data.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_medias_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_message_load_media_provider.r.dart';
import 'package:ion/app/features/chat/hooks/use_audio_playback_controller.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/providers/active_audio_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_metadata/message_metadata.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/audio_wave_playback_service/audio_wave_playback_service.r.dart';
import 'package:ion/app/services/compressors/audio_compressor.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

part 'components/audio_wave_form_display.dart';
part 'components/play_pause_button.dart';

class AudioMessage extends HookConsumerWidget {
  const AudioMessage({
    required this.eventMessage,
    this.margin,
    this.onTapReply,
    super.key,
  });

  final EventMessage eventMessage;
  final VoidCallback? onTapReply;
  final EdgeInsetsDirectional? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));
    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final audioUrl = useState<String?>(null);

    final hasReactions = useHasReaction(entity.toEventReference(), ref);

    final messageMedia = ref
        .watch(chatMediasProvider(eventReference: entity.toEventReference()))
        .valueOrNull
        ?.firstOrNull;

    final mediaAttachment =
        messageMedia?.remoteUrl == null ? null : entity.data.media[messageMedia?.remoteUrl!];

    useEffect(
      () {
        if (audioUrl.value != null) return null;
        ref
            .read(
          chatMessageLoadMediaProvider(
            entity: entity,
            mediaAttachment: mediaAttachment,
            loadThumbnail: false,
            cacheKey: messageMedia?.cacheKey,
          ),
        )
            .then((value) {
          if (value != null && context.mounted) {
            ref.read(audioCompressorProvider).compressAudioToWav(value.path).then((value) {
              audioUrl.value = value;
            });
          }
        });
        return null;
      },
      [messageMedia, mediaAttachment?.url, audioUrl.value],
    );

    if (audioUrl.value == null) {
      return const SizedBox.shrink();
    }

    final audioPlaybackState = useState<PlayerState?>(null);
    final audioPlaybackController = useAudioWavePlaybackController()
      ..setFinishMode(finishMode: FinishMode.pause);
    final playerWaveStyle = useMemoized(
      () => PlayerWaveStyle(
        liveWaveColor:
            isMe ? context.theme.appColors.onPrimaryAccent : context.theme.appColors.primaryText,
        fixedWaveColor: context.theme.appColors.sheetLine,
        seekLineColor: Colors.transparent,
        waveThickness: 1.0.s,
        spacing: 2.0.s,
      ),
      [isMe],
    );

    useEffect(
      () {
        if (audioUrl.value == null) return null;
        ref.read(audioWavePlaybackServiceProvider).initializePlayer(
              eventMessage.id,
              audioUrl.value!,
              audioPlaybackController,
              playerWaveStyle,
            );

        final stateSubscription = audioPlaybackController.onPlayerStateChanged.listen((event) {
          if (context.mounted) {
            if (event != PlayerState.stopped) {
              audioPlaybackState.value = event;
            }
          }
        });

        final completionSubscription = audioPlaybackController.onCompletion.listen((event) {
          if (context.mounted) {
            ref.read(activeAudioMessageProvider.notifier).activeAudioMessage = null;
          }
        });

        return () {
          stateSubscription.cancel();
          completionSubscription.cancel();
        };
      },
      [audioUrl.value],
    );

    final metadataWidth = useState<double>(0);
    final metadataKey = useMemoized(GlobalKey.new);
    final contentPadding = EdgeInsets.all(12.0.s);

    useOnInit(() {
      final renderBox = metadataKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        metadataWidth.value = renderBox.size.width;
      }
    });

    ref.listen(activeAudioMessageProvider, (previous, next) {
      if (next == eventMessage.id) {
        audioPlaybackController.startPlayer();
      } else {
        audioPlaybackController.pausePlayer();
      }
    });

    final messageItem = AudioItem(
      eventMessage: eventMessage,
      contentDescription: context.i18n.common_voice_message,
    );

    final repliedEventMessage = ref.watch(repliedMessageListItemProvider(messageItem));

    final repliedMessageItem = getRepliedMessageListItem(
      ref: ref,
      repliedEventMessage: repliedEventMessage.valueOrNull,
    );

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: AudioItem(
        eventMessage: eventMessage,
        contentDescription: context.i18n.common_voice_message,
      ),
      contentPadding: contentPadding,
      child: Column(
        children: [
          if (repliedMessageItem != null) ReplyMessage(messageItem, repliedMessageItem, onTapReply),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PlayPauseButton(
                          audioPlaybackController: audioPlaybackController,
                          audioPlaybackState: audioPlaybackState,
                          eventMessageId: eventMessage.id,
                        ),
                        SizedBox(width: 8.0.s),
                        _AudioWaveformDisplay(
                          audioPlaybackController: audioPlaybackController,
                          audioPlaybackState: audioPlaybackState,
                          playerWaveStyle: playerWaveStyle,
                          isMe: isMe,
                        ),
                      ],
                    ),
                    MessageReactions(
                      isMe: isMe,
                      eventMessage: eventMessage,
                    ),
                  ],
                ),
              ),
              MessageMetaData(
                eventMessage: eventMessage,
                startPadding: hasReactions ? 0.0.s : 8.0.s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
