import 'package:flutter_test/flutter_test.dart';
import 'package:hpcustomer/services/order_payload.dart';

void main() {
  group('buildOrderItems', () {
    test('sends the chosen size, add-ons, flavour and note', () {
      final lines = buildOrderItems([
        {
          'id': 'p1',
          'productId': 'p1',
          'name': 'Smoky Breif',
          'variantId': 'v-large',
          'variation': 'Large',
          'flavour': 'Chicken Tikka',
          'instructions': 'less spicy',
          'toppings': [
            {'id': 'a1', 'name': 'Extra Cheese', 'price': 120},
            {'id': 'a2', 'name': 'Olives', 'price': 80},
          ],
          'quantity': 2,
          'price': 1200,
        },
      ]);

      expect(lines, hasLength(1));
      expect(lines.single['productId'], 'p1');
      expect(lines.single['variantId'], 'v-large');
      expect(lines.single['quantity'], 2);
      expect(lines.single['addonIds'], ['a1', 'a2']);
      expect(lines.single['notes'], 'Flavour: Chicken Tikka. Note: less spicy');
      // The app's own price is never sent: the server prices the order.
      expect(lines.single.containsKey('unitPrice'), isFalse);
    });

    test('gives a selected drink its own order line', () {
      final lines = buildOrderItems([
        {
          'productId': 'p1',
          'name': 'Pizza',
          'variantId': 'v1',
          'drinkId': 'd9',
          'drink': 'Coke',
          'quantity': 3,
        },
      ]);

      expect(lines, hasLength(2));
      expect(lines[1]['productId'], 'd9');
      expect(lines[1]['quantity'], 3);
      expect(lines[1]['notes'], 'Drink for Pizza');
    });

    test('omits empty optional fields', () {
      final lines = buildOrderItems([
        {'productId': 'p1', 'name': 'Fries', 'variantId': null, 'flavour': '', 'instructions': '', 'toppings': [], 'quantity': 1},
      ]);

      expect(lines.single, {'productId': 'p1', 'quantity': 1});
    });

    test('falls back to the cart id and skips lines with no product', () {
      final lines = buildOrderItems([
        {'id': 'p7', 'name': 'Burger', 'quantity': 1},
        {'name': 'Ghost item', 'quantity': 1},
      ]);

      expect(lines, hasLength(1));
      expect(lines.single['productId'], 'p7');
    });

    test('ignores add-ons without a usable id', () {
      final lines = buildOrderItems([
        {
          'productId': 'p1',
          'toppings': [
            {'id': 'a1'},
            {'id': ''},
            {'name': 'No id'},
            'text-only',
          ],
          'quantity': 1,
        },
      ]);

      expect(lines.single['addonIds'], ['a1']);
    });
  });
}
