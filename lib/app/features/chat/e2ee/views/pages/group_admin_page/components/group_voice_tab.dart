// SPDX-License-Identifier: ice License 1.0

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:ion/app/features/chat/e2ee/model/entities/encrypted_group_message_entity.f.dart';
import 'package:ion/app/features/chat/e2ee/providers/chat_message_media_path_provider.r.dart';
import 'package:ion/app/features/chat/e2ee/providers/group/group_media_provider.r.dart'
    show GroupMediaItem, groupVoiceItemsProvider;
import 'package:ion/app/features/chat/hooks/use_audio_playback_controller.dart';
import 'package:ion/app/features/chat/hooks/use_audio_playback_setup.dart';
import 'package:ion/app/features/chat/model/database/chat_database.m.dart';
import 'package:ion/app/features/chat/providers/active_audio_message_provider.r.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/model/media_attachment.dart';
import 'package:ion/app/features/user/providers/user_metadata_provider.r.dart';
import 'package:ion/app/utils/date.dart';
import 'package:ion/generated/assets.gen.dart';

class GroupVoiceTab extends ConsumerWidget {
  const GroupVoiceTab({
    required this.conversationId,
    super.key,
  });

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceAsync = ref.watch<AsyncValue<List<GroupMediaItem>>>(
      groupVoiceItemsProvider(conversationId),
    );

    return voiceAsync.when(
      data: (List<GroupMediaItem> voiceItems) {
        if (voiceItems.isEmpty) {
          return Center(
            child: Text(
              context.i18n.common_voice,
              style: context.theme.appTextThemes.body,
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsetsDirectional.only(
            start: 16.0.s,
            end: 16.0.s,
            top: 18.0.s,
          ),
          itemCount: voiceItems.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.0.s),
          itemBuilder: (context, int index) {
            final voiceItem = voiceItems[index];
            return _GroupVoiceCell(
              media: voiceItem.media,
              duration: voiceItem.media.duration,
              eventReference: voiceItem.eventReference,
              publishedAt: voiceItem.publishedAt,
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stack) => Center(
        child: Text(
          context.i18n.common_error,
          style: context.theme.appTextThemes.body,
        ),
      ),
    );
  }
}

class _GroupVoiceCell extends HookConsumerWidget {
  const _GroupVoiceCell({
    required this.media,
    required this.duration,
    required this.eventReference,
    required this.publishedAt,
  });

  final MediaAttachment media;
  final int? duration;
  final EventReference eventReference;
  final int publishedAt;

  String _formatDateAndTime(int timestamp) {
    final date = timestamp.toDateTime;
    final dateStr = DateFormat('d MMM yyyy').format(date);
    final timeStr = DateFormat('HH:mm').format(date);
    return '$dateStr • $timeStr';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(
      userPreviewDataProvider(eventReference.masterPubkey, network: false)
          .select(userPreviewDisplayNameSelector),
    );

    final eventMessageFuture = useFuture(
      useMemoized(
        () => ref.read(eventMessageDaoProvider).getByReference(eventReference),
        [eventReference],
      ),
    );

    final entity = useMemoized(
      () {
        if (eventMessageFuture.hasData && eventMessageFuture.data != null) {
          return EncryptedGroupMessageEntity.fromEventMessage(eventMessageFuture.data!);
        }
        return null;
      },
      [eventMessageFuture.hasData, eventMessageFuture.data],
    );

    final localMediaPath = entity != null
        ? ref.watch(
            chatMessageMediaPathProvider(
              entity: entity,
              loadThumbnail: false,
              convertAudioToWav: true,
              mediaAttachment: media,
            ).select((value) => value.valueOrNull),
          )
        : null;

    if (localMediaPath == null && eventMessageFuture.hasData) {
      return const SizedBox();
    }

    final audioPlaybackController = useAudioWavePlaybackController()
      ..setFinishMode(finishMode: FinishMode.pause);

    final eventMessageId = useMemoized(
      () => eventMessageFuture.hasData && eventMessageFuture.data != null
          ? eventMessageFuture.data!.id
          : null,
      [eventMessageFuture.hasData, eventMessageFuture.data],
    );

    final audioPlayback = useAudioPlaybackSetup(
      eventMessageId: eventMessageId,
      eventReference: eventReference,
      localMediaPath: localMediaPath,
      audioPlaybackController: audioPlaybackController,
      liveWaveColor: context.theme.appColors.primaryText,
      context: context,
      ref: ref,
    );
    final audioPlaybackState = audioPlayback.audioPlaybackState;
    final playerId = audioPlayback.playerId;

    // Get duration from controller or fallback to media duration
    final maxDuration = useMemoized(
      () => audioPlaybackController.maxDuration > 0
          ? audioPlaybackController.maxDuration
          : (duration != null ? duration! * 1000 : 0),
      [audioPlaybackController.maxDuration, duration],
    );

    final durationStr = maxDuration > 0
        ? formatDuration(Duration(milliseconds: maxDuration))
        : (duration != null ? formatDuration(Duration(seconds: duration!)) : '0:00');

    final dateTimeStr = _formatDateAndTime(publishedAt);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.0.s),
      decoration: BoxDecoration(
        color: context.theme.appColors.tertiaryBackground,
        borderRadius: BorderRadius.circular(16.0.s),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (localMediaPath == null || eventMessageId == null) {
                    return;
                  }
                  if (audioPlaybackState.value?.isPlaying ?? false) {
                    ref.read(activeAudioMessageProvider.notifier).activeAudioMessage = null;
                  } else {
                    ref.read(activeAudioMessageProvider.notifier).activeAudioMessage = playerId;
                  }
                },
                child: Container(
                  width: 36.0.s,
                  height: 36.0.s,
                  decoration: BoxDecoration(
                    color: context.theme.appColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(12.0.s),
                    border: Border.all(
                      width: 1.0.s,
                      color: context.theme.appColors.onTertiaryFill,
                    ),
                  ),
                  child: Center(
                    child: localMediaPath == null || eventMessageId == null
                        ? const IONLoadingIndicator(
                            type: IndicatorType.dark,
                          )
                        : ValueListenableBuilder<PlayerState?>(
                            valueListenable: audioPlaybackState,
                            builder: (context, state, child) {
                              if (state == null) {
                                return Assets.svg.iconVideoPlay.icon(
                                  size: 20.0.s,
                                  color: context.theme.appColors.primaryAccent,
                                );
                              }
                              return state.isPlaying
                                  ? Assets.svg.iconVideoPause.icon(
                                      size: 20.0.s,
                                      color: context.theme.appColors.primaryAccent,
                                    )
                                  : Assets.svg.iconVideoPlay.icon(
                                      size: 20.0.s,
                                      color: context.theme.appColors.primaryAccent,
                                    );
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(width: 8.0.s),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: context.theme.appTextThemes.subtitle3,
                  ),
                  Text(
                    '$durationStr • $dateTimeStr',
                    style: context.theme.appTextThemes.caption.copyWith(
                      color: context.theme.appColors.tertiaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
