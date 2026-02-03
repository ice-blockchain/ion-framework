// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';
import 'package:webview_flutter/webview_flutter.dart' as wf;

class WebView extends StatefulHookConsumerWidget {
  const WebView({required this.url, super.key});

  final String url;

  @override
  ConsumerState<WebView> createState() => _WebViewState();
}

class _WebViewState extends ConsumerState<WebView> {
  late final wf.WebViewController controller;
  bool _isLoadingPage = false;

  @override
  void initState() {
    super.initState();
    _isLoadingPage = true;
    controller = wf.WebViewController()
      ..setNavigationDelegate(
        wf.NavigationDelegate(
          onPageStarted: (_) => _setLoading(true),
          onPageFinished: (_) => _setLoading(false),
          onWebResourceError: (_) => _setLoading(false),
        ),
      )
      ..loadRequest(
        Uri.parse(widget.url),
      );
  }

  void _setLoading(bool value) {
    if (mounted && _isLoadingPage != value) {
      setState(() => _isLoadingPage = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        wf.WebViewWidget(
          controller: controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{
            Factory<VerticalDragGestureRecognizer>(VerticalDragGestureRecognizer.new),
            Factory<HorizontalDragGestureRecognizer>(HorizontalDragGestureRecognizer.new),
            Factory<PanGestureRecognizer>(PanGestureRecognizer.new),
          },
        ),
        if (_isLoadingPage)
          Center(
            child: IONLoadingIndicator(
              type: IndicatorType.dark,
              size: Size.square(30.0.s),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
