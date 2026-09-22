import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/table_cart_service.dart';
import 'item_detail_screen.dart';
import 'cart_review_screen.dart';

class MenuScreen extends StatefulWidget {
  final Map<String, dynamic> table;

  const MenuScreen({super.key, required this.table});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedCategoryId;

  String get _tableId => widget.table['id'].toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cats = await ApiService.fetchCategories();
    final prods = await ApiService.fetchProducts();
    if (!mounted) return;
    setState(() {
      _categories = cats.map((c) => Map<String, dynamic>.from(c)).toList();
      _products = prods.map((p) => Map<String, dynamic>.from(p)).toList();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategoryId == null) return _products;
    return _products.where((p) => p['categoryId']?.toString() == _selectedCategoryId).toList();
  }

  void _addToCart(Map<String, dynamic> cartItem) {
    TableCartService().addItem(_tableId, cartItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
            Text('Table ${widget.table['number']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => CartReviewScreen(table: widget.table)));
                  if (mounted) setState(() {});
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: TableCartService().version,
                    builder: (context, _, _) {
                      final count = TableCartService().totalItemCountFor(_tableId);
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.receipt_long_outlined, color: AppColors.darkNavy, size: 20),
                          if (count > 0)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: AppColors.primaryOrange, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1.0)),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : Column(
              children: [
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      children: [
                        _buildCategoryChip('All', null),
                        ..._categories.map((c) => _buildCategoryChip(c['name'] ?? '', c['id']?.toString())),
                      ],
                    ),
                  ),
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? const Center(child: Text('No items in this category.', style: TextStyle(color: AppColors.textMuted)))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) => _buildProductCard(_filteredProducts[index]),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: TableCartService().version,
        builder: (context, _, _) {
          final count = TableCartService().totalItemCountFor(_tableId);
          if (count == 0) return const SizedBox.shrink();
          final total = TableCartService().totalPriceFor(_tableId);
          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => CartReviewScreen(table: widget.table)));
                    if (mounted) setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryYellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: Text('View Order — $count item${count == 1 ? '' : 's'} · PKR $total',
                      style: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? id) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategoryId = id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryYellow : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primaryYellow : AppColors.cardBorder),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final price = product['basePrice'];
    return GestureDetector(
      onTap: () {
        final item = {
          'id': product['id'],
          'name': product['name'],
          'desc': product['description'],
          'image': product['image'],
          'price': price is num ? price.toInt() : 0,
          'category': product['category']?['name'],
          'variants': product['variants'],
          'flavours': product['flavours'],
          'addons': product['addons'],
        };
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item, table: widget.table, onAddToCart: _addToCart)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF9FAFB),
                child: Image.network(
                  ApiService.resolveImageUrl(product['image']?.toString()),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.fastfood, size: 36, color: Colors.grey)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNavy),
                  ),
                  const SizedBox(height: 4),
                  Text('PKR ${price is num ? price.toInt() : price}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
