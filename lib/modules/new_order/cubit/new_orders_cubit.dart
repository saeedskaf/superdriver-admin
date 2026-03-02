import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/data/env/end_points.dart';
import 'package:superdriver_admin/domain/models/admin_order.dart';
import 'package:superdriver_admin/domain/models/admin_order_details.dart';
import 'package:superdriver_admin/modules/new_order/cubit/new_orders_state.dart';

class NewOrdersCubit extends Cubit<NewOrdersState> {
  NewOrdersCubit() : super(NewOrdersInitial());

  static NewOrdersCubit get(BuildContext context) => BlocProvider.of(context);

  static const _timeout = Duration(seconds: 15);

  String? _search;
  String? _chatOrderId;
  String? _status = 'placed';
  bool? _isManual;
  int? _restaurant;
  String? _driver;
  String? _paymentMethod;
  bool? _isScheduled;
  int _page = 1;
  int _pageSize = 20;

  String? get search => _search;
  String? get chatOrderId => _chatOrderId;
  String? get status => _status;
  bool? get isScheduled => _isScheduled;

  String? get _token =>
      locator<SharedPreferencesRepository>().getData(key: 'access_token');

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<void> fetchNewOrders({
    String? search,
    String? chatOrderId,
    String? status,
    bool applyStatus = false,
    bool? isManual,
    bool applyIsManual = false,
    int? restaurant,
    bool applyRestaurant = false,
    String? driver,
    bool applyDriver = false,
    String? paymentMethod,
    bool applyPaymentMethod = false,
    bool? isScheduled,
    bool applyIsScheduled = false,
    int? page,
    int? pageSize,
    bool resetPage = false,
  }) async {
    if (_token == null) {
      emit(NewOrdersError('Not logged in'));
      return;
    }

    if (search != null) _search = search.trim().isEmpty ? null : search.trim();
    if (chatOrderId != null) {
      _chatOrderId = chatOrderId.trim().isEmpty ? null : chatOrderId.trim();
    }
    if (applyStatus || status != null) _status = status;
    if (applyIsManual || isManual != null) _isManual = isManual;
    if (applyRestaurant || restaurant != null) _restaurant = restaurant;
    if (applyDriver || driver != null) {
      _driver = driver == null || driver.trim().isEmpty ? null : driver.trim();
    }
    if (applyPaymentMethod || paymentMethod != null) {
      _paymentMethod = paymentMethod == null || paymentMethod.trim().isEmpty
          ? null
          : paymentMethod.trim();
    }
    if (applyIsScheduled) _isScheduled = isScheduled;
    if (page != null) _page = page;
    if (pageSize != null) _pageSize = pageSize;
    if (resetPage) _page = 1;

    emit(NewOrdersLoading());

    try {
      final query = <String, String>{
        'page': _page.toString(),
        'page_size': _pageSize.toString(),
      };
      if (_status != null) query['status'] = _status!;
      if (_isManual != null) query['is_manual'] = _isManual.toString();
      if (_chatOrderId != null) query['chat_order_id'] = _chatOrderId!;
      if (_search != null) query['search'] = _search!;
      if (_restaurant != null) query['restaurant'] = _restaurant.toString();
      if (_driver != null) query['driver'] = _driver!;
      if (_paymentMethod != null) query['payment_method'] = _paymentMethod!;
      if (_isScheduled != null) {
        query['is_scheduled'] = _isScheduled.toString();
      }

      final url = Uri.parse(
        ConstantsService.newOrdersEndpoint,
      ).replace(queryParameters: query);

      final response = await http.get(url, headers: _headers).timeout(_timeout);
      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          final raw = data is List
              ? data
              : (data is Map && data['results'] is List)
              ? data['results'] as List
              : [];
          emit(
            NewOrdersLoaded(raw.map((e) => AdminOrder.fromJson(e)).toList()),
          );
        case 401:
          emit(NewOrdersError('Session expired, please login again'));
        case 403:
          emit(NewOrdersError('You do not have permission'));
        default:
          emit(
            NewOrdersError('Failed to load orders (${response.statusCode})'),
          );
      }
    } catch (_) {
      emit(NewOrdersError('Connection error'));
    }
  }

  Future<void> refresh() => fetchNewOrders();

  Future<void> clearFilters() async {
    _search = null;
    _chatOrderId = null;
    _status = 'placed';
    _isManual = null;
    _restaurant = null;
    _driver = null;
    _paymentMethod = null;
    _isScheduled = null;
    _page = 1;
    _pageSize = 20;
    await fetchNewOrders();
  }

  Future<void> fetchOrderDetail(int orderId) async {
    if (_token == null) {
      emit(OrderDetailError('Not logged in'));
      return;
    }
    emit(OrderDetailLoading());

    try {
      final url = Uri.parse(ConstantsService.orderDetailEndpoint(orderId));

      final response = await http.get(url, headers: _headers).timeout(_timeout);

      log(response.body);

      switch (response.statusCode) {
        case 200:
          emit(
            OrderDetailLoaded(
              AdminOrderDetail.fromJson(jsonDecode(response.body)),
            ),
          );
        case 401:
          emit(OrderDetailError('Session expired'));
        default:
          emit(OrderDetailError('Failed to load order details'));
      }
    } catch (_) {
      emit(OrderDetailError('Connection error'));
    }
  }

  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
    String? reason,
  }) async {
    if (_token == null) {
      emit(UpdateOrderStatusError('Not logged in'));
      return;
    }
    emit(UpdateOrderStatusLoading());

    try {
      final url = Uri.parse(
        ConstantsService.updateOrderStatusEndpoint(orderId),
      );

      final body = <String, dynamic>{'status': status};
      if (status == 'cancelled' && reason != null) body['reason'] = reason;

      final response = await http
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);

      switch (response.statusCode) {
        case 200 || 201:
          emit(UpdateOrderStatusSuccess(status));
        case 401:
          emit(UpdateOrderStatusError('Session expired'));
        default:
          final message = _parseErrorMessage(response.body);
          emit(UpdateOrderStatusError(message));
      }
    } catch (_) {
      emit(UpdateOrderStatusError('Connection error'));
    }
  }

  String _parseErrorMessage(String body) {
    try {
      final err = jsonDecode(body);
      return err['detail']?.toString() ?? 'Failed to update status';
    } catch (_) {
      return 'Failed to update status';
    }
  }
}
