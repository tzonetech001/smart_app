import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, entrepreneur, customer }

class UserModel {
  String id;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String? gender;
  UserRole role;
  DateTime createdAt;
  String? profileImage;
  String region;
  String? district;
  String? ward;
  bool isActive;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.gender,
    required this.role,
    required this.createdAt,
    this.profileImage,
    this.isActive = true,
    this.region = 'Dar es Salaam',
    this.district,
    this.ward,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'profileImage': profileImage,
      'isActive': isActive,
      'region': region,
      'district': district,
      'ward': ward,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      gender: map['gender'],
      role: _stringToRole(map['role'] ?? 'customer'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profileImage: map['profileImage'],
      isActive: map['isActive'] ?? true,
      region: map['region'] ?? 'Dar es Salaam',
      district: map['district'],
      ward: map['ward'],
    );
  }

  static UserRole _stringToRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'entrepreneur':
        return UserRole.entrepreneur;
      default:
        return UserRole.customer;
    }
  }
}