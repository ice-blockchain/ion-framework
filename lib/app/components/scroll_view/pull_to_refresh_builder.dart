// SPDX-License-Identifier: ice License 1.0

import 'dart:io';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ion/app/components/progress_bar/ion_loading_indicator.dart';
import 'package:ion/app/components/scroll_view/ion_pull_to_refresh_loading_indicator.dart';
import 'package:ion/app/extensions/extensions.dart';

class PullToRefreshBuilder extends HookWidget {
  PullToRefreshBuilder({
    required this.slivers,
    required this.onRefresh,
    Widget Function(BuildContext context, List<Widget> slivers)? builder,
    this.refreshIndicatorEdgeOffset = 0,
    this.collapsibleChild,
    super.key,
  }) : builder = builder ??
            ((BuildContext context, List<Widget> slivers) => CustomScrollView(slivers: slivers));

  final Widget Function(BuildContext context, List<Widget> slivers) builder;

  final Widget? collapsibleChild;

  final List<Widget> slivers;

  final Future<void> Function() onRefresh;

  final double refreshIndicatorEdgeOffset;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isIOS) {
      return builder(context, [
        if (collapsibleChild != null) collapsibleChild!,
        CupertinoSliverRefreshControl(
          onRefresh: _onRefresh,
          builder: (_, refreshState, pulledExtent, refreshTriggerPullDistance, ___) =>
              IonPullToRefreshLoadingIndicator(
            refreshState: refreshState,
            pulledExtent: pulledExtent,
            refreshTriggerPullDistance: refreshTriggerPullDistance,
          ),
        ),
        ...slivers,
      ]);
    }

    return CustomMaterialIndicator(
      onRefresh: _onRefresh,
      edgeOffset: refreshIndicatorEdgeOffset,
      indicatorBuilder: (context, controller) {
        return Padding(
          padding: EdgeInsets.all(8.0.s),
          child: IONLoadingIndicatorThemed(
            size: Size.square(20.0.s),
          ),
        );
      },
      child: builder(context, [
        if (collapsibleChild != null) collapsibleChild!,
        ...slivers,
      ]),
    );
  }

  // Add some minimal delay to prevent the refresh indicator from hiding too quickly
  Future<void> _onRefresh() => (onRefresh(), Future<void>.delayed(const Duration(seconds: 1))).wait;
}
