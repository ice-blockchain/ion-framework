// SPDX-License-Identifier: ice License 1.0

import 'dart:io';
import 'package:android_play_install_referrer/android_play_install_referrer.dart'
    show AndroidPlayInstallReferrer;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'referrer_service.r.g.dart';

@riverpod
Future<String?> installReferrer(Ref ref) async {
  if (Platform.isAndroid != true) {
    return null;
  }

  final referrerDetails = await AndroidPlayInstallReferrer.installReferrer;

  final referrer = referrerDetails.installReferrer;
  if (referrer == null || referrer.isEmpty) {
    return null;
  }
  //referrer data is passed in google play URL in referrer param as encoded query string,
  // example: https://play.google.com/store/apps/details?id=com.example.app&referrer=sender_id%3D12345%26campaign%3Dinvite_test
  final params = Uri.splitQueryString(referrer);
  return params['sender_id'];
}
