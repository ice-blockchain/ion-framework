// SPDX-License-Identifier: ice License 1.0

import 'package:ion/app/constants/emails.dart';
import 'package:ion/app/services/mail/mail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'contact_support_notifier.r.g.dart';

enum ContactSupportSubject {
  feedback('Feedback'),
  reservedNickname('Reserved Nickname');

  const ContactSupportSubject(this.label);

  final String label;
}

@riverpod
class ContactSupportNotifier extends _$ContactSupportNotifier {
  @override
  FutureOr<void> build() async {}

  Future<void> email({required ContactSupportSubject subject}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await sendEmail(
        receiver: Emails.support,
        subject: subject.label,
        body: '',
      );
    });
  }
}
