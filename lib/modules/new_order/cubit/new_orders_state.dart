import 'package:superdriver_admin/domain/models/admin_order.dart';

import 'package:superdriver_admin/domain/models/admin_order_details.dart'
    show AdminOrderDetail;

abstract class NewOrdersState {}

class NewOrdersInitial extends NewOrdersState {}

// List
class NewOrdersLoading extends NewOrdersState {}

class NewOrdersLoaded extends NewOrdersState {
  final List<AdminOrder> orders;
  NewOrdersLoaded(this.orders);
}

class NewOrdersError extends NewOrdersState {
  final String message;
  NewOrdersError(this.message);
}

// Detail
class OrderDetailLoading extends NewOrdersState {}

class OrderDetailLoaded extends NewOrdersState {
  final AdminOrderDetail order;
  OrderDetailLoaded(this.order);
}

class OrderDetailError extends NewOrdersState {
  final String message;
  OrderDetailError(this.message);
}

// Update Status
class UpdateOrderStatusLoading extends NewOrdersState {}

class UpdateOrderStatusSuccess extends NewOrdersState {
  final String newStatus;
  UpdateOrderStatusSuccess(this.newStatus);
}

class UpdateOrderStatusError extends NewOrdersState {
  final String message;
  UpdateOrderStatusError(this.message);
}
