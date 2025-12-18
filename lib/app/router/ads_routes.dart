// SPDX-License-Identifier: ice License 1.0

part of 'app_routes.gr.dart';

class AdsRoutes {
  static const routes = <TypedRoute<RouteData>>[
    TypedShellRoute<ModalShellRouteData>(
      routes: [
        TypedGoRoute<AdsModalRoute>(path: 'ads-modal'),
      ],
    ),
  ];
}

@TypedGoRoute<AdsBenefitsRoute>(
  path: '/ads-benefits',
)
class AdsBenefitsRoute extends BaseRouteData with _$AdsBenefitsRoute {
  AdsBenefitsRoute()
      : super(
          child: const AdsBenefitsPage(),
          type: IceRouteType.single,
        );
}

class AdsModalRoute extends BaseRouteData with _$AdsModalRoute {
  AdsModalRoute()
      : super(
          child: const AdsModalPage(),
          type: IceRouteType.bottomSheet,
        );
}
