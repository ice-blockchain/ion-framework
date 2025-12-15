import 'package:ion_ads/ion_ads.dart';

/// Represents ad revenue details from Appodeal SDK.
class AppodealAdRevenue {
  /// Constructs an [AppodealAdRevenue] object from a dynamic argument map.
  ///
  /// Throws an [ArgumentError] if required fields are missing or have invalid types.
  AppodealAdRevenue.fromArgs(dynamic arguments)
      : adType = AppodealAdType.byPlatformType(arguments['adType'] as int),
        networkName = arguments['networkName'] as String,
        demandSource = arguments['demandSource'] as String,
        adUnitName = arguments['adUnitName'] as String,
        placement = arguments['placement'] as String,
        revenue = (arguments['revenue'] as num).toDouble(),
        currency = arguments['currency'] as String,
        revenuePrecision = arguments['revenuePrecision'] as String;

  /// The type of the ad (e.g., banner, interstitial, rewarded video).
  final AppodealAdType adType;

  /// The name of the advertising network (e.g., Google, Facebook).
  final String networkName;

  /// The specific demand source for the ad.
  final String demandSource;

  /// The name of the ad unit.
  final String adUnitName;

  /// The placement identifier for the ad.
  final String placement;

  /// The revenue generated from the ad.
  final double revenue;

  /// The currency of the revenue (e.g., USD, EUR).
  final String currency;

  /// The precision of the revenue value (e.g., "exact" or "estimated").
  final String revenuePrecision;

  /// Converts the [AppodealAdRevenue] object to a `Map` for serialization.
  Map<String, dynamic> get toMap => <String, dynamic>{
        'adType': adType.platformType,
        'networkName': networkName,
        'demandSource': demandSource,
        'adUnitName': adUnitName,
        'placement': placement,
        'revenue': revenue,
        'currency': currency,
        'revenuePrecision': revenuePrecision,
      };

  @override
  String toString() {
    return 'AppodealAdRevenue('
        'adType: $adType, '
        'networkName: $networkName, '
        'demandSource: $demandSource, '
        'adUnitName: $adUnitName, '
        'placement: $placement, '
        'revenue: $revenue, '
        'currency: $currency, '
        'revenuePrecision: $revenuePrecision)';
  }
}
