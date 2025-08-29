// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['_id'] as String,
  name: json['name'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  role: json['role'] as String,
  firebaseUid: json['firebaseUid'] as String?,
  profilePic: json['profilePic'] as String?,
  numberOfBookings: (json['numberOfBookings'] as num?)?.toInt() ?? 0,
  hasFirstBooking: json['hasFirstBooking'] as bool? ?? false,
  profileCompleted: json['profileCompleted'] as bool? ?? false,
  address: json['address'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  zipCode: json['zipCode'] as String?,
  country: json['country'] as String?,
  dateOfBirth: json['dateOfBirth'] as String?,
  gender: json['gender'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'role': instance.role,
  'firebaseUid': instance.firebaseUid,
  'profilePic': instance.profilePic,
  'numberOfBookings': instance.numberOfBookings,
  'hasFirstBooking': instance.hasFirstBooking,
  'profileCompleted': instance.profileCompleted,
  'address': instance.address,
  'city': instance.city,
  'state': instance.state,
  'zipCode': instance.zipCode,
  'country': instance.country,
  'dateOfBirth': instance.dateOfBirth,
  'gender': instance.gender,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
