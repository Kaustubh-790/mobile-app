class CartItem {
  final String id;
  final String serviceId;
  final String? packageId;
  final int quantity;
  final Map<String, dynamic>? customizations;
  final double price;
  final String addedAt;

  CartItem({
    required this.id,
    required this.serviceId,
    this.packageId,
    required this.quantity,
    this.customizations,
    required this.price,
    required this.addedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    try {
      // Handle different ID field names
      final String id =
          json['_id']?.toString() ??
          json['id']?.toString() ??
          'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Handle serviceId with fallback
      final String serviceId =
          json['serviceId']?.toString() ??
          json['service_id']?.toString() ??
          'unknown_service';

      // Handle packageId (optional)
      final String? packageId =
          json['packageId']?.toString() ?? json['package_id']?.toString();

      // Handle quantity with validation
      final int quantity = json['quantity'] is int
          ? json['quantity'] as int
          : json['quantity'] is String
          ? int.tryParse(json['quantity'] as String) ?? 1
          : 1;

      // Handle customizations (optional)
      final Map<String, dynamic>? customizations =
          json['customizations'] is Map<String, dynamic>
          ? json['customizations'] as Map<String, dynamic>
          : null;

      // Handle price with validation
      final double price = json['price'] is num
          ? (json['price'] as num).toDouble()
          : json['price'] is String
          ? double.tryParse(json['price'] as String) ?? 0.0
          : 0.0;

      // Handle addedAt with fallback
      final String addedAt =
          json['addedAt']?.toString() ??
          json['added_at']?.toString() ??
          DateTime.now().toIso8601String();

      return CartItem(
        id: id,
        serviceId: serviceId,
        packageId: packageId,
        quantity: quantity,
        customizations: customizations,
        price: price,
        addedAt: addedAt,
      );
    } catch (e) {
      print('CartItem.fromJson error: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'serviceId': serviceId,
      if (packageId != null) 'packageId': packageId,
      'quantity': quantity,
      if (customizations != null) 'customizations': customizations,
      'price': price,
      'addedAt': addedAt,
    };
  }

  CartItem copyWith({
    String? id,
    String? serviceId,
    String? packageId,
    int? quantity,
    Map<String, dynamic>? customizations,
    double? price,
    String? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      packageId: packageId ?? this.packageId,
      quantity: quantity ?? this.quantity,
      customizations: customizations ?? this.customizations,
      price: price ?? this.price,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.id == id &&
        other.serviceId == serviceId &&
        other.packageId == packageId &&
        other.quantity == quantity &&
        other.customizations == customizations &&
        other.price == price &&
        other.addedAt == addedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        serviceId.hashCode ^
        packageId.hashCode ^
        quantity.hashCode ^
        customizations.hashCode ^
        price.hashCode ^
        addedAt.hashCode;
  }

  @override
  String toString() {
    return 'CartItem(id: $id, serviceId: $serviceId, packageId: $packageId, quantity: $quantity, customizations: $customizations, price: $price, addedAt: $addedAt)';
  }
}
