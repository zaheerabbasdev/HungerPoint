import 'package:flutter/foundation.dart';

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

  static const UserProfile _defaultProfile = UserProfile(
    fullName: 'Zaheer Abbas',
    email: 'zabbas092002@gmail.com',
    dateOfBirth: '20-Sep-2002',
    mobileNumber: '+923139804929',
    isVerified: true,
  );

  final ValueNotifier<UserProfile> userProfileNotifier = ValueNotifier<UserProfile>(_defaultProfile);

  UserProfile get profile => userProfileNotifier.value;

  void updateFullName(String name) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(fullName: name);
  }

  void updateEmail(String email) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(email: email);
  }

  void updateDateOfBirth(String dob) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(dateOfBirth: dob);
  }

  void updateMobileNumber(String mobile) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(mobileNumber: mobile);
  }

  void updateProfileImage({String? imagePath, String? avatarEmoji}) {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(
      profileImagePath: imagePath,
      avatarEmoji: avatarEmoji,
    );
  }

  void removeProfileImage() {
    userProfileNotifier.value = userProfileNotifier.value.copyWith(
      clearImage: true,
    );
  }

  void resetToDefault() {
    userProfileNotifier.value = _defaultProfile;
  }
}
