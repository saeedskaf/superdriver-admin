import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:superdriver_admin/domain/models/admin_order_details.dart';
import 'package:superdriver_admin/modules/new_order/cubit/new_orders_cubit.dart';
import 'package:superdriver_admin/modules/new_order/cubit/new_orders_state.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final NewOrdersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = NewOrdersCubit()..fetchOrderDetail(widget.orderId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const TextCustom(
            text: 'Order Details',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: BlocConsumer<NewOrdersCubit, NewOrdersState>(
          listener: _onStateChange,
          builder: (context, state) => switch (state) {
            OrderDetailLoading() || UpdateOrderStatusLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            OrderDetailError(:final message) => _ErrorView(
              message: message,
              onRetry: () => _cubit.fetchOrderDetail(widget.orderId),
            ),
            OrderDetailLoaded(:final order) => _DetailContent(
              order: order,
              cubit: _cubit,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  void _onStateChange(BuildContext context, NewOrdersState state) {
    if (state is UpdateOrderStatusSuccess) {
      final isAccepted = state.newStatus == 'preparing';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAccepted ? 'Order accepted & sent to drivers' : 'Order cancelled',
          ),
          backgroundColor: isAccepted ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
    if (state is UpdateOrderStatusError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.order, required this.cubit});

  final AdminOrderDetail order;
  final NewOrdersCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderHeaderCard(order: order),
                const SizedBox(height: AppSpacing.md),
                _RestaurantCard(order: order),
                const SizedBox(height: AppSpacing.md),
                _CustomerCard(order: order),
                const SizedBox(height: AppSpacing.md),
                if (order.addressSnapshot != null) ...[
                  _AddressCard(address: order.addressSnapshot!),
                  const SizedBox(height: AppSpacing.md),
                ] else if (order.deliveryAddressText.isNotEmpty) ...[
                  _TextInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Address',
                    color: AppColors.secondaryDark,
                    text: order.deliveryAddressText,
                    background: AppColors.secondarySurface,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (order.description.isNotEmpty) ...[
                  _TextInfoCard(
                    icon: Icons.description_outlined,
                    title: 'Order Description',
                    color: AppColors.primary,
                    text: order.description,
                    background: AppColors.primarySurface,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (order.specialInstructions.isNotEmpty) ...[
                  _TextInfoCard(
                    icon: Icons.assignment_outlined,
                    title: 'Special Instructions',
                    color: AppColors.secondaryDark,
                    text: order.specialInstructions,
                    background: AppColors.secondarySurface,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (order.items.isNotEmpty) ...[
                  _ItemsCard(items: order.items),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (order.notes != null && order.notes!.isNotEmpty) ...[
                  _NotesCard(notes: order.notes!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (order.trackingInfo != null) ...[
                  _TrackingInfoCard(info: order.trackingInfo!),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (order.statusHistory.isNotEmpty) ...[
                  _StatusHistoryCard(events: order.statusHistory),
                  const SizedBox(height: AppSpacing.md),
                ],
                _PriceCard(order: order),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
        _ActionBar(order: order, cubit: cubit),
      ],
    );
  }
}

// ── Section Cards ─────────────────────────────────────────────────────────────

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TextCustom(
                  text: order.orderNumber,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              _StatusBadge(
                status: order.status,
                label: order.statusDisplay.isEmpty
                    ? order.status
                    : order.statusDisplay,
              ),
            ],
          ),
          if (order.chatOrderId.isNotEmpty || order.isManual) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (order.chatOrderId.isNotEmpty)
                  _InfoBadge(
                    label: order.chatOrderId,
                    color: AppColors.primary,
                    bg: AppColors.primarySurface,
                  ),
                if (order.isManual)
                  const _InfoBadge(
                    label: 'Manual Order',
                    color: AppColors.info,
                    bg: AppColors.infoSurface,
                  ),
                if (order.isScheduled)
                  const _InfoBadge(
                    label: 'Scheduled',
                    color: AppColors.secondaryDark,
                    bg: AppColors.secondarySurface,
                  ),
                if (order.isPricePending)
                  const _InfoBadge(
                    label: 'Price Pending',
                    color: AppColors.secondaryDark,
                    bg: AppColors.secondarySurface,
                  ),
              ],
            ),
          ],
          if (order.isScheduled && order.scheduledDeliveryTime != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: AppSizes.iconSm,
                    color: AppColors.secondaryDark,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  TextCustom(
                    text:
                        '${order.deliveryTypeDisplay}: ${order.scheduledDeliveryTime}',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({required this.order});

  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.restaurant,
            title: 'Restaurant',
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Name', value: order.displayRestaurantName),
          if ((order.restaurantPhone ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _PhoneRow(phone: order.restaurantPhone!),
          ],
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.person_outline,
            title: 'Customer',
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Name',
            value: order.userName.trim().isEmpty ? 'Guest' : order.userName,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PhoneRow(phone: order.contactPhone),
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(label: 'Payment', value: order.paymentMethodDisplay),
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(label: 'Delivery Type', value: order.deliveryTypeDisplay),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final dynamic address;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.location_on_outlined,
            title: 'Delivery Address',
            color: AppColors.secondaryDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(label: 'Full Address', value: address.fullAddress),
          if (address.area != null && address.area!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(label: 'Area', value: address.area!),
          ],
          if (address.governorate != null &&
              address.governorate!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(label: 'Governorate', value: address.governorate!),
          ],
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.items});

  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.shopping_bag_outlined,
            title: 'Order Items (${items.length})',
            color: AppColors.secondaryDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(
            items.length,
            (i) =>
                _OrderItemTile(item: items[i], isLast: i == items.length - 1),
          ),
        ],
      ),
    );
  }
}

class _TextInfoCard extends StatelessWidget {
  const _TextInfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.text,
    required this.background,
  });

  final IconData icon;
  final String title;
  final Color color;
  final String text;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(icon: icon, title: title, color: color),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: TextCustom(
              text: text,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.note_alt_outlined,
            title: 'Customer Notes',
            color: AppColors.secondaryDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: TextCustom(
              text: notes,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingInfoCard extends StatelessWidget {
  const _TrackingInfoCard({required this.info});

  final TrackingInfo info;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.route_outlined,
            title: 'Tracking Summary',
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailRow(
            label: 'Current Status',
            value: info.statusDisplay.isEmpty ? info.status : info.statusDisplay,
          ),
          if (info.scheduledDeliveryTime != null &&
              info.scheduledDeliveryTime!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(
              label: 'Scheduled At',
              value: info.scheduledDeliveryTime!,
            ),
          ],
          if (info.placedAt != null && info.placedAt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(label: 'Placed At', value: info.placedAt!),
          ],
          if (info.preparingAt != null && info.preparingAt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(label: 'Preparing At', value: info.preparingAt!),
          ],
          if (info.pickedAt != null && info.pickedAt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(label: 'Picked At', value: info.pickedAt!),
          ],
          if (info.deliveredAt != null && info.deliveredAt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _DetailRow(label: 'Delivered At', value: info.deliveredAt!),
          ],
        ],
      ),
    );
  }
}

class _StatusHistoryCard extends StatelessWidget {
  const _StatusHistoryCard({required this.events});

  final List<OrderStatusEvent> events;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.history_rounded,
            title: 'Status History',
            color: AppColors.secondaryDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(
            events.length,
            (index) => _StatusHistoryTile(
              event: events[index],
              isLast: index == events.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHistoryTile extends StatelessWidget {
  const _StatusHistoryTile({required this.event, required this.isLast});

  final OrderStatusEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final fromLabel = event.fromStatusDisplay.isEmpty
        ? event.fromStatus
        : event.fromStatusDisplay;
    final toLabel = event.toStatusDisplay.isEmpty
        ? event.toStatus
        : event.toStatusDisplay;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.secondarySurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextCustom(
              text: '$fromLabel -> $toLabel',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            if (event.changedByName.isNotEmpty) ...[
              const SizedBox(height: 4),
              TextCustom(
                text: 'By: ${event.changedByName}',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ],
            if (event.createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              TextCustom(
                text: event.createdAt,
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ],
            if (event.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              TextCustom(
                text: event.notes,
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.order});

  final AdminOrderDetail order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.receipt_long_outlined,
            title: 'Price Breakdown',
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.md),
          _PriceRow(label: 'Subtotal', value: order.subtotal),
          const SizedBox(height: AppSpacing.xs),
          _PriceRow(label: 'Delivery Fee', value: order.deliveryFee),
          const SizedBox(height: AppSpacing.xs),
          _PriceRow(
            label: 'Discount',
            value: order.discountAmount,
            emphasizeZero: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PercentRow(
            label: 'App Commission',
            value: order.appDiscountPercentage,
          ),
          const SizedBox(height: AppSpacing.xs),
          _PriceRow(
            label: 'Restaurant Due',
            value: order.restaurantTotal,
            highlight: AppColors.primary,
          ),
          if (order.isPricePending) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const TextCustom(
                text:
                    'Price is pending. The driver will confirm the final amount later.',
                fontSize: 12,
                color: AppColors.secondaryDark,
              ),
            ),
          ],
          if (order.finalPriceSetAt != null &&
              order.finalPriceSetAt!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(label: 'Final Price Set At', value: order.finalPriceSetAt!),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(color: AppColors.borderLight, height: 1),
          ),
          _PriceRow(label: 'Customer Total', value: order.total, isTotal: true),
        ],
      ),
    );
  }
}

// ── Action Bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.order, required this.cubit});

  final AdminOrderDetail order;
  final NewOrdersCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (order.status != 'placed') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button — fixed width, icon only on small screens
          SizedBox(
            height: AppSizes.buttonMd,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(context, order.id, cubit),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close,
                    size: AppSizes.iconSm,
                    color: AppColors.error,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  TextCustom(
                    text: 'Cancel',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SizedBox(
              height: AppSizes.buttonMd,
              child: order.isScheduled
                  ? Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const TextCustom(
                        text: 'Scheduled order. Auto-dispatched later.',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryDark,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => cubit.updateOrderStatus(
                        orderId: order.id,
                        status: 'preparing',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              size: AppSizes.iconSm,
                              color: AppColors.textOnPrimary,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            TextCustom(
                              text: 'Accept & Send to Drivers',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    int orderId,
    NewOrdersCubit cubit,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: AppSizes.iconMd,
            ),
            SizedBox(width: AppSpacing.xs),
            TextCustom(
              text: 'Cancel Order',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextCustom(
              text: 'Please provide a reason for cancellation:',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Restaurant closed, items unavailable...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TextCustom(
              text: 'Back',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: AppColors.secondaryDark,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              cubit.updateOrderStatus(
                orderId: orderId,
                status: 'cancelled',
                reason: reasonController.text.trim(),
              );
            },
            icon: const Icon(
              Icons.close,
              size: AppSizes.iconSm,
              color: AppColors.textOnPrimary,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            label: const TextCustom(
              text: 'Cancel Order',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Item Tile ───────────────────────────────────────────────────────────

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item, required this.isLast});

  final dynamic item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuantityBadge(quantity: item.quantity),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextCustom(
                          text: item.productName,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            TextCustom(
                              text: 'Unit: ${item.unitPrice} SYP',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            TextCustom(
                              text: 'Total: ${item.totalPrice} SYP',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.specialInstructions != null &&
                  item.specialInstructions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _SpecialInstructionsBox(text: item.specialInstructions!),
              ],
              if (item.addons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _AddonsBox(addons: item.addons),
              ],
            ],
          ),
        ),
        if (!isLast) const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _QuantityBadge extends StatelessWidget {
  const _QuantityBadge({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: TextCustom(
        text: '${quantity}x',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
      ),
    );
  }
}

class _SpecialInstructionsBox extends StatelessWidget {
  const _SpecialInstructionsBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.secondaryDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: AppSizes.iconSm,
            color: AppColors.secondaryDark,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TextCustom(
                  text: 'Special Instructions',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
                const SizedBox(height: 2),
                TextCustom(
                  text: text,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddonsBox extends StatelessWidget {
  const _AddonsBox({required this.addons});

  final List<dynamic> addons;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.infoSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TextCustom(
            text: 'Addons',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.infoDark,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...addons.map(
            (addon) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.add_circle,
                        size: 14,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      TextCustom(
                        text: '${addon.addonName} x${addon.quantity}',
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                  TextCustom(
                    text: '${addon.price} SYP',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Primitives ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: AppSizes.iconSm, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextCustom(
          text: title,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextCustom(text: label, fontSize: 12, color: AppColors.textTertiary),
        const SizedBox(height: 2),
        TextCustom(
          text: value,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DetailRow(label: 'Phone', value: phone),
        ),
        _IconAction(
          icon: Icons.copy,
          color: AppColors.info,
          bgColor: AppColors.infoSurface,
          onTap: () {
            Clipboard.setData(ClipboardData(text: phone));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone copied'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.xs),
        _IconAction(
          icon: Icons.call,
          color: AppColors.success,
          bgColor: AppColors.successSurface,
          onTap: () async {
            final uri = Uri.parse('tel:$phone');
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: AppSizes.iconSm, color: color),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.highlight,
    this.emphasizeZero = true,
  });

  final String label;
  final String value;
  final bool isTotal;
  final Color? highlight;
  final bool emphasizeZero;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextCustom(
          text: label,
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
        ),
        TextCustom(
          text: '$value SYP',
          fontSize: isTotal ? 16 : 14,
          fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          color:
              highlight ??
              (isTotal
                  ? AppColors.primary
                  : (!emphasizeZero && value == '0')
                  ? AppColors.textTertiary
                  : AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == 'cancelled';
    final bg = isCancelled ? AppColors.errorBg : AppColors.secondarySurface;
    final textColor = isCancelled ? AppColors.error : AppColors.secondaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: TextCustom(
        text: label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

class _PercentRow extends StatelessWidget {
  const _PercentRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextCustom(text: label, fontSize: 14, color: AppColors.textSecondary),
        TextCustom(
          text: '$value%',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: TextCustom(
        text: label,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          TextCustom(
            text: message,
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: AppSizes.iconSm),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
