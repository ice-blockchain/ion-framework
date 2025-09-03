// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:convert' show utf8;

import 'package:convert/convert.dart' show hex;
import 'package:fpjs_pro_plugin/fpjs_pro_plugin.dart';
import 'package:fpjs_pro_plugin/region.dart';
import 'package:ion/app/exceptions/exceptions.dart';
import 'package:ion/app/features/core/providers/env_provider.r.dart';
import 'package:ion/app/features/ion_connect/ion_connect.dart';
import 'package:ion/app/features/ion_connect/providers/ion_connect_event_signer_provider.r.dart';
import 'package:ion/app/services/logger/logger.dart';
import 'package:ion/app/services/platform_info_service/platform_info_service.r.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_identification_service.r.g.dart';

@Riverpod(keepAlive: true)
class DeviceIdentificationService extends _$DeviceIdentificationService {
  bool _initialized = false;

  @override
  Future<void> build() async {
    if (_initialized) {
      return;
    }

    final env = ref.read(envProvider.notifier);
    final origin = env.get<String>(EnvVariable.ION_ORIGIN);
    await FpjsProPlugin.initFpjs(
      env.get(EnvVariable.DEVICE_IDENTIFICATION_CLIENT_API_KEY),
      region: Region.eu,
      endpoint: '$origin/v1/device-identifications',
    );
    _initialized = true;
  }

  Future<String> getRequestIdFor(String identityKeyName) async {
    // wait till initialized
    await future;

    try {
      final eventSigner =
          await ref.read(ionConnectEventSignerProvider(identityKeyName).notifier).initEventSigner();
      if (eventSigner == null) {
        throw EventSignerNotFoundException();
      }
      final platformInfo = ref.read(platformInfoServiceProvider);
      final signature = await _buildSignature(eventSigner: eventSigner, platformInfo: platformInfo);
      final data = await FpjsProPlugin.getVisitorData(tags: {'signature': signature});
      return data.requestId;
    } catch (error, stackTrace) {
      Logger.log(
        'Failed to get request id',
        error: error,
        stackTrace: stackTrace,
      );
      throw const DeviceIdentityVerificationException();
    }
  }

  Future<String> _buildSignature({
    required EventSigner eventSigner,
    required PlatformInfoService platformInfo,
  }) async {
    final os = platformInfo.name;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000; // seconds since UTC epoch
    final payload = '$os:$now'.toLowerCase();
    final messageHex = hex.encode(utf8.encode(payload));
    final signedPayload = await eventSigner.sign(message: messageHex);

    return '$now:${eventSigner.publicKey}:${signedPayload.replaceAll('eddsa/curve25519:', '')}';
  }
}
