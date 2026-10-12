import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Reviews are tied to a delivered order. Open it from an order ("Rate this order") with
/// [orderId] set, or from the menu to pick one of your delivered orders that is not yet reviewed.
class RatingsFeedbackScreen extends StatefulWidget {
  final String? orderId;
  final String? orderNumber;

  const RatingsFeedbackScreen({super.key, this.orderId, this.orderNumber});

  @override
  State<RatingsFeedbackScreen> createState() => _RatingsFeedbackScreenState();
}

class _RatingsFeedbackScreenState extends State<RatingsFeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRating = 5;
  final Set<String> _selectedTags = {};

  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _reviewable = [];
  List<Map<String, dynamic>> _myReviews = [];
  String? _selectedOrderId;
  bool _alreadyReviewed = false;

  static const List<String> _availableTags = [
    'Delicious Food 🍕',
    'Fast Delivery ⚡',
    'Hot & Fresh 🔥',
    'Great Packaging 📦',
    'Polite Rider 🛵',
    'Accurate Order 🎯',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedOrderId = widget.orderId;
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final reviews = await ApiService.getMyReviews();
    final orders = await ApiService.getMyOrders();
    if (!mounted) return;

    final reviewedOrderIds = reviews.map((r) => r['orderId']?.toString()).toSet();
    final reviewable = <Map<String, dynamic>>[];
    for (final o in orders) {
      final status = o['status']?.toString();
      final id = o['id']?.toString();
      if ((status == 'DELIVERED' || status == 'COMPLETED') && id != null && !reviewedOrderIds.contains(id)) {
        reviewable.add(Map<String, dynamic>.from(o as Map));
      }
    }

    setState(() {
      _myReviews = reviews.map((r) => Map<String, dynamic>.from(r as Map)).toList();
      _reviewable = reviewable;
      _alreadyReviewed = widget.orderId != null && reviewedOrderIds.contains(widget.orderId);
      final stillValid = _selectedOrderId != null && reviewable.any((o) => o['id']?.toString() == _selectedOrderId);
      if (!stillValid) _selectedOrderId = reviewable.isNotEmpty ? reviewable.first['id']?.toString() : null;
      _loading = false;
    });
  }

  Future<void> _submitFeedback() async {
    if (_submitting) return;
    final orderId = _selectedOrderId;
    if (orderId == null) {
      _snack('Choose the order you want to review.', error: true);
      return;
    }

    final text = _feedbackController.text.trim();
    final tags = _selectedTags.join(', ');
    final comment = [text, if (tags.isNotEmpty) '($tags)'].join(' ').trim();

    setState(() => _submitting = true);
    final result = await ApiService.submitReview(orderId: orderId, rating: _selectedRating, comment: comment);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      _feedbackController.clear();
      _selectedTags.clear();
      _selectedRating = 5;
      _snack('Thank you! Your review was submitted.');
      await _loadAll();
      if (mounted) _tabController.animateTo(1);
    } else {
      _snack(result['message']?.toString() ?? 'Could not submit your review. Please try again.', error: true);
      // e.g. "already reviewed": refresh so the list matches the server.
      await _loadAll();
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _orderLabel(Map<String, dynamic> o) {
    final created = o['createdAt']?.toString() ?? '';
    final date = created.length >= 10 ? created.substring(0, 10) : '';
    final total = num.tryParse(o['total']?.toString() ?? '')?.toStringAsFixed(0) ?? '';
    return '#${o['orderNumber'] ?? o['id']}${date.isEmpty ? '' : '  ·  $date'}${total.isEmpty ? '' : '  ·  PKR $total'}';
  }

  BoxDecoration get _card => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E1B4B), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          'Ratings & Feedback',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF5722),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFF5722),
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            const Tab(text: 'GIVE FEEDBACK'),
            Tab(text: _myReviews.isEmpty ? 'MY REVIEWS' : 'MY REVIEWS (${_myReviews.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD600))))
          : TabBarView(
              controller: _tabController,
              children: [_buildGiveFeedbackTab(), _buildMyReviewsTab()],
            ),
    );
  }

  // ─── 1. GIVE FEEDBACK TAB ──────────────────────────────────────
  Widget _buildGiveFeedbackTab() {
    if (_reviewable.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.rate_review_outlined, size: 56, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 14),
          Text(
            _alreadyReviewed ? 'You already reviewed this order' : 'No orders to review yet',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 8),
          Text(
            _alreadyReviewed
                ? 'Thank you for your feedback. You can see it under MY REVIEWS.'
                : 'Once an order has been delivered you can rate it here.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which order
          const Text('Which order?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
          const SizedBox(height: 8),
          for (final o in _reviewable)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedOrderId = o['id']?.toString()),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: o['id']?.toString() == _selectedOrderId ? const Color(0xFFFFF3ED) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: o['id']?.toString() == _selectedOrderId ? const Color(0xFFFF5722) : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      o['id']?.toString() == _selectedOrderId ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 20,
                      color: o['id']?.toString() == _selectedOrderId ? const Color(0xFFFF5722) : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _orderLabel(o),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),

          // Star rating card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: _card,
            child: Column(
              children: [
                const Text('How was your experience?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 6),
                const Text('Tap the stars to rate your food & delivery',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final isFilled = starIndex <= _selectedRating;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _selectedRating = starIndex),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          isFilled ? Icons.star : Icons.star_border,
                          color: isFilled ? const Color(0xFFFFB800) : const Color(0xFFD1D5DB),
                          size: 38,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedRating == 5
                      ? 'Excellent! Loved it! ⭐⭐⭐⭐⭐'
                      : (_selectedRating == 4
                          ? 'Very Good! ⭐⭐⭐⭐'
                          : (_selectedRating == 3 ? 'Good / Average ⭐⭐⭐' : 'Needs Improvement')),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFFF5722)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text('What did you like the most?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF3ED) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE5E7EB), width: 1.2),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF4B5563),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          const Text('Write your review (optional)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF3F4F6)),
            ),
            child: TextField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: 800,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E1B4B)),
              decoration: const InputDecoration(
                hintText: 'Share your thoughts on food quality, service or delivery...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDE03),
                foregroundColor: const Color(0xFF1E1B4B),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting ? null : _submitFeedback,
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E1B4B)))
                  : const Text('SUBMIT REVIEW', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── 2. MY REVIEWS TAB ─────────────────────────────────────────
  Widget _buildMyReviewsTab() {
    if (_myReviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(Icons.star_border_rounded, size: 56, color: Color(0xFF9CA3AF)),
            SizedBox(height: 14),
            Text(
              "You haven't reviewed any orders yet",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        itemCount: _myReviews.length,
        itemBuilder: (context, index) {
          final r = _myReviews[index];
          final rating = (num.tryParse(r['rating']?.toString() ?? '') ?? 0).toInt();
          final created = r['createdAt']?.toString() ?? '';
          final date = created.length >= 10 ? created.substring(0, 10) : '';
          final comment = r['comment']?.toString() ?? '';
          final orderNumber = (r['order'] as Map?)?['orderNumber'];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: _card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order #${orderNumber ?? ''}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B))),
                    Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: i < rating ? const Color(0xFFFFB800) : const Color(0xFFD1D5DB),
                      size: 18,
                    );
                  }),
                ),
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(comment, style: const TextStyle(fontSize: 13.5, color: Color(0xFF4B5563), height: 1.4)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
