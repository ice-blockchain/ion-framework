// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/utils/url.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'suggested_token_icon_availability_provider.r.g.dart';

@riverpod
Stream<bool> suggestedTokenIconAvailability(
  Ref ref,
  String url,
) async* {
  if (url.isEmpty || !isNetworkUrl(url)) {
    yield false;
    return;
  }
  var isDisposed = false;
  ref.onDispose(() {
    isDisposed = true;
  });
  final deadline = DateTime.now().add(const Duration(minutes: 2));
  while (!isDisposed && DateTime.now().isBefore(deadline)) {
    final isAvailable = await _checkSuggestedTokenIconAvailable(url);
    if (isAvailable) {
      yield true;
      return;
    }
    yield false;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

Future<bool> _checkSuggestedTokenIconAvailable(String url) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse(url);
    final request = await client.headUrl(uri);
    request.headers.set('User-Agent', 'IonApp/1.0');
    final response = await request.close();
    return response.statusCode != HttpStatus.notFound;
  } catch (_) {
    return false;
  } finally {
    client.close();
  }
}
