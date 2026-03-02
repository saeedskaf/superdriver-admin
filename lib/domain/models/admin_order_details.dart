class AdminOrderDetail {
  final int id;
  final String orderNumber;
  final String chatOrderId;
  final bool isManual;
  final String status;
  final String statusDisplay;
  final String restaurantName;
  final String displayRestaurantName;
  final String? restaurantPhone;
  final String userName;
  final String contactPhone;
  final String subtotal;
  final String deliveryFee;
  final String discountAmount;
  final String total;
  final String restaurantTotal;
  final String appDiscountPercentage;
  final String paymentMethod;
  final String paymentMethodDisplay;
  final String deliveryTypeDisplay;
  final bool isPricePending;
  final AddressSnapshot? addressSnapshot;
  final List<OrderItem> items;
  final String? notes;
  final String description;
  final String deliveryAddressText;
  final String specialInstructions;
  final String? finalPriceSetAt;
  final TrackingInfo? trackingInfo;
  final List<OrderStatusEvent> statusHistory;
  final bool isScheduled;
  final String? scheduledDeliveryTime;

  AdminOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.chatOrderId,
    required this.isManual,
    required this.status,
    required this.statusDisplay,
    required this.restaurantName,
    required this.displayRestaurantName,
    this.restaurantPhone,
    required this.userName,
    required this.contactPhone,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    required this.restaurantTotal,
    required this.appDiscountPercentage,
    required this.paymentMethod,
    required this.paymentMethodDisplay,
    required this.deliveryTypeDisplay,
    required this.isPricePending,
    this.addressSnapshot,
    required this.items,
    this.notes,
    required this.description,
    required this.deliveryAddressText,
    required this.specialInstructions,
    this.finalPriceSetAt,
    this.trackingInfo,
    required this.statusHistory,
    this.isScheduled = false,
    this.scheduledDeliveryTime,
  });

  factory AdminOrderDetail.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value, {String fallback = ''}) {
      return value == null ? fallback : value.toString();
    }

    bool readBool(dynamic value) => value == true;

    final addressJson = json['address_snapshot'];

    return AdminOrderDetail(
      id: json['id'] ?? 0,
      orderNumber: readString(json['order_number']),
      chatOrderId: readString(json['chat_order_id']),
      isManual: readBool(json['is_manual']),
      status: readString(json['status']),
      statusDisplay: readString(json['status_display']),
      restaurantName: readString(json['restaurant_name']),
      displayRestaurantName: readString(
        json['display_restaurant_name'],
        fallback: readString(json['restaurant_name']),
      ),
      restaurantPhone: json['restaurant_phone']?.toString(),
      userName: readString(json['user_name']),
      contactPhone: readString(
        json['contact_phone'],
        fallback: readString(json['user_phone']),
      ),
      subtotal: readString(json['subtotal'], fallback: '0'),
      deliveryFee: readString(json['delivery_fee'], fallback: '0'),
      discountAmount: readString(json['discount_amount'], fallback: '0'),
      total: readString(json['total'], fallback: '0'),
      restaurantTotal: readString(json['restaurant_total'], fallback: '0'),
      appDiscountPercentage: readString(
        json['app_discount_percentage'],
        fallback: '0',
      ),
      paymentMethod: readString(json['payment_method'], fallback: 'cash'),
      paymentMethodDisplay: readString(
        json['payment_method_display'],
        fallback: readString(json['payment_method']).toUpperCase(),
      ),
      deliveryTypeDisplay: readString(
        json['delivery_type_display'],
        fallback: readBool(json['is_scheduled']) ? 'Scheduled' : 'Immediate',
      ),
      isPricePending: readBool(json['is_price_pending']),
      addressSnapshot: addressJson is Map
          ? AddressSnapshot.maybeFromJson(Map<String, dynamic>.from(addressJson))
          : null,
      items: json['items'] != null
          ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
          : [],
      notes: json['notes']?.toString(),
      description: readString(json['description']),
      deliveryAddressText: readString(json['delivery_address_text']),
      specialInstructions: readString(json['special_instructions']),
      finalPriceSetAt: json['final_price_set_at']?.toString(),
      trackingInfo: json['tracking_info'] is Map
          ? TrackingInfo.fromJson(
              Map<String, dynamic>.from(json['tracking_info'] as Map),
            )
          : null,
      statusHistory: json['status_history'] is List
          ? (json['status_history'] as List)
                .whereType<Map>()
                .map(
                  (e) => OrderStatusEvent.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      isScheduled: readBool(json['is_scheduled']),
      scheduledDeliveryTime: json['scheduled_delivery_time']?.toString(),
    );
  }
}

class AddressSnapshot {
  final String fullAddress;
  final String? area;
  final String? governorate;

  AddressSnapshot({required this.fullAddress, this.area, this.governorate});

  static AddressSnapshot? maybeFromJson(Map<String, dynamic> json) {
    final fullAddress = (json['full_address'] ?? '').toString().trim();
    final area = json['area']?.toString().trim();
    final governorate = json['governorate']?.toString().trim();

    if (fullAddress.isEmpty &&
        (area == null || area.isEmpty) &&
        (governorate == null || governorate.isEmpty)) {
      return null;
    }

    return AddressSnapshot(
      fullAddress: fullAddress,
      area: area,
      governorate: governorate,
    );
  }
}

class TrackingInfo {
  final String status;
  final String statusDisplay;
  final bool isScheduled;
  final String? scheduledDeliveryTime;
  final bool isPricePending;
  final String? placedAt;
  final String? preparingAt;
  final String? pickedAt;
  final String? deliveredAt;

  TrackingInfo({
    required this.status,
    required this.statusDisplay,
    required this.isScheduled,
    this.scheduledDeliveryTime,
    required this.isPricePending,
    this.placedAt,
    this.preparingAt,
    this.pickedAt,
    this.deliveredAt,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> json) {
    bool readBool(dynamic value) => value == true;
    String readString(dynamic value, {String fallback = ''}) =>
        value == null ? fallback : value.toString();

    return TrackingInfo(
      status: readString(json['status']),
      statusDisplay: readString(json['status_display']),
      isScheduled: readBool(json['is_scheduled']),
      scheduledDeliveryTime: json['scheduled_delivery_time']?.toString(),
      isPricePending: readBool(json['is_price_pending']),
      placedAt: json['placed_at']?.toString(),
      preparingAt: json['preparing_at']?.toString(),
      pickedAt: json['picked_at']?.toString(),
      deliveredAt: json['delivered_at']?.toString(),
    );
  }
}

class OrderStatusEvent {
  final String fromStatus;
  final String fromStatusDisplay;
  final String toStatus;
  final String toStatusDisplay;
  final String changedByName;
  final String notes;
  final String createdAt;

  OrderStatusEvent({
    required this.fromStatus,
    required this.fromStatusDisplay,
    required this.toStatus,
    required this.toStatusDisplay,
    required this.changedByName,
    required this.notes,
    required this.createdAt,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value, {String fallback = ''}) =>
        value == null ? fallback : value.toString();

    return OrderStatusEvent(
      fromStatus: readString(json['from_status']),
      fromStatusDisplay: readString(json['from_status_display']),
      toStatus: readString(json['to_status']),
      toStatusDisplay: readString(json['to_status_display']),
      changedByName: readString(json['changed_by_name']),
      notes: readString(json['notes']),
      createdAt: readString(json['created_at']),
    );
  }
}

class OrderItem {
  final String productName;
  final int quantity;
  final String unitPrice;
  final String totalPrice;
  final String? specialInstructions;
  final List<OrderAddon> addons;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.specialInstructions,
    required this.addons,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unitPrice: json['unit_price'] ?? '0',
      totalPrice: json['total_price'] ?? '0',
      specialInstructions: json['special_instructions'],
      addons: json['addons'] != null
          ? (json['addons'] as List).map((e) => OrderAddon.fromJson(e)).toList()
          : [],
    );
  }
}

class OrderAddon {
  final String addonName;
  final int quantity;
  final String price;

  OrderAddon({
    required this.addonName,
    required this.quantity,
    required this.price,
  });

  factory OrderAddon.fromJson(Map<String, dynamic> json) {
    return OrderAddon(
      addonName: json['addon_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? '0',
    );
  }
}
