// SPDX-License-Identifier: ice License 1.0

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ion/app/services/iap/boost_post_products.dart';

/// Service for handling in-app purchases for boost post feature
class IAPService {
  factory IAPService() => _instance;
  IAPService._internal();

  static final IAPService _instance = IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;

  /// All boost product IDs (35 total: 5 budgets × 7 durations)
  final Set<String> _productIds = BoostPostProducts.generateAllProductIds();

  Map<String, ProductDetails> _products = {};
  final StreamController<PurchaseDetails> _purchaseController =
      StreamController<PurchaseDetails>.broadcast();

  /// Stream of purchase updates
  Stream<PurchaseDetails> get purchaseStream => _purchaseController.stream;

  /// Map of available products (productId -> ProductDetails)
  Map<String, ProductDetails> get products => Map.unmodifiable(_products);

  /// Whether the store is available
  bool get isAvailable => _isAvailable;

  /// Get all product IDs
  Set<String> get productIds => Set.unmodifiable(_productIds);

  /// Initialize IAP service
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();

    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () {
        debugPrint('IAP: Purchase stream closed');
        _subscription?.cancel();
      },
      onError: (Object error) {
        debugPrint('IAP: Purchase stream error: $error');
      },
    );

    // Load products
    await loadProducts();
  }

  /// Load product details from store
  Future<void> loadProducts() async {
    if (!_isAvailable) {
      debugPrint('IAP: Cannot load products - store not available');
      return;
    }

    final response = await _iap.queryProductDetails(_productIds);

    if (response.error != null) {
      debugPrint('IAP: Error loading products: ${response.error}');
      return;
    }

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP: Products not found: ${response.notFoundIDs}');
    }

    _products = {
      for (final product in response.productDetails) product.id: product,
    };

    debugPrint('IAP: Loaded ${_products.length}/${_productIds.length} products');
  }

  /// Get product details for a specific product ID
  ProductDetails? getProduct(String productId) {
    return _products[productId];
  }

  /// Get product ID from budget and duration
  String getProductId(double budget, int duration) {
    return BoostPostProducts.getProductId(budget.toInt(), duration);
  }

  /// Purchase a product
  /// Returns true if purchase was initiated successfully
  Future<bool> purchaseProduct(String productId) async {
    if (!_isAvailable) {
      debugPrint('IAP: Store not available');
      return false;
    }

    final product = _products[productId];
    if (product == null) {
      debugPrint('IAP: Product not found: $productId');
      return false;
    }

    final purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      // Use consumable for Android, non-consumable for iOS
      // Note: For consumables, we use buyConsumable on Android
      // For iOS, consumables are handled the same way
      if (Platform.isAndroid) {
        final success = await _iap.buyConsumable(purchaseParam: purchaseParam);
        return success;
      } else {
        // iOS: buyNonConsumable works for consumables too
        // The product type is defined in App Store Connect
        final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
        return success;
      }
    } catch (e) {
      debugPrint('IAP: Purchase error: $e');
      return false;
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      debugPrint('IAP: Purchase update - ${purchase.productID}: ${purchase.status}');

      if (purchase.status == PurchaseStatus.pending) {
        debugPrint('IAP: Purchase pending: ${purchase.productID}');
        _purchaseController.add(purchase);
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        debugPrint('IAP: Purchase successful: ${purchase.productID}');
        _purchaseController.add(purchase);
        // Complete the purchase after handling
        _completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('IAP: Purchase error: ${purchase.error?.message} (${purchase.error?.code})');
        _purchaseController.add(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        debugPrint('IAP: Purchase canceled: ${purchase.productID}');
        _purchaseController.add(purchase);
      }
    }
  }

  /// Complete a purchase (verify receipt and deliver product)
  /// This should be called after you've verified the receipt on your backend
  Future<void> _completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      try {
        await _iap.completePurchase(purchase);
        debugPrint('IAP: Purchase completed: ${purchase.productID}');
      } catch (e) {
        debugPrint('IAP: Error completing purchase: $e');
      }
    }
  }

  /// Manually complete a purchase (call this after backend verification)
  Future<void> completePurchase(PurchaseDetails purchase) async {
    await _completePurchase(purchase);
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      debugPrint('IAP: Cannot restore - store not available');
      return;
    }

    try {
      await _iap.restorePurchases();
      debugPrint('IAP: Restore purchases initiated');
    } catch (e) {
      debugPrint('IAP: Error restoring purchases: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _purchaseController.close();
    debugPrint('IAP: Service disposed');
  }
}
