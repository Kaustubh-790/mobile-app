import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  @JsonKey(name: '_id')
  final String id;
  
  final String? name;
  final String? email;
  final String? phone;
  final String role;
  
  @JsonKey(name: 'firebaseUid')
  final String? firebaseUid;
  
  @JsonKey(name: 'profilePic')
  final String? profilePic;
  
  @JsonKey(name: 'numberOfBookings')
  final int numberOfBookings;
  
  @JsonKey(name: 'hasFirstBooking')
  final bool hasFirstBooking;
  
  @JsonKey(name: 'profileCompleted')
  final bool profileCompleted;
  
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  
  @JsonKey(name: 'dateOfBirth')
  final String? dateOfBirth;
  final String? gender;
  
  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;
  
  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const User({
    required this.id,
    this.name,
    this.email,
    this.phone,
    required this.role,
    this.firebaseUid,
    this.profilePic,
    this.numberOfBookings = 0,
    this.hasFirstBooking = false,
    this.profileCompleted = false,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.dateOfBirth,
    this.gender,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? firebaseUid,
    String? profilePic,
    int? numberOfBookings,
    bool? hasFirstBooking,
    bool? profileCompleted,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? dateOfBirth,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      profilePic: profilePic ?? this.profilePic,
      numberOfBookings: numberOfBookings ?? this.numberOfBookings,
      hasFirstBooking: hasFirstBooking ?? this.hasFirstBooking,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
