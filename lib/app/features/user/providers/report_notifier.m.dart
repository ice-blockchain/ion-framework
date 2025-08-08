// SPDX-License-Identifier: ice License 1.0

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ion/app/constants/emails.dart';
import 'package:ion/app/features/ion_connect/model/event_reference.f.dart';
import 'package:ion/app/features/user/model/user_metadata.f.dart';
import 'package:ion/app/services/deep_link/deep_link_service.r.dart';
import 'package:ion/app/services/mail/mail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'report_notifier.m.freezed.dart';
part 'report_notifier.m.g.dart';

@freezed
sealed class ReportReason with _$ReportReason {
  const factory ReportReason.user({required String pubkey}) = ReportReasonUser;
  const factory ReportReason.content({required EventReference eventReference}) =
      ReportReasonContent;
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
    final deepLinkService = ref.read(deepLinkServiceProvider);

    final encodedReason = switch (reason) {
      ReportReasonUser() => await deepLinkService.createDeeplink(
          ReplaceableEventReference(masterPubkey: reason.pubkey, kind: UserMetadataEntity.kind)
              .encode(),
        ),
      ReportReasonContent() => await deepLinkService.createDeeplink(reason.eventReference.encode()),
    };

    return switch (reason) {
      ReportReasonUser() => 'This is a report for the user $encodedReason',
      ReportReasonContent() => 'This is a report for the content $encodedReason',
    };
  }
}
