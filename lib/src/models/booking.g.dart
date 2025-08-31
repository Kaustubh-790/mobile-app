// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
  id: json['_id'] as String?,
  userId: json['userId'] as String,
  cartId: json['cartId'] as String,
  services: (json['services'] as List<dynamic>)
      .map((e) => BookingService.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentStatus: json['paymentStatus'] as String,
  paymentMethod: json['paymentMethod'] as String?,
  cardLast4: json['cardLast4'] as String?,
  bookingDate: DateTime.parse(json['bookingDate'] as String),
  bookingTime: json['bookingTime'] as String,
  customerInfo: CustomerInfo.fromJson(
    json['customerInfo'] as Map<String, dynamic>,
  ),
  status: json['status'] as String,
  assignedWorkerId: json['assignedWorkerId'] as String?,
  workerName: json['workerName'] as String?,
  scheduledDate: json['scheduledDate'] == null
      ? null
      : DateTime.parse(json['scheduledDate'] as String),
  scheduledTime: json['scheduledTime'] as String?,
  address: json['address'] as String?,
  duration: json['duration'] as String?,
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  rescheduleCount: (json['rescheduleCount'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  bookingCounted: json['bookingCounted'] as bool?,
  workerAssignments: json['workerAssignments'] as List<dynamic>?,
  refundStatus: json['refundStatus'] as String?,
  cancellationFee: (json['cancellationFee'] as num?)?.toDouble(),
);

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
  '_id': instance.id,
  'userId': instance.userId,
  'cartId': instance.cartId,
  'services': instance.services,
  'totalAmount': instance.totalAmount,
  'paymentStatus': instance.paymentStatus,
  'paymentMethod': instance.paymentMethod,
  'cardLast4': instance.cardLast4,
  'bookingDate': instance.bookingDate.toIso8601String(),
  'bookingTime': instance.bookingTime,
  'customerInfo': instance.customerInfo,
  'status': instance.status,
  'assignedWorkerId': instance.assignedWorkerId,
  'workerName': instance.workerName,
  'scheduledDate': instance.scheduledDate?.toIso8601String(),
  'scheduledTime': instance.scheduledTime,
  'address': instance.address,
  'duration': instance.duration,
  'completedAt': instance.completedAt?.toIso8601String(),
  'rescheduleCount': instance.rescheduleCount,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'bookingCounted': instance.bookingCounted,
  'workerAssignments': instance.workerAssignments,
  'refundStatus': instance.refundStatus,
  'cancellationFee': instance.cancellationFee,
};

BookingService _$BookingServiceFromJson(Map<String, dynamic> json) =>
    BookingService(
      serviceId: json['serviceId'] as String,
      packageId: json['packageId'],
      quantity: (json['quantity'] as num).toInt(),
      customizations: json['customizations'] as Map<String, dynamic>?,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      assignedWorkerId: json['assignedWorkerId'] as String?,
      workerName: json['workerName'] as String?,
      completedByWorker: json['completedByWorker'] as bool,
      serviceRating: (json['serviceRating'] as num?)?.toDouble(),
      serviceReview: json['serviceReview'] as String?,
      bookingTime: json['bookingTime'] as String?,
      scheduledDate: json['scheduledDate'] == null
          ? null
          : DateTime.parse(json['scheduledDate'] as String),
      scheduledTime: json['scheduledTime'] as String?,
      address: json['address'] as String?,
      duration: json['duration'] as String?,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      rescheduleCount: (json['rescheduleCount'] as num).toInt(),
      rescheduledDate: json['rescheduledDate'] == null
          ? null
          : DateTime.parse(json['rescheduledDate'] as String),
      rescheduledTime: json['rescheduledTime'] as String?,
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
    );

Map<String, dynamic> _$BookingServiceToJson(BookingService instance) =>
    <String, dynamic>{
      'serviceId': instance.serviceId,
      'packageId': instance.packageId,
      'quantity': instance.quantity,
      'customizations': instance.customizations,
      'price': instance.price,
      'status': instance.status,
      'assignedWorkerId': instance.assignedWorkerId,
      'workerName': instance.workerName,
      'completedByWorker': instance.completedByWorker,
      'serviceRating': instance.serviceRating,
      'serviceReview': instance.serviceReview,
      'bookingTime': instance.bookingTime,
      'scheduledDate': instance.scheduledDate?.toIso8601String(),
      'scheduledTime': instance.scheduledTime,
      'address': instance.address,
      'duration': instance.duration,
      'completedAt': instance.completedAt?.toIso8601String(),
      'rescheduleCount': instance.rescheduleCount,
      'rescheduledDate': instance.rescheduledDate?.toIso8601String(),
      'rescheduledTime': instance.rescheduledTime,
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
    };

CustomerInfo _$CustomerInfoFromJson(Map<String, dynamic> json) => CustomerInfo(
  name: json['name'] as String,
  email: json['email'] as String,
  phone: json['phone'] as String,
  address: json['address'] as String,
);

Map<String, dynamic> _$CustomerInfoToJson(CustomerInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'address': instance.address,
    };
