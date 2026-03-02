class AdminOrder {
  final int id;
  final String orderNumber;
  final bool isManual;
  final String chatOrderId;
  final String status;
  final String statusDisplay;
  final int? restaurant;
  final String restaurantName;
  final String displayRestaurantName;
  final String? restaurantPhone;
  final String? restaurantLogo;
  final int? user;
  final String userName;
  final String userPhone;
  final String contactPhone;
  final String total;
  final String subtotal;
  final String restaurantTotal;
  final String deliveryFee;
  final String discountAmount;
  final String appDiscountPercentage;
  final bool isPricePending;
  final int itemsCount;
  final String paymentMethod;
  final String paymentMethodDisplay;
  final bool isScheduled;
  final String? scheduledDeliveryTime;
  final String deliveryTypeDisplay;
  final bool hasDriver;
  final String? placedAt;
  final String? createdAt;

  AdminOrder({
    required this.id,
    required this.orderNumber,
    required this.isManual,
    required this.chatOrderId,
    required this.status,
    required this.statusDisplay,
    this.restaurant,
    required this.restaurantName,
    required this.displayRestaurantName,
    this.restaurantPhone,
    this.restaurantLogo,
    this.user,
    required this.userName,
    required this.userPhone,
    required this.contactPhone,
    required this.total,
    required this.subtotal,
    required this.restaurantTotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.appDiscountPercentage,
    required this.isPricePending,
    required this.itemsCount,
    required this.paymentMethod,
    required this.paymentMethodDisplay,
    required this.isScheduled,
    this.scheduledDeliveryTime,
    required this.deliveryTypeDisplay,
    required this.hasDriver,
    this.placedAt,
    this.createdAt,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value, {String fallback = ''}) {
      return value == null ? fallback : value.toString();
    }

    bool readBool(dynamic value) => value == true;

    return AdminOrder(
      id: json['id'] ?? 0,
      orderNumber: readString(json['order_number']),
      isManual: readBool(json['is_manual']),
      chatOrderId: readString(json['chat_order_id']),
      status: readString(json['status']),
      statusDisplay: readString(json['status_display']),
      restaurant: json['restaurant'],
      restaurantName: readString(json['restaurant_name']),
      displayRestaurantName: readString(
        json['display_restaurant_name'],
        fallback: readString(json['restaurant_name']),
      ),
      restaurantPhone: json['restaurant_phone']?.toString(),
      restaurantLogo: json['restaurant_logo']?.toString(),
      user: json['user'],
      userName: readString(json['user_name']),
      userPhone: readString(json['user_phone']),
      contactPhone: readString(
        json['contact_phone'],
        fallback: readString(json['user_phone']),
      ),
      total: readString(json['total'], fallback: '0'),
      subtotal: readString(json['subtotal'], fallback: '0'),
      restaurantTotal: readString(json['restaurant_total'], fallback: '0'),
      deliveryFee: readString(json['delivery_fee'], fallback: '0'),
      discountAmount: readString(json['discount_amount'], fallback: '0'),
      appDiscountPercentage: readString(
        json['app_discount_percentage'],
        fallback: '0',
      ),
      isPricePending: readBool(json['is_price_pending']),
      itemsCount: json['items_count'] ?? 0,
      paymentMethod: readString(json['payment_method'], fallback: 'cash'),
      paymentMethodDisplay: readString(
        json['payment_method_display'],
        fallback: readString(json['payment_method']).toUpperCase(),
      ),
      isScheduled: readBool(json['is_scheduled']),
      scheduledDeliveryTime: json['scheduled_delivery_time']?.toString(),
      deliveryTypeDisplay: readString(
        json['delivery_type_display'],
        fallback: readBool(json['is_scheduled']) ? 'Scheduled' : 'Immediate',
      ),
      hasDriver: readBool(json['has_driver']),
      placedAt: json['placed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
