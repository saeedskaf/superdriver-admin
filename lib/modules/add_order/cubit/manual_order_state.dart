part of 'manual_order_cubit.dart';

abstract class ManualOrderState {}

class ManualOrderInitial extends ManualOrderState {}

class ManualOrderLoading extends ManualOrderState {}

class ManualOrderSuccess extends ManualOrderState {
  final String message;
  ManualOrderSuccess(this.message);
}

class ManualOrderError extends ManualOrderState {
  final String message;
  ManualOrderError(this.message);
}
