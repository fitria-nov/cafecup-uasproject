class UserModel {
  final String id;
  final String email;
  final bool emailVisibility;
  final bool verified;
  final String name;
  final String? phone;
  final String? address;
  final String? userType;
  final String? avatar;

  UserModel({
    required this.id,
    required this.email,
    required this.emailVisibility,
    required this.verified,
    required this.name,
    this.phone,
    this.address,
    this.userType,
    this.avatar,
  });

  // Factory constructor to create a UserModel from a PocketBase record
  factory UserModel.fromPocketBase(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailVisibility: json['emailVisibility'] == true,
      verified: json['verified'] == true,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      userType: json['user_type']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  // Convert UserModel to a Map for updating PocketBase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'emailVisibility': emailVisibility,
      'verified': verified,
      'name': name,
      'phone': phone,
      'address': address,
      'user_type': userType,
      'avatar': avatar,
    };
  }

  // Create a copy of the UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    bool? emailVisibility,
    bool? verified,
    String? name,
    String? phone,
    String? address,
    String? userType,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      emailVisibility: emailVisibility ?? this.emailVisibility,
      verified: verified ?? this.verified,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name, userType: $userType)';
  }
}
