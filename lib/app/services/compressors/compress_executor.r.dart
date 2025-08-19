// SPDX-License-Identifier: ice License 1.0

import 'dart:async';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:synchronized/synchronized.dart';

part 'compress_executor.r.g.dart';

class CompressExecutor {
  final _lock = Lock();

  Future<FFmpegSession> execute(
    List<String> args,
    Completer<FFmpegSession> sessionResultCompleter, {
    Completer<FFmpegSession>? sessionIdCompleter,
  }) async {
    return _lock.synchronized(() async {
      final session = await FFmpegKit.executeWithArgumentsAsync(args, (sessionResult) {
        sessionResultCompleter.complete(sessionResult);
      });

      sessionIdCompleter?.complete(session);

      return sessionResultCompleter.future;
    });
  }
}

@Riverpod(keepAlive: true)
CompressExecutor compressExecutor(Ref ref) => CompressExecutor();
