import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String dateOfBirth;
  final String mobileNumber;
  final bool isVerified;
  final String? profileImagePath;
  final String? avatarEmoji;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.dateOfBirth,
    required this.mobileNumber,
    this.isVerified = true,
    this.profileImagePath,
    this.avatarEmoji,
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? dateOfBirth,
    String? mobileNumber,
    bool? isVerified,
    String? profileImagePath,
    String? avatarEmoji,
    bool clearImage = false,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isVerified: isVerified ?? this.isVerified,
      profileImagePath: clearImage ? null : (profileImagePath ?? this.profileImagePath),
      avatarEmoji: clearImage ? null : (avatarEmoji ?? this.avatarEmoji),
    );
  }
}

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  static const UserProfile _guestProfile = UserProfile(
    fullName: 'Guest User',
    email: '',
    dateOfBirth: '',
    mobileNumber: '',
    isVerified: false,
  );

  final ValueNotifier<UserProfile> userProfileNotifier = ValueNotifier<UserProfile>(_guestProfile);

  UserProfile get profile => userProfileNotifier.value;

  /// Updates profile directly with verified backend user data
  void setUserFromBackend(Map<String, dynamic> user, [Map<String, dynamic>? customer]) {
    final String name = user['name']?.toString() ?? (profile.fullName.isNotEmpty ? profile.fullName : 'Customer');
    final String phone = user['phone']?.toString() ?? profile.mobileNumber;
    final String email = user['email']?.toString() ?? customer?['email']?.toString() ?? profile.email;
    final String dob = customer?['dateOfBirth']?.toString() ?? profile.dateOfBirth;
    final String? avatar = customer?['avatarEmoji']?.toString() ?? profile.avatarEmoji;

    userProfileNotifier.value = userProfileNotifier.value.copyWith(
      fullName: name,
      email: email,
      mobileNumber: phone,
      dateOfBirth: dob,
      avatarEmoji: avatar,
      isVerified: true,
    );
  }

  /// Syncs customer profile with backend
  Future<void> syncWithBackend() async {
    try {
      if (!ApiService.isLoggedIn) {
        // If ApiService has currentUser from saved session, load it
        if (ApiService.currentUser != null) {
          setUserFromBackend(ApiService.currentUser!);
        }
        return;
      }

      final profileData = await ApiService.getCustomerProfile();
      if (profileData != null) {
        userProfileNotifier.value = userProfileNotifier.value.copyWith(
          fullName: profileData['name'] ?? profileData['fullName'] ?? userProfileNotifier.value.fullName,
          email: profileData['email'] ?? userProfileNotifier.value.email,
          mobileNumber: profileData['phone'] ?? profileData['mobileNumber'] ?? userProfileNotifier.value.mobileNumber,
          dateOfBirth: profileData['dateOfBirth'] ?? userProfileNotifier.value.dateOfBirth,
          avatarEmoji: profileData['avatarEmoji'] ?? userProfileNotifier.value.avatarEmoji,
          profileImagePath: profileData['profileImage'] ?? userProfileNotifier.value.profileImagePath,
          isVerified: true,
        );
      } else if (ApiService.currentUser != null) {
        setUserFromBackend(ApiService.currentUser!);
      }
    } catch (e) {
      debugPrint('Error syncing profile with backend: $e');
    }
  }

  void updateFullName(String name) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(fullName: name);
    ApiService.updateCustomerProfile(fullName: name);
  }

  void updateEmail(String email) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(email: email);
    ApiService.updateCustomerProfile(email: email);
  }

  void updateDateOfBirth(String dob) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(dateOfBirth: dob);
    ApiService.updateCustomerProfile(dateOfBirth: dob);
  }

  void updateMobileNumber(String mobile) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(mobileNumber: mobile);
  }

  void updateProfileImage({String? imagePath, String? avatarEmoji}) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(
      profileImagePath: imagePath,
      avatarEmoji: avatarEmoji,
    );
    if (avatarEmoji != null) {
      ApiService.updateCustomerProfile(avatarEmoji: avatarEmoji);
    }
  }

  /// Shows the picked file immediately (optimistic UI), then uploads it to the
  /// backend and persists the resulting remote URL to the customer profile.
  /// Returns true if the remote upload+save succeeded.
  Future<bool> uploadAndSetProfileImage(File file) async {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(
      profileImagePath: file.path,
      clearImage: false,
    );

    final url = await ApiService.uploadImage(file);
    if (url == null) return false;

    final saved = await ApiService.updateCustomerProfile(profileImagePath: url);
    if (saved) {
      userProfileNotifier.value = userProfileNotifier.value.copyWith(
        profileImagePath: url,
      );
    }
    return saved;
  }

  void removeProfileImage() {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(
      clearImage: true,
    );
    ApiService.updateCustomerProfile(profileImagePath: '');
  }

  /// Deactivates the account on the backend, then clears local session state.
  Future<bool> deleteAccount() async {
    final ok = await ApiService.deleteAccount();
    if (ok) {
      resetToDefault();
    }
    return ok;
  }

  void resetToDefault() {
    userProfileNotifier.value = _guestProfile;
    ApiService.logout();
  }
}
