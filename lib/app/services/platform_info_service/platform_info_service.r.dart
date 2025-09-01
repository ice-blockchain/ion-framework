// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'platform_info_service.r.g.dart';

class PlatformInfoService {
  final PlatformInfoDelegate _delegate = PlatformInfoDelegate.forPlatform();

  String get name => _delegate.name;

  Future<String> get version => _delegate.version;

  Future<String> get release => _delegate.release;
}

abstract class PlatformInfoDelegate {
  factory PlatformInfoDelegate.forPlatform() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidPlatformInfoDelegate(),
      TargetPlatform.iOS => IOSPlatformInfoDelegate(),
      _ => throw UnsupportedError('Unsupported platform: $defaultTargetPlatform'),
    };
  }

  String get name;

  Future<String> get version;

  Future<String> get release;
}

class AndroidPlatformInfoDelegate implements PlatformInfoDelegate {
  @override
  String get name => 'Android';

  @override
  Future<String> get version async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt.toString();
  }

  @override
  Future<String> get release async {
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.release;
  }
}

class IOSPlatformInfoDelegate implements PlatformInfoDelegate {
  @override
  String get name => 'iOS';

  @override
  Future<String> get version async {
    final info = await DeviceInfoPlugin().iosInfo;
    return info.systemVersion;
  }

  @override
  Future<String> get release async {
    final info = await DeviceInfoPlugin().iosInfo;
    return info.systemVersion;
  }
}

@Riverpod(keepAlive: true)
PlatformInfoService platformInfoService(Ref ref) => PlatformInfoService();
