import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../providers/user_provider.dart';

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  static const Set<String> _productIds = {'premium_monthly'};

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _available = false;

  List<ProductDetails> get products => List<ProductDetails>.unmodifiable(_products);
  bool get isAvailable => _available;

  Future<void> initialize(UserProvider userProvider) async {
    _available = await _inAppPurchase.isAvailable();
    if (!_available) {
      return;
    }
    await loadProducts();
    _subscription ??= _inAppPurchase.purchaseStream.listen(
      (purchases) => _handlePurchases(purchases, userProvider),
      onDone: () => _subscription?.cancel(),
    );
  }

  Future<List<ProductDetails>> loadProducts() async {
    if (!_available) {
      return _products;
    }
    final response = await _inAppPurchase.queryProductDetails(_productIds);
    _products = response.productDetails;
    return _products;
  }

  Future<void> buyPremium(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restore() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _handlePurchases(
    List<PurchaseDetails> purchases,
    UserProvider userProvider,
  ) async {
    var hasPremium = userProvider.isPremium;
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        hasPremium = true;
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
    userProvider.setPremium(hasPremium);
  }
}
