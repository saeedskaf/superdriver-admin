import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superdriver_admin/domain/models/admin_order.dart';
import 'package:superdriver_admin/modules/new_order/cubit/new_orders_cubit.dart';
import 'package:superdriver_admin/modules/new_order/cubit/new_orders_state.dart';
import 'package:superdriver_admin/modules/new_order/order_details_screen.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

class NewOrdersScreen extends StatefulWidget {
  const NewOrdersScreen({super.key});

  @override
  State<NewOrdersScreen> createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  late final NewOrdersCubit _cubit;
  final _searchCtrl = TextEditingController();
  final _chatOrderIdCtrl = TextEditingController();
  final _statusCtrl = TextEditingController(text: 'Placed');
  final _scheduleCtrl = TextEditingController(text: 'All');
  String _status = 'placed';
  bool? _isScheduled;

  @override
  void initState() {
    super.initState();
    _cubit = NewOrdersCubit()..fetchNewOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chatOrderIdCtrl.dispose();
    _statusCtrl.dispose();
    _scheduleCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _openDetail(int orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    ).then((_) => _cubit.refresh());
  }

  Future<void> _applyFilters() {
    return _cubit.fetchNewOrders(
      search: _searchCtrl.text,
      chatOrderId: _chatOrderIdCtrl.text,
      status: _status,
      isScheduled: _isScheduled,
      applyIsScheduled: true,
      resetPage: true,
    );
  }

  Future<void> _clearFilters() async {
    _searchCtrl.clear();
    _chatOrderIdCtrl.clear();
    setState(() {
      _status = 'placed';
      _isScheduled = null;
    });
    _statusCtrl.text = 'Placed';
    _scheduleCtrl.text = 'All';
    await _cubit.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          _FiltersBar(
            searchCtrl: _searchCtrl,
            chatOrderIdCtrl: _chatOrderIdCtrl,
            statusCtrl: _statusCtrl,
            scheduleCtrl: _scheduleCtrl,
            status: _status,
            isScheduled: _isScheduled,
            onStatusChanged: (value, label) => setState(() {
              _status = value;
              _statusCtrl.text = label;
            }),
            onScheduleChanged: (value, label) => setState(() {
              _isScheduled = value;
              _scheduleCtrl.text = label;
            }),
            onApply: _applyFilters,
            onClear: _clearFilters,
          ),
          Expanded(
            child: BlocBuilder<NewOrdersCubit, NewOrdersState>(
              builder: (context, state) => switch (state) {
                NewOrdersLoading() => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                NewOrdersError(:final message) => _ErrorView(
                  message: message,
                  onRetry: _applyFilters,
                ),
                NewOrdersLoaded(:final orders) when orders.isEmpty =>
                  _EmptyView(onRefresh: _applyFilters),
                NewOrdersLoaded(:final orders) => _OrdersListView(
                  orders: orders,
                  onRefresh: _cubit.refresh,
                  onTap: _openDetail,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.searchCtrl,
    required this.chatOrderIdCtrl,
    required this.statusCtrl,
    required this.scheduleCtrl,
    required this.status,
    required this.isScheduled,
    required this.onStatusChanged,
    required this.onScheduleChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController searchCtrl;
  final TextEditingController chatOrderIdCtrl;
  final TextEditingController statusCtrl;
  final TextEditingController scheduleCtrl;
  final String status;
  final bool? isScheduled;
  final void Function(String value, String label) onStatusChanged;
  final void Function(bool? value, String label) onScheduleChanged;
  final Future<void> Function() onApply;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FormFieldCustom(
                    controller: searchCtrl,
                    label: 'Search',
                    hintText: 'ID, Phone',
                    isRequired: false,
                    prefixIcon: const Icon(
                      Icons.search,
                      size: AppSizes.iconSm,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FormFieldCustom(
                    controller: chatOrderIdCtrl,
                    label: 'Chat Order ID',
                    hintText: 'Exact match',
                    isRequired: false,
                    prefixIcon: const Icon(
                      Icons.tag_outlined,
                      size: AppSizes.iconSm,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    controller: statusCtrl,
                    label: 'Status',
                    hintText: 'Select status',
                    icon: Icons.flag_outlined,
                    onTap: () => _showChoiceSheet(
                      context,
                      title: 'Status',
                      options: const [
                        ('placed', 'Placed'),
                        ('preparing', 'Preparing'),
                        ('picked', 'Picked'),
                        ('delivered', 'Delivered'),
                        ('cancelled', 'Cancelled'),
                        ('all', 'All'),
                      ],
                      selectedValue: status,
                      onSelected: onStatusChanged,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PickerField(
                    controller: scheduleCtrl,
                    label: 'Schedule',
                    hintText: 'All',
                    icon: Icons.schedule_outlined,
                    onTap: () => _showScheduleSheet(
                      context,
                      selectedValue: isScheduled,
                      onSelected: onScheduleChanged,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClear,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showChoiceSheet(
  BuildContext context, {
  required String title,
  required List<(String, String)> options,
  required String selectedValue,
  required void Function(String value, String label) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextCustom(
                text: title,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...options.map(
                (option) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(option.$2),
                  trailing: selectedValue == option.$1
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelected(option.$1, option.$2);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showScheduleSheet(
  BuildContext context, {
  required bool? selectedValue,
  required void Function(bool? value, String label) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextCustom(
                text: 'Schedule',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All'),
                trailing: selectedValue == null
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(null, 'All');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Now'),
                trailing: selectedValue == false
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(false, 'Now');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scheduled'),
                trailing: selectedValue == true
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  onSelected(true, 'Scheduled');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.onTap,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AbsorbPointer(
        child: FormFieldCustom(
          controller: controller,
          label: label,
          hintText: hintText,
          isRequired: false,
          readOnly: true,
          prefixIcon: Icon(
            icon,
            size: AppSizes.iconSm,
            color: AppColors.textTertiary,
          ),
          suffixIcon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _OrdersListView extends StatelessWidget {
  const _OrdersListView({
    required this.orders,
    required this.onRefresh,
    required this.onTap,
  });

  final List<AdminOrder> orders;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: orders.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) => _OrderCard(
          order: orders[index],
          onTap: () => onTap(orders[index].id),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          const TextCustom(
            text: 'No matching orders',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: AppSizes.iconSm),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            TextCustom(
              text: message,
              fontSize: 14,
              color: AppColors.textSecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: AppSizes.iconSm),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final AdminOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextCustom(
                    text: order.orderNumber,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                _Badge(
                  label: order.statusDisplay.isEmpty
                      ? order.status
                      : order.statusDisplay,
                  color: AppColors.secondaryDark,
                  bg: AppColors.secondarySurface,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (order.chatOrderId.isNotEmpty)
                  _Badge(
                    label: order.chatOrderId,
                    color: AppColors.primary,
                    bg: AppColors.primarySurface,
                  ),
                if (order.isScheduled)
                  _Badge(
                    label: order.deliveryTypeDisplay,
                    color: AppColors.secondaryDark,
                    bg: AppColors.secondarySurface,
                  ),
                if (order.isManual)
                  _Badge(
                    label: 'Manual',
                    color: AppColors.info,
                    bg: AppColors.infoSurface,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(
              icon: Icons.restaurant_outlined,
              iconColor: AppColors.primary,
              text: order.displayRestaurantName,
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            if ((order.restaurantPhone ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.phone_outlined,
                iconColor: AppColors.textTertiary,
                text: order.restaurantPhone!,
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Builder(
              builder: (context) {
                final name = order.userName.trim();
                final phone = order.contactPhone.trim();
                final customerLine = [
                  if (name.isNotEmpty) name,
                  if (phone.isNotEmpty) phone,
                ].join(' • ');

                if (customerLine.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _InfoRow(
                  icon: Icons.person_outline,
                  iconColor: AppColors.textTertiary,
                  text: customerLine,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                );
              },
            ),
            if (order.isScheduled && order.scheduledDeliveryTime != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                icon: Icons.schedule_outlined,
                iconColor: AppColors.secondaryDark,
                text: order.scheduledDeliveryTime!,
                fontSize: 12,
                color: AppColors.secondaryDark,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _PriceSummary(
                    label: 'Customer Total',
                    value: order.total,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PriceSummary(
                    label: 'Restaurant Due',
                    value: order.restaurantTotal,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: TextCustom(
                    text: '${order.itemsCount} items',
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                _Badge(
                  label: order.paymentMethodDisplay,
                  color: AppColors.info,
                  bg: AppColors.infoSurface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.fontSize,
    required this.color,
    this.fontWeight,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: TextCustom(
            text: text,
            fontSize: fontSize,
            fontWeight: fontWeight ?? FontWeight.w400,
            color: color,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextCustom(text: label, fontSize: 11, color: AppColors.textTertiary),
          const SizedBox(height: 2),
          TextCustom(
            text: '$value SYP',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
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
