// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/constants/emails.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_entity_provider.r.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/deep_link/appsflyer_deep_link_service.r.dart';
import 'package:ion/app/services/deep_link/shared_content_type.dart';
import 'package:ion/app/services/mail/mail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_notifier.m.freezed.dart';
part 'report_notifier.m.g.dart';

@freezed
sealed class ReportReason with _$ReportReason {
  const factory ReportReason.user({required String text, required String pubkey}) =
      ReportReasonUser;
  const factory ReportReason.content({
    required String text,
    required EventReference eventReference,
  }) = ReportReasonContent;
  const factory ReportReason.ticker({
    required String text,
    required EventReference eventReference,
  }) = ReportReasonTicker;
}

@riverpod
class ReportNotifier extends _$ReportNotifier {
  static const String reportSubject = 'Report';

  @override
  FutureOr<void> build() async {}

  Future<void> report(ReportReason reason) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await sendEmail(
        receiver: Emails.support,
        subject: reportSubject,
        body: await _getReportBody(reason),
      );
    });
  }

  Future<String> _getReportBody(ReportReason reason) async {
    final appsflyerDeepLinkService = ref.read(appsflyerDeepLinkServiceProvider);

    final encodedReason = await switch (reason) {
      ReportReasonUser() => appsflyerDeepLinkService.createDeeplink(
          path:
              ReplaceableEventReference(masterPubkey: reason.pubkey, kind: UserMetadataEntity.kind)
                  .encode(),
          contentType: SharedContentType.profile,
        ),
      ReportReasonContent() => () async {
          final entity =
              ref.read(ionConnectEntityProvider(eventReference: reason.eventReference)).valueOrNull;
          final contentType = entity != null ? mapEntityToSharedContentType(entity) : null;

          return appsflyerDeepLinkService.createDeeplink(
            path: reason.eventReference.encode(),
            contentType: contentType,
          );
        }(),
      ReportReasonTicker() => () async {
          final entity =
              ref.read(ionConnectEntityProvider(eventReference: reason.eventReference)).valueOrNull;
          final contentType = entity != null ? mapEntityToSharedContentType(entity) : null;

          return appsflyerDeepLinkService.createDeeplink(
            path: reason.eventReference.encode(),
            contentType: contentType,
          );
        }(),
    };

    return switch (reason) {
      ReportReasonUser() => '${reason.text} $encodedReason',
      ReportReasonContent() => '${reason.text} $encodedReason',
      ReportReasonTicker() => '${reason.text} $encodedReason',
    };
  }
}
