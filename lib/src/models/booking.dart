import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  final String? id;
  final String userId;
  final String cartId;
  final List<BookingService> services;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod;
  final String? cardLast4;
  final DateTime bookingDate;
  final String bookingTime;
  final CustomerInfo customerInfo;
  final String status;
  final String? assignedWorkerId;
  final String? workerName;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String address;
  final String duration;
  final DateTime? completedAt;
  final int rescheduleCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    this.id,
    required this.userId,
    required this.cartId,
    required this.services,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.cardLast4,
    required this.bookingDate,
    required this.bookingTime,
    required this.customerInfo,
    required this.status,
    this.assignedWorkerId,
    this.workerName,
    this.scheduledDate,
    this.scheduledTime,
    required this.address,
    required this.duration,
    this.completedAt,
    required this.rescheduleCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

  Booking copyWith({
    String? id,
    String? userId,
    String? cartId,
    List<BookingService>? services,
    double? totalAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? cardLast4,
    DateTime? bookingDate,
    String? bookingTime,
    CustomerInfo? customerInfo,
    String? status,
    String? assignedWorkerId,
    String? workerName,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? address,
    String? duration,
    DateTime? completedAt,
    int? rescheduleCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cartId: cartId ?? this.cartId,
      services: services ?? this.services,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardLast4: cardLast4 ?? this.cardLast4,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      customerInfo: customerInfo ?? this.customerInfo,
      status: status ?? this.status,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      workerName: workerName ?? this.workerName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      address: address ?? this.address,
      duration: duration ?? this.duration,
      completedAt: completedAt ?? this.completedAt,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
class BookingService {
  final String serviceId;
  final String? packageId;
  final int quantity;
  final Map<String, dynamic>? customizations;
  final double price;
  final String status;
  final String? assignedWorkerId;
  final String? workerName;
  final bool completedByWorker;
  final double? serviceRating;
  final String? serviceReview;
  final String? bookingTime;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String? address;
  final String? duration;
  final DateTime? completedAt;
  final int rescheduleCount;
  final DateTime? rescheduledDate;
  final String? rescheduledTime;
  final DateTime? cancelledAt;

  const BookingService({
    required this.serviceId,
    this.packageId,
    required this.quantity,
    this.customizations,
    required this.price,
    required this.status,
    this.assignedWorkerId,
    this.workerName,
    required this.completedByWorker,
    this.serviceRating,
    this.serviceReview,
    this.bookingTime,
    this.scheduledDate,
    this.scheduledTime,
    this.address,
    this.duration,
    this.completedAt,
    required this.rescheduleCount,
    this.rescheduledDate,
    this.rescheduledTime,
    this.cancelledAt,
  });

  factory BookingService.fromJson(Map<String, dynamic> json) =>
      _$BookingServiceFromJson(json);
  Map<String, dynamic> toJson() => _$BookingServiceToJson(this);

  BookingService copyWith({
    String? serviceId,
    String? packageId,
    int? quantity,
    Map<String, dynamic>? customizations,
    double? price,
    String? status,
    String? assignedWorkerId,
    String? workerName,
    bool? completedByWorker,
    double? serviceRating,
    String? serviceReview,
    String? bookingTime,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? address,
    String? duration,
    DateTime? completedAt,
    int? rescheduleCount,
    DateTime? rescheduledDate,
    String? rescheduledTime,
    DateTime? cancelledAt,
  }) {
    return BookingService(
      serviceId: serviceId ?? this.serviceId,
      packageId: packageId ?? this.packageId,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
      price: price ?? this.price,
      status: status ?? this.status,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      workerName: workerName ?? this.workerName,
      completedByWorker: completedByWorker ?? this.completedByWorker,
      serviceRating: serviceRating ?? this.serviceRating,
      serviceReview: serviceReview ?? this.serviceReview,
      bookingTime: bookingTime ?? this.bookingTime,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      address: address ?? this.address,
      duration: duration ?? this.duration,
      completedAt: completedAt ?? this.completedAt,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
      rescheduledDate: rescheduledDate ?? this.rescheduledDate,
      rescheduledTime: rescheduledTime ?? this.rescheduledTime,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

@JsonSerializable()
class CustomerInfo {
  final String name;
  final String email;
  final String phone;
  final String address;

  const CustomerInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) =>
      _$CustomerInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerInfoToJson(this);

  CustomerInfo copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    return CustomerInfo(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}

// Enums for status fields
enum PaymentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('refunded')
  refunded,
}

enum BookingStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('rescheduled')
  rescheduled,
}

enum ServiceStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('rescheduled')
  rescheduled,
}
