import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../screens/favorites_screen.dart';
import '../screens/explore_tab.dart';
import '../screens/saved_addresses_screen.dart';
import '../services/cart_service.dart';

class SideProfileDrawer extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback? onExploreMenu;

  const SideProfileDrawer({
    super.key,
    required this.onClose,
    this.onExploreMenu,
  });

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(color: AppColors.primaryYellow, shape: BoxShape.circle),
                      child: const Center(child: Text('🍕', style: TextStyle(fontSize: 26))),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_none, color: AppColors.darkNavy, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Zaheer Abbas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkNavy)),
                const Text('+923139804929', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('VIEW PROFILE', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Menu Options
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildDrawerItem(Icons.inventory_2_outlined, 'Order History'),
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
                _buildDrawerItem(Icons.star_outline, 'Ratings & Feedbacks'),
                _buildDrawerItem(Icons.logout, 'Logout'),
              ],
            ),
          ),


          // Bottom Contact Us Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primaryYellow, Colors.orange]),
                borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 8),
        ],
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

