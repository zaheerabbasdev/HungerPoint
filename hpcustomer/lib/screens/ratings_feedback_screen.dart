import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FeedbackItem {
  final String id;
  final String orderId;
  final String date;
  final int rating;
  final String comment;
  final List<String> tags;

  const FeedbackItem({
    required this.id,
    required this.orderId,
    required this.date,
    required this.rating,
    required this.comment,
    required this.tags,
  });
}

class RatingsFeedbackScreen extends StatefulWidget {
  const RatingsFeedbackScreen({super.key});

  @override
  State<RatingsFeedbackScreen> createState() => _RatingsFeedbackScreenState();
}

class _RatingsFeedbackScreenState extends State<RatingsFeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedRating = 5;
  final Set<String> _selectedTags = {'Delicious Food 🍕', 'Fast Delivery ⚡'};

  static const List<String> _availableTags = [
    'Delicious Food 🍕',
    'Fast Delivery ⚡',
    'Hot & Fresh 🔥',
    'Great Packaging 📦',
    'Polite Rider 🛵',
    'Accurate Order 🎯',
  ];

  final List<FeedbackItem> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    final text = _feedbackController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a few words about your experience'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final newFeedback = FeedbackItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderId: 'Order #HP-${DateTime.now().millisecond + 9000}',
      date: 'Today',
      rating: _selectedRating,
      comment: text,
      tags: _selectedTags.toList(),
    );

    setState(() {
      _feedbacks.insert(0, newFeedback);
      _feedbackController.clear();
      _selectedRating = 5;
    });

    // Send review to backend API
    final fullComment = _selectedTags.isNotEmpty ? '$text (${_selectedTags.join(", ")})' : text;
    ApiService.submitReview(rating: _selectedRating, comment: fullComment);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you! Your feedback has been submitted successfully.'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );

    _tabController.animateTo(1);
  }

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
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1B4B),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF5722),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFF5722),
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'GIVE FEEDBACK'),
            Tab(text: 'MY REVIEWS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── 1. GIVE FEEDBACK TAB ──────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Star rating card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'How was your experience?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap the stars to rate your food & delivery',
                        style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 16),

                      // Interactive Star Picker
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
                            : (_selectedRating >= 4
                                ? 'Very Good! ⭐⭐⭐⭐'
                                : (_selectedRating == 3
                                    ? 'Good / Average ⭐⭐⭐'
                                    : 'Needs Improvement')),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Tags selection
                const Text(
                  'What did you like the most?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableTags.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF3ED) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF5722) : const Color(0xFFE5E7EB),
                            width: 1.2,
                          ),
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

                // Written Feedback Box
                const Text(
                  'Write your review',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1E1B4B)),
                    decoration: const InputDecoration(
                      hintText: 'Share your thoughts on food quality, service or delivery...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFDE03),
                      foregroundColor: const Color(0xFF1E1B4B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitFeedback,
                    child: const Text(
                      'SUBMIT FEEDBACK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ─── 2. MY REVIEWS TAB ─────────────────────────────────────
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _feedbacks.length,
            itemBuilder: (context, index) {
              final fb = _feedbacks[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fb.orderId,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          fb.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(5, (starIdx) {
                        return Icon(
                          starIdx < fb.rating ? Icons.star : Icons.star_border,
                          color: starIdx < fb.rating ? const Color(0xFFFFB800) : const Color(0xFFD1D5DB),
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fb.comment,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                    if (fb.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: fb.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3ED),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFFF5722),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
