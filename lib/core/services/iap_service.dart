import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Play Store / App Store product IDs — create these exact IDs in both consoles.
class IapProducts {
  static const monthly = 'hakkiri_monthly_pro';
  static const annual = 'hakkiri_annual_pro';

  static const all = {monthly, annual};

  static String? tierForProductId(String productId) {
    switch (productId) {
      case monthly:
        return 'monthly_pro';
      case annual:
        return 'annual_pro';
      default:
        return null;
    }
  }

  static String productIdForTier(String tier) {
    if (tier == 'annual_pro') return annual;
    return monthly;
  }
}

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loading = false;
  String? lastError;
  final Map<String, ProductDetails> products = {};

  final _purchaseController = StreamController<PurchaseDetails>.broadcast();
  Stream<PurchaseDetails> get purchaseUpdates => _purchaseController.stream;

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) {
      lastError = 'Store billing is not available on this device.';
      return;
    }
    await _sub?.cancel();
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        lastError = e.toString();
        debugPrint('IapService purchaseStream error: $e');
      },
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!available) {
      available = await _iap.isAvailable();
      if (!available) return;
    }
    loading = true;
    lastError = null;
    try {
      final response = await _iap.queryProductDetails(IapProducts.all);
      products
        ..clear()
        ..addEntries(
          response.productDetails.map((p) => MapEntry(p.id, p)),
        );
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not found: ${response.notFoundIDs}');
        if (products.isEmpty) {
          lastError = 'This plan is not available right now. Please try again later.';
        }
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('IapService.loadProducts error: $e');
    } finally {
      loading = false;
    }
  }

  ProductDetails? productForTier(String tier) {
    return products[IapProducts.productIdForTier(tier)];
  }

  Future<bool> buyTier(String tier) async {
    lastError = null;
    var product = productForTier(tier);
    if (product == null) {
      await loadProducts();
      product = productForTier(tier);
    }
    if (product == null) {
      lastError = lastError ??
          'This plan is not available right now. Please try again later.';
      return false;
    }
    final param = PurchaseParam(productDetails: product);
    // Subscriptions use non-consumable / auto-renewable buy flow.
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    lastError = null;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      lastError = e.toString();
      rethrow;
    }
  }

  Future<void> complete(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _purchaseController.add(p);
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    await _purchaseController.close();
  }
}
