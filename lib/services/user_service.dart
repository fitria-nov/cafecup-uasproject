import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import '../models/user_model.dart';
import 'pocketbase_service.dart';

class UserService {
  final PocketBaseService _pbService;

  UserService(this._pbService);

  // Get current user as UserModel - STRING PARSING VERSION (SIMPLIFIED)
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _pbService.currentUser;

      if (user == null) {
        print('❌ No current user found');
        return null;
      }

      print('🔍 Raw user object: $user');

      // EXTRACT FROM STRING REPRESENTATION
      String userString = user.toString();
      print('🔍 User string representation: $userString');

      // Extract data using string parsing
      String userId = '';
      String userEmail = '';
      String userName = '';
      String? userType;
      String? phone;
      String? address;
      String? avatar;
      bool emailVisibility = true;
      bool verified = false;

      // Extract ID
      final idRegex = RegExp(r'"id":"([^"]+)"');
      final idMatch = idRegex.firstMatch(userString);
      if (idMatch != null && idMatch.groupCount >= 1) {
        userId = idMatch.group(1) ?? '';
        print('✅ Extracted ID: $userId');
      }

      // Extract email
      final emailRegex = RegExp(r'"email":"([^"]+)"');
      final emailMatch = emailRegex.firstMatch(userString);
      if (emailMatch != null && emailMatch.groupCount >= 1) {
        userEmail = emailMatch.group(1) ?? '';
        print('✅ Extracted email: $userEmail');
      }

      // Extract name
      final nameRegex = RegExp(r'"name":"([^"]+)"');
      final nameMatch = nameRegex.firstMatch(userString);
      if (nameMatch != null && nameMatch.groupCount >= 1) {
        userName = nameMatch.group(1) ?? '';
        print('✅ Extracted name: $userName');
      }

      // Extract emailVisibility
      final emailVisibilityRegex = RegExp(r'"emailVisibility":([^,}]+)');
      final emailVisibilityMatch = emailVisibilityRegex.firstMatch(userString);
      if (emailVisibilityMatch != null && emailVisibilityMatch.groupCount >= 1) {
        emailVisibility = emailVisibilityMatch.group(1) == 'true';
        print('✅ Extracted emailVisibility: $emailVisibility');
      }

      // Extract verified
      final verifiedRegex = RegExp(r'"verified":([^,}]+)');
      final verifiedMatch = verifiedRegex.firstMatch(userString);
      if (verifiedMatch != null && verifiedMatch.groupCount >= 1) {
        verified = verifiedMatch.group(1) == 'true';
        print('✅ Extracted verified: $verified');
      }

      // If email is empty, use default
      if (userEmail.isEmpty) {
        userEmail = 'Tidak ada email';
        print('⚠️ Using default email: $userEmail');
      }

      // If name is empty, use email prefix or default
      if (userName.isEmpty && userEmail.isNotEmpty && userEmail != 'Tidak ada email') {
        userName = userEmail.split('@')[0];
        print('⚠️ Using email prefix as name: $userName');
      } else if (userName.isEmpty) {
        userName = 'Pengguna';
        print('⚠️ Using default name: $userName');
      }

      // Create UserModel with extracted data
      final userModel = UserModel(
        id: userId,
        email: userEmail,
        emailVisibility: emailVisibility,
        verified: verified,
        name: userName,
        phone: phone,
        address: address,
        userType: userType,
        avatar: avatar,
      );

      print('🎯 FINAL UserModel created:');
      print('  - ID: ${userModel.id}');
      print('  - Email: ${userModel.email}');
      print('  - Name: ${userModel.name}');
      print('  - EmailVisibility: ${userModel.emailVisibility}');
      print('  - Verified: ${userModel.verified}');

      return userModel;

    } catch (e) {
      print('❌ MAJOR ERROR in getCurrentUser: $e');
      return null;
    }
  }

  // SIMPLIFIED METHODS - Only use what exists in PocketBaseService

  // Basic update method (we'll implement this later if needed)
  Future<UserModel?> updateUserProfile({
    required String userId,
    String? name,
    String? phone,
    String? address,
  }) async {
    try {
      // For now, just return current user
      // We can implement update later when needed
      if (kDebugMode) {
        print('Update profile not implemented yet');
      }
      return getCurrentUser();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      return null;
    }
  }

  // Basic avatar upload (we'll implement this later if needed)
  Future<bool> uploadAvatar(String userId, Uint8List fileBytes, String fileName) async {
    try {
      if (kDebugMode) {
        print('Avatar upload not implemented yet');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading avatar: $e');
      }
      return false;
    }
  }
}
