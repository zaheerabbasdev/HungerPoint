// Turns the cart into the order lines the backend understands.
//
// The server prices an order itself: product base price + the chosen size's
// offset + each add-on, per unit. So the lines must carry the real size
// (`variantId`) and add-on ids — anything else is invisible to the kitchen and
// is not charged. Flavour and the customer's note travel in `notes`.

String composeItemNotes(Map<String, dynamic> item) {
  final parts = <String>[];
  final flavour = item['flavour']?.toString() ?? '';
  final instructions = item['instructions']?.toString() ?? '';
  if (flavour.isNotEmpty) parts.add('Flavour: $flavour');
  if (instructions.isNotEmpty) parts.add('Note: $instructions');
  return parts.join('. ');
}

List<Map<String, dynamic>> buildOrderItems(List<Map<String, dynamic>> cartItems) {
  final lines = <Map<String, dynamic>>[];

  for (final item in cartItems) {
    final quantity = (item['quantity'] as int?) ?? 1;
    final productId = (item['productId'] ?? item['id'])?.toString();
    if (productId == null || productId.isEmpty) continue;

    final addonIds = ((item['toppings'] as List?) ?? const [])
        .map((t) => t is Map ? t['id']?.toString() : null)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final notes = composeItemNotes(item);
    final variantId = item['variantId']?.toString();

    lines.add({
      'productId': productId,
      if (variantId != null && variantId.isNotEmpty) 'variantId': variantId,
      'quantity': quantity,
      if (addonIds.isNotEmpty) 'addonIds': addonIds,
      if (notes.isNotEmpty) 'notes': notes,
    });

    // A chosen drink is a real, separately priced product: give it its own
    // line so it is charged and shown on the kitchen ticket.
    final drinkId = item['drinkId']?.toString();
    if (drinkId != null && drinkId.isNotEmpty) {
      lines.add({
        'productId': drinkId,
        'quantity': quantity,
        'notes': 'Drink for ${item['name']}',
      });
    }
  }

  return lines;
}
