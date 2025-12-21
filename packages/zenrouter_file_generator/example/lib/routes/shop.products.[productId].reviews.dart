import 'package:flutter/material.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

import 'routes.zen.dart';

part 'shop.products.[productId].reviews.g.dart';

/// Example of nested route using dot notation.
///
/// URL: /shop/products/:productId/reviews
///
/// Equivalent to: shop/products/[productId]/reviews.dart
@ZenRoute()
class ShopProductsProductIdReviewsRoute
    extends _$ShopProductsProductIdReviewsRoute {
  ShopProductsProductIdReviewsRoute({required super.productId});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reviews for Product $productId')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.star, color: Colors.amber),
            title: const Text('Great product!'),
            subtitle: Text('Product ID: $productId'),
          ),
          const ListTile(
            leading: Icon(Icons.star, color: Colors.amber),
            title: Text('Highly recommended'),
            subtitle: Text('5 stars'),
          ),
          const ListTile(
            leading: Icon(Icons.star_half, color: Colors.amber),
            title: Text('Good but could be better'),
            subtitle: Text('3.5 stars'),
          ),
        ],
      ),
    );
  }
}
