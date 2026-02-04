import 'dart:async';

import '../providers/user_provider.dart';

class ProductDetails {
  final String id;
  final String title;
  final String description;
  final String price;

  ProductDetails({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });
}

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  List<ProductDetails> _products = [];
  bool _available = false;

  List<ProductDetails> get products => List<ProductDetails>.unmodifiable(_products);
  bool get isAvailable => _available;

  Future<void> initialize(UserProvider userProvider) async {
    // 인앱 결제 비활성화 (Play Store 설정 필요)
    _available = false;
  }

  Future<List<ProductDetails>> loadProducts() async {
    return _products;
  }

  Future<void> buyPremium(ProductDetails product) async {
    // 비활성화
  }

  Future<void> restore() async {
    // 비활성화
  }

  void dispose() {}
}
