import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'edit_profile_field_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E1B4B),
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion request submitted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: ValueListenableBuilder<UserProfile>(
        valueListenable: ProfileService().userProfileNotifier,
        builder: (context, profile, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ─── TOP BANNER & OVERLAPPING AVATAR ───────────────────
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Restaurant Aerial Banner Image
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1B4B),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF2C1810), Color(0xFF1A1A1A)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                          // Dark overlay for text readability
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                          // Top AppBar inside banner
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Centered Overlapping Avatar (Image 1)
                    Positioned(
                      top: 220 - 55, // Center avatar halfway over banner edge
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD1D5DB),
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 68,
                              ),
                            ),

                            // Camera badge icon (Image 1)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5722),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 70),

                // ─── PROFILE DETAILS CARDS ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Full Name Card
                      _buildProfileCard(
                        title: 'Full Name',
                        value: profile.fullName,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileFieldScreen(
                                fieldType: ProfileFieldType.fullName,
                                initialValue: profile.fullName,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Email Card
                      _buildProfileCard(
                        title: 'Email',
                        value: profile.email,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileFieldScreen(
                                fieldType: ProfileFieldType.email,
                                initialValue: profile.email,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Date Of Birth Card
                      _buildProfileCard(
                        title: 'Date Of Birth',
                        value: profile.dateOfBirth,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileFieldScreen(
                                fieldType: ProfileFieldType.dateOfBirth,
                                initialValue: profile.dateOfBirth,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Mobile Number Card with VERIFIED Badge
                      _buildProfileCard(
                        title: 'Mobile Number',
                        value: profile.mobileNumber,
                        isVerified: profile.isVerified,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfileFieldScreen(
                                fieldType: ProfileFieldType.mobileNumber,
                                initialValue: profile.mobileNumber,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // ─── DELETE MY ACCOUNT BUTTON ───────────────────
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showDeleteAccountDialog(context),
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFF5722),
                              width: 1.8,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'DELETE MY ACCOUNT',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF5722),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String value,
    required VoidCallback onEdit,
    bool isVerified = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 2),
                  child: Text(
                    'EDIT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF5722),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E1B4B),
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDE03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'VERIFIED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
