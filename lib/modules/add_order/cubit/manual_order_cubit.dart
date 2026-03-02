import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/data/env/end_points.dart';
import 'package:superdriver_admin/domain/models/restaurant_choice.dart';

part 'manual_order_state.dart';

class ManualOrderCubit extends Cubit<ManualOrderState> {
  ManualOrderCubit() : super(ManualOrderInitial());

  static ManualOrderCubit get(BuildContext context) => BlocProvider.of(context);

  static const _timeout = Duration(seconds: 15);

  String? get _token =>
      locator<SharedPreferencesRepository>().getData(key: 'access_token');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Fetch Restaurants ─────────────────────────────────────────────────────

  Future<List<RestaurantChoice>> fetchRestaurants() async {
    final uri = Uri.parse(ConstantsService.restaurantChoicesEndpoint);
    final response = await http.get(uri, headers: _headers).timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load restaurants (${response.statusCode})');
    }

    final data = jsonDecode(response.body);

    if (data is List) {
      return data.map((e) => RestaurantChoice.fromJson(e)).toList();
    }
    if (data is Map && data['results'] is List) {
      return (data['results'] as List)
          .map((e) => RestaurantChoice.fromJson(e))
          .toList();
    }

    throw Exception('Unexpected response format');
  }

  // ── Create Manual Order ───────────────────────────────────────────────────

  Future<void> createManualOrder({
    required String source,
    required String contactPhone,
    required String description,
    required String subtotal,
    required String deliveryFee,
    required String total,
    required String restaurantTotal,
    required bool isPricePending,
    String? chatOrderId,
    String? deliveryAddressText,
    int? deliveryAddressId,
    int? userId,
    int? restaurantId,
    String? restaurantNameManual,
    String? restaurantAddressManual,
    String? paymentMethod,
    String? notes,
    String? scheduledDeliveryTime,
  }) async {
    if (_token == null) {
      emit(ManualOrderError('Not logged in'));
      return;
    }
    emit(ManualOrderLoading());

    try {
      final url = Uri.parse(ConstantsService.createManualOrderEndpoint);

      final body = _buildBody(
        source: source,
        contactPhone: contactPhone,
        description: description,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        restaurantTotal: restaurantTotal,
        isPricePending: isPricePending,
        chatOrderId: chatOrderId,
        deliveryAddressText: deliveryAddressText,
        deliveryAddressId: deliveryAddressId,
        userId: userId,
        restaurantId: restaurantId,
        restaurantNameManual: restaurantNameManual,
        restaurantAddressManual: restaurantAddressManual,
        paymentMethod: paymentMethod,
        notes: notes,
        scheduledDeliveryTime: scheduledDeliveryTime,
      );

      final response = await http
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200 || 201:
          emit(ManualOrderSuccess('Order created successfully'));
        case 400:
          emit(ManualOrderError(_parse400Error(response.body)));
        case 401:
          emit(ManualOrderError('Session expired'));
        default:
          emit(ManualOrderError('Failed to create order'));
      }
    } catch (_) {
      emit(ManualOrderError('Connection error'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _buildBody({
    required String source,
    required String contactPhone,
    required String description,
    required String subtotal,
    required String deliveryFee,
    required String total,
    required String restaurantTotal,
    required bool isPricePending,
    String? chatOrderId,
    String? deliveryAddressText,
    int? deliveryAddressId,
    int? userId,
    int? restaurantId,
    String? restaurantNameManual,
    String? restaurantAddressManual,
    String? paymentMethod,
    String? notes,
    String? scheduledDeliveryTime,
  }) {
    final body = <String, dynamic>{
      'source': source,
      'contact_phone': contactPhone,
      'description': description,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'restaurant_total': restaurantTotal,
      'is_price_pending': isPricePending,
    };

    if (chatOrderId?.trim().isNotEmpty == true) {
      body['chat_order_id'] = chatOrderId!.trim();
    }

    if (source == 'external') {
      if (deliveryAddressText?.trim().isNotEmpty == true) {
        body['delivery_address_text'] = deliveryAddressText!.trim();
      }
    } else if (source == 'chat') {
      if (userId != null) body['user_id'] = userId;
      if (deliveryAddressId != null) {
        body['delivery_address_id'] = deliveryAddressId;
      }
    }

    if (restaurantId != null) {
      body['restaurant_id'] = restaurantId;
    } else if (restaurantNameManual?.trim().isNotEmpty == true) {
      body['restaurant_name_manual'] = restaurantNameManual!.trim();
      if (source == 'external' &&
          restaurantAddressManual?.trim().isNotEmpty == true) {
        body['restaurant_address_manual'] = restaurantAddressManual!.trim();
      }
    }

    if (paymentMethod?.trim().isNotEmpty == true) {
      body['payment_method'] = paymentMethod!.trim();
    }
    if (notes?.trim().isNotEmpty == true) body['notes'] = notes!.trim();
    if (scheduledDeliveryTime != null) {
      body['scheduled_delivery_time'] = scheduledDeliveryTime;
    }

    return body;
  }

  String _parse400Error(String responseBody) {
    try {
      final err = jsonDecode(responseBody);
      return err is Map ? err.values.first.toString() : 'Invalid data';
    } catch (_) {
      return 'Invalid data';
    }
  }
}
