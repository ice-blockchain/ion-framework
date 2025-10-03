// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/url_preview/providers/url_metadata_provider.r.dart';
import 'package:ion/app/hooks/use_on_init.dart';
import 'package:ion/app/utils/url.dart';
import 'package:ion/app/utils/validators.dart';
import 'package:ogp_data_extract/ogp_data_extract.dart';

class UrlPreview extends HookConsumerWidget {
  const UrlPreview({
    required this.url,
    required this.builder,
    this.metaListener,
    super.key,
  });

  final String url;
  final Widget Function(OgpData? meta, String? favIconUrl) builder;
  final void Function(OgpData? meta)? metaListener;

  String? _resolveFavIconUrl(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.scheme.isEmpty) {
      return null;
    }
    return '${uri.origin}/favicon.ico';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Validators.isInvalidUrl(url)) {
      return builder(null, null);
    }
    final normalizedUrl = useMemoized(() {
      final normalizedUrl = normalizeUrl(url);
      if (isNetworkUrl(normalizedUrl)) {
        return normalizedUrl;
      }
      return null;
    });

    if (normalizedUrl == null) {
      return builder(null, null);
    }

    useOnInit(() {
      if (!context.mounted) {
        return;
      }
      final urlMetadata = ref.read(urlMetadataProvider(normalizedUrl));
      if (urlMetadata.valueOrNull != null && !urlMetadata.isLoading) {
        metaListener?.call(urlMetadata.valueOrNull);
      }
    });

    final favIconUrl = _resolveFavIconUrl(normalizedUrl);

    if (!context.mounted) {
      return builder(null, null);
    }

    final metadataAsync = ref.watch(urlMetadataProvider(normalizedUrl));
    ref.listen(urlMetadataProvider(normalizedUrl), (_, next) {
      metaListener?.call(next.valueOrNull);
    });

    if (metadataAsync.isLoading || metadataAsync.hasError) {
      return builder(null, null);
    }

    return builder(metadataAsync.valueOrNull, favIconUrl);
  }
}
