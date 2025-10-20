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
import 'package:ion/app/features/chat/e2ee/providers/chat_message_media_path_provider.r.dart';
import 'package:ion/app/features/chat/hooks/use_audio_playback_controller.dart';
import 'package:ion/app/features/chat/hooks/use_has_reaction.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/model/message_list_item.f.dart';
import 'package:ion/app/features/chat/providers/active_audio_message_provider.r.dart';
import 'package:ion/app/features/chat/recent_chats/providers/replied_message_list_item_provider.r.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_item_wrapper/message_item_wrapper.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_metadata/message_metadata.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_reactions/message_reactions.dart';
import 'package:ion/app/features/chat/views/components/message_items/message_types/reply_message/reply_message.dart';
import 'package:ion/app/features/components/entities_list/list_cached_objects.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/services/audio_wave_playback_service/audio_wave_playback_service.r.dart';
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
    final isMe = ref.watch(isCurrentUserSelectorProvider(eventMessage.masterPubkey));

    final entity = useMemoized(
      () => ReplaceablePrivateDirectMessageEntity.fromEventMessage(eventMessage),
      [eventMessage],
    );

    final eventReference = entity.toEventReference();
    final hasReactions = useHasReaction(eventReference, ref);

    final messageMedia = ref.watch(
          chatMediasProvider(eventReference: eventReference).select((value) {
            final media = value.valueOrNull;

            if (media != null && media.isNotEmpty) {
              ListCachedObjects.updateObject<MessageMediaTableData>(
                context,
                media.first,
              );

              return media.first;
            }
            return null;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<MessageMediaTableData>(context, eventReference);

    final mediaAttachment =
        messageMedia?.remoteUrl == null ? null : entity.data.media[messageMedia?.remoteUrl!];

    final localMediaPath = ref
            .watch(
              chatMessageMediaPathProvider(
                entity: entity,
                loadThumbnail: false,
                convertAudioToWav: true,
                cacheKey: messageMedia?.cacheKey,
                mediaAttachment: mediaAttachment,
              ).select((value) {
                final audioPath = value.valueOrNull;
                if (audioPath != null) {
                  ListCachedObjects.updateObject<PathWithKey>(
                    context,
                    (key: eventReference.toString(), filePath: audioPath),
                  );
                }
                return value;
              }),
            )
            .valueOrNull ??
        ListCachedObjects.maybeObjectOf<PathWithKey>(context, eventReference.toString())?.filePath;

    if (localMediaPath == null) {
      return const SizedBox();
    }

    final audioPlaybackState = useState<PlayerState?>(null);
    final audioPlaybackController = useAudioWavePlaybackController()
      ..setFinishMode(finishMode: FinishMode.pause);

    final playerWaveStyle = useMemoized(
      () => PlayerWaveStyle(
        spacing: 2.0.s,
        waveThickness: 1.0.s,
        seekLineColor: Colors.transparent,
        fixedWaveColor: context.theme.appColors.sheetLine,
        liveWaveColor:
            isMe ? context.theme.appColors.onPrimaryAccent : context.theme.appColors.primaryText,
      ),
      [isMe],
    );

    useEffect(
      () {
        ref.read(audioWavePlaybackServiceProvider).initializePlayer(
              eventMessage.id,
              localMediaPath,
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
      [localMediaPath],
    );

    useEffect(
      () {
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
      [localMediaPath],
    );

    ref.listen(activeAudioMessageProvider, (previous, next) {
      if (next == eventMessage.id) {
        audioPlaybackController.startPlayer();
      } else {
        audioPlaybackController.pausePlayer();
      }
    });

    final metadataWidth = useState<double>(0);
    final metadataKey = useMemoized(GlobalKey.new);
    final contentPadding = EdgeInsets.all(12.0.s);

    useOnInit(() {
      final renderBox = metadataKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        metadataWidth.value = renderBox.size.width;
      }
    });

    final messageItem = useMemoized(
      () => AudioItem(
        eventMessage: eventMessage,
        contentDescription: context.i18n.common_voice_message,
      ),
      [eventMessage],
    );

    final repliedEventMessage = ref.watch(
          repliedMessageListItemProvider(messageItem).select((value) {
            final repliedEvent = value.valueOrNull;

            if (repliedEvent != null) {
              ListCachedObjects.updateObject<EventMessage>(context, repliedEvent);
            }
            return repliedEvent;
          }),
        ) ??
        ListCachedObjects.maybeObjectOf<EventMessage>(
          context,
          entity.data.parentEvent?.eventReference.dTag,
        );

    final repliedMessageItem = getRepliedMessageListItem(
      ref: ref,
      repliedEventMessage: repliedEventMessage,
    );

    return MessageItemWrapper(
      isMe: isMe,
      margin: margin,
      messageItem: messageItem,
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
                          eventMessageId: eventMessage.id,
                          audioPlaybackState: audioPlaybackState,
                          audioPlaybackController: audioPlaybackController,
                        ),
                        SizedBox(width: 8.0.s),
                        _AudioWaveformDisplay(
                          isMe: isMe,
                          playerWaveStyle: playerWaveStyle,
                          audioPlaybackState: audioPlaybackState,
                          audioPlaybackController: audioPlaybackController,
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
              MessageMetadata(
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
