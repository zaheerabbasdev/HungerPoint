import 'package:flutter/foundation.dart';

class UserProfile {
  final String fullName;
  final String email;
  final String dateOfBirth;
  final String mobileNumber;
  final bool isVerified;

  const UserProfile({
    required this.fullName,
    required this.email,
    required this.dateOfBirth,
    required this.mobileNumber,
    this.isVerified = true,
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? dateOfBirth,
    String? mobileNumber,
    bool? isVerified,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ValueNotifier<UserProfile> userProfileNotifier = ValueNotifier<UserProfile>(
    const UserProfile(
      fullName: 'Zaheer Abbas',
      email: 'zabbas092002@gmail.com',
      dateOfBirth: '20-Sep-2002',
      mobileNumber: '+923139804929',
      isVerified: true,
    ),
  );

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
}
