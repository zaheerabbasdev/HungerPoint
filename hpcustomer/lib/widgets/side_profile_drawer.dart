import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/favorites_screen.dart';
import '../screens/explore_tab.dart';
import '../screens/saved_addresses_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ratings_feedback_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/cart_service.dart';
import '../services/profile_service.dart';
import '../services/favorites_service.dart';

class SideProfileDrawer extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onExploreMenu;

  const SideProfileDrawer({
    super.key,
    required this.onClose,
    this.onExploreMenu,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Color(0xFFFF5722), size: 24),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1B4B),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your HungerPoint account?',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ProfileService().resetToDefault();
              CartService().clearCart();
              FavoritesService().clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5722),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            color: const Color(0xFFFAFAFA),
            child: ValueListenableBuilder<UserProfile>(
              valueListenable: ProfileService().userProfileNotifier,
              builder: (context, profile, _) {
                final hasFileImage = profile.profileImagePath != null && File(profile.profileImagePath!).existsSync();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            image: hasFileImage
                                ? DecorationImage(
                                    image: FileImage(File(profile.profileImagePath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: hasFileImage
                              ? null
                              : Center(
                                  child: Text(
                                    profile.avatarEmoji ?? '🍕',
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_none, color: AppColors.darkNavy, size: 20),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 8.5,
                                  height: 8.5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF5722),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.fullName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                    ),
                    Text(
                      profile.mobileNumber,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('VIEW PROFILE', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Drawer Menu Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(
                  Icons.inventory_2_outlined,
                  'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.favorite_border,
                  'My Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavoritesScreen(
                          onAddToCart: (item) => CartService().addItem(item),
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.grid_view_outlined,
                  'Explore Menu',
                  onTap: () {
                    Navigator.pop(context);
                    if (onExploreMenu != null) {
                      onExploreMenu!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExploreMenuScreen(
                            onAddToCart: (item) => CartService().addItem(item),
                            cart: CartService().items,
                            initialCategoryIndex: 0,
                          ),
                        ),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  Icons.location_on_outlined,
                  'Saved Addresses',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavedAddressesScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.star_outline,
                  'Ratings & Feedbacks',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RatingsFeedbackScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.logout,
                  'Logout',
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),


          // Bottom Contact Us Card (Elevated upward)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 26.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showContactUsSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primaryYellow, Colors.orange]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Text('🍕', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Text('CONTACT US', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                      Spacer(),
                      Icon(Icons.phone, color: AppColors.primaryOrange),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactUsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Contact HungerPoint',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'We are here to assist you 24/7',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3ED),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: AppColors.primaryOrange, size: 20),
                ),
                title: const Text('Helpline / Call Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('111-486-437 (+92 51 111-HUNGER)', style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dialing HungerPoint Helpline (111-486-437)...')),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32), size: 20),
                ),
                title: const Text('WhatsApp Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Chat with our support team', style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening WhatsApp Support...')),
                  );
                },
              ),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.email_outlined, color: Color(0xFF1E1B4B), size: 20),
                ),
                title: const Text('Email Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('support@hungerpoint.com', style: TextStyle(fontSize: 13)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support email: support@hungerpoint.com')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.darkNavy, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNavy)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}

