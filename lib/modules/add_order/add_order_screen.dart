import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:superdriver_admin/domain/models/restaurant_choice.dart';
import 'package:superdriver_admin/modules/add_order/cubit/manual_order_cubit.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

class ManualOrderScreen extends StatefulWidget {
  const ManualOrderScreen({
    super.key,
    this.initialSource,
    this.lockSource = false,
    this.initialChatOrderId,
    this.initialPhone,
    this.initialDescription,
    this.initialUserId,
    this.initialAddressId,
  });

  final String? initialSource;
  final bool lockSource;
  final String? initialChatOrderId;
  final String? initialPhone;
  final String? initialDescription;
  final int? initialUserId;
  final int? initialAddressId;

  @override
  State<ManualOrderScreen> createState() => _ManualOrderScreenState();
}

class _ManualOrderScreenState extends State<ManualOrderScreen> {
  late final ManualOrderCubit _cubit;
  final _formKey = GlobalKey<FormState>();

  // Source
  String _source = 'external';
  bool _isRegisteredRestaurant = true;
  String _paymentMethod = 'cash';
  bool _isScheduled = false;
  bool _isPricePending = false;
  DateTime? _scheduledAt;

  // Controllers
  final _phoneCtrl = TextEditingController();
  final _chatOrderIdCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _subtotalCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _restaurantTotalCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _addressTextCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();
  final _addressIdCtrl = TextEditingController();
  final _restaurantIdCtrl = TextEditingController();
  final _restaurantDisplayCtrl = TextEditingController();
  final _restaurantNameCtrl = TextEditingController();
  final _restaurantAddressCtrl = TextEditingController();

  // Restaurants picker state

  List<RestaurantChoice> _restaurants = [];
  bool _restaurantsLoading = false;
  String? _restaurantsError;

  @override
  void initState() {
    super.initState();
    _cubit = ManualOrderCubit();
    _applyInitialPrefill();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _chatOrderIdCtrl.dispose();
    _descriptionCtrl.dispose();
    _subtotalCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _totalCtrl.dispose();
    _restaurantTotalCtrl.dispose();
    _notesCtrl.dispose();
    _addressTextCtrl.dispose();
    _userIdCtrl.dispose();
    _addressIdCtrl.dispose();
    _restaurantIdCtrl.dispose();
    _restaurantDisplayCtrl.dispose();
    _restaurantNameCtrl.dispose();
    _restaurantAddressCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ManualOrderCubit, ManualOrderState>(
        listener: _onStateChange,
        builder: (context, state) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SourceCard(
                        source: _source,
                        onChanged: _onSourceChanged,
                        enabled: !widget.lockSource,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ContactCard(
                        source: _source,
                        phoneCtrl: _phoneCtrl,
                        userIdCtrl: _userIdCtrl,
                      ),
                      if (_source == 'chat') ...[
                        const SizedBox(height: AppSpacing.md),
                        _ChatLinkCard(chatOrderIdCtrl: _chatOrderIdCtrl),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _AddressCard(
                        source: _source,
                        addressTextCtrl: _addressTextCtrl,
                        addressIdCtrl: _addressIdCtrl,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _RestaurantCard(
                        source: _source,
                        isRegistered: _isRegisteredRestaurant,
                        restaurantDisplayCtrl: _restaurantDisplayCtrl,
                        restaurantIdCtrl: _restaurantIdCtrl,
                        restaurantNameCtrl: _restaurantNameCtrl,
                        restaurantAddressCtrl: _restaurantAddressCtrl,
                        onToggle: _onRestaurantToggle,
                        onPickerTap: _openRestaurantsPicker,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DescriptionCard(descriptionCtrl: _descriptionCtrl),
                      const SizedBox(height: AppSpacing.md),
                      _PricingCard(
                        isPricePending: _isPricePending,
                        onPricePendingChanged: (value) {
                          setState(() {
                            _isPricePending = value;
                            if (value) {
                              _subtotalCtrl.clear();
                              _totalCtrl.clear();
                              _restaurantTotalCtrl.clear();
                            }
                          });
                        },
                        subtotalCtrl: _subtotalCtrl,
                        deliveryFeeCtrl: _deliveryFeeCtrl,
                        totalCtrl: _totalCtrl,
                        restaurantTotalCtrl: _restaurantTotalCtrl,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ScheduleCard(
                        isScheduled: _isScheduled,
                        scheduledAt: _scheduledAt,
                        onModeChanged: (value) =>
                            setState(() => _isScheduled = value),
                        onPickDateTime: _pickScheduledDateTime,
                        onClearDateTime: () =>
                            setState(() => _scheduledAt = null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PaymentCard(
                        selected: _paymentMethod,
                        onChanged: (v) => setState(() => _paymentMethod = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _NotesCard(notesCtrl: _notesCtrl),
                      const SizedBox(height: AppSpacing.xxl),
                      _SubmitButton(
                        isLoading: state is ManualOrderLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Listeners & Handlers ─────────────────────────────────────────────────

  void _onStateChange(BuildContext context, ManualOrderState state) {
    if (state is ManualOrderSuccess) {
      _showSnackBar(context, state.message, AppColors.success);
      _clearForm();
    }
    if (state is ManualOrderError) {
      _showSnackBar(context, state.message, AppColors.error);
    }
  }

  Future<void> _pickScheduledDateTime() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _isScheduled = true;
    });
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  void _onSourceChanged(String value) {
    if (widget.lockSource) return;

    setState(() {
      _source = value;
      if (_source == 'external') {
        _userIdCtrl.clear();
        _addressIdCtrl.clear();
        _chatOrderIdCtrl.clear();
      } else {
        _addressTextCtrl.clear();
        _restaurantAddressCtrl.clear();
      }
    });
  }

  void _onRestaurantToggle(bool isRegistered) {
    setState(() {
      _isRegisteredRestaurant = isRegistered;
      if (isRegistered) {
        _restaurantNameCtrl.clear();
        _restaurantAddressCtrl.clear();
      } else {
        _restaurantIdCtrl.clear();
        _restaurantDisplayCtrl.clear();
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_source == 'chat' && _chatOrderIdCtrl.text.trim().isEmpty) {
      _showSnackBar(
        context,
        'Chat Order ID is required for chat orders',
        AppColors.error,
      );
      return;
    }

    if (_source == 'chat' && int.tryParse(_userIdCtrl.text.trim()) == null) {
      _showSnackBar(context, 'Valid User ID is required', AppColors.error);
      return;
    }

    if (_source == 'chat' && int.tryParse(_addressIdCtrl.text.trim()) == null) {
      _showSnackBar(context, 'Valid Address ID is required', AppColors.error);
      return;
    }

    if (_isScheduled) {
      if (_scheduledAt == null) {
        _showSnackBar(
          context,
          'Please select a scheduled time',
          AppColors.error,
        );
        return;
      }
      final minTime = DateTime.now().add(const Duration(minutes: 30));
      if (_scheduledAt!.isBefore(minTime)) {
        _showSnackBar(
          context,
          'Scheduled time must be at least 30 minutes from now',
          AppColors.error,
        );
        return;
      }
    }

    _cubit.createManualOrder(
      source: _source,
      contactPhone: _phoneCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      subtotal: _normalizePrice(_subtotalCtrl.text),
      deliveryFee: _deliveryFeeCtrl.text.trim(),
      total: _normalizePrice(_totalCtrl.text),
      restaurantTotal: _normalizePrice(_restaurantTotalCtrl.text),
      isPricePending: _isPricePending,
      chatOrderId: _source == 'chat' ? _chatOrderIdCtrl.text.trim() : null,
      deliveryAddressText: _source == 'external'
          ? _addressTextCtrl.text.trim()
          : null,
      userId: _source == 'chat' ? int.tryParse(_userIdCtrl.text.trim()) : null,
      deliveryAddressId: _source == 'chat'
          ? int.tryParse(_addressIdCtrl.text.trim())
          : null,
      restaurantId: _isRegisteredRestaurant
          ? int.tryParse(_restaurantIdCtrl.text.trim())
          : null,
      restaurantNameManual: !_isRegisteredRestaurant
          ? _restaurantNameCtrl.text.trim()
          : null,
      restaurantAddressManual:
          (!_isRegisteredRestaurant && _source == 'external')
          ? _restaurantAddressCtrl.text.trim()
          : null,
      paymentMethod: _paymentMethod,
      notes: _notesCtrl.text.trim(),
      scheduledDeliveryTime: _isScheduled && _scheduledAt != null
          ? _scheduledAt!.toUtc().toIso8601String()
          : null,
    );
  }

  String _normalizePrice(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '0' : trimmed;
  }

  void _applyInitialPrefill() {
    _source = widget.initialSource ?? 'external';

    _phoneCtrl.text = widget.initialPhone ?? '';
    _chatOrderIdCtrl.text = widget.initialChatOrderId ?? '';
    _descriptionCtrl.text = widget.initialDescription ?? '';
    _userIdCtrl.text = widget.initialUserId?.toString() ?? '';
    _addressIdCtrl.text = widget.initialAddressId?.toString() ?? '';
  }

  void _clearForm() {
    for (final c in [
      _phoneCtrl,
      _chatOrderIdCtrl,
      _descriptionCtrl,
      _subtotalCtrl,
      _deliveryFeeCtrl,
      _totalCtrl,
      _restaurantTotalCtrl,
      _notesCtrl,
      _addressTextCtrl,
      _userIdCtrl,
      _addressIdCtrl,
      _restaurantIdCtrl,
      _restaurantDisplayCtrl,
      _restaurantNameCtrl,
      _restaurantAddressCtrl,
    ]) {
      c.clear();
    }
    setState(() {
      _source = widget.lockSource ? widget.initialSource ?? 'chat' : 'external';
      _isRegisteredRestaurant = true;
      _paymentMethod = 'cash';
      _isScheduled = false;
      _isPricePending = false;
      _scheduledAt = null;
      if (widget.lockSource) {
        _applyInitialPrefill();
      }
    });
  }

  // ── Restaurants Picker ────────────────────────────────────────────────────

  Future<void> _openRestaurantsPicker() async {
    await _loadRestaurants();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (_) => _RestaurantsPickerSheet(
        loading: _restaurantsLoading,
        error: _restaurantsError,
        restaurants: _restaurants,
        onRetry: _loadRestaurants,
        onSelect: (r) {
          setState(() {
            _restaurantIdCtrl.text = r.id.toString();
            _restaurantDisplayCtrl.text = r.name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _loadRestaurants() async {
    if (_restaurants.isNotEmpty) return;
    setState(() {
      _restaurantsLoading = true;
      _restaurantsError = null;
    });
    try {
      final data = await _cubit.fetchRestaurants();
      if (!mounted) return;
      setState(() {
        _restaurants = data;
        _restaurantsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _restaurantsLoading = false;
        _restaurantsError = e.toString();
      });
    }
  }
}

// ── Section Cards ─────────────────────────────────────────────────────────────

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.onChanged,
    this.enabled = true,
  });

  final String source;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.source_outlined,
      title: 'Order Source',
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _SegmentedToggle(
            options: const [
              _ToggleOption(
                'external',
                'External',
                Icons.phone_in_talk_outlined,
              ),
              _ToggleOption('chat', 'Chat', Icons.chat_outlined),
            ],
            selected: source,
            onChanged: enabled ? onChanged : (_) {},
            enabled: enabled,
          ),
          const SizedBox(height: AppSpacing.xs),
          TextCustom(
            text: source == 'external'
                ? 'Customer called or sent WhatsApp'
                : 'Customer messaged through app chat',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.source,
    required this.phoneCtrl,
    required this.userIdCtrl,
  });

  final String source;
  final TextEditingController phoneCtrl;
  final TextEditingController userIdCtrl;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.person_outline,
      title: 'Contact Info',
      color: AppColors.info,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FormFieldCustom(
            controller: phoneCtrl,
            label: 'Phone Number',
            hintText: '09XXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm,
            ),
            validator: _required,
          ),
          if (source == 'chat') ...[
            const SizedBox(height: AppSpacing.md),
            FormFieldCustom(
              controller: userIdCtrl,
              label: 'User ID',
              hintText: 'Enter user ID from system',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(
                Icons.badge_outlined,
                color: AppColors.textTertiary,
                size: AppSizes.iconSm,
              ),
              validator: _required,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.source,
    required this.addressTextCtrl,
    required this.addressIdCtrl,
  });

  final String source;
  final TextEditingController addressTextCtrl;
  final TextEditingController addressIdCtrl;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.location_on_outlined,
      title: 'Delivery Address',
      color: AppColors.secondaryDark,
      iconBackgroundColor: AppColors.secondarySurface,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          if (source == 'external')
            FormFieldCustom(
              controller: addressTextCtrl,
              label: 'Full Address',
              hintText: 'e.g. University St, Building 5, Floor 2',
              maxLines: 2,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppColors.textTertiary,
                size: AppSizes.iconSm,
              ),
              validator: _required,
            )
          else
            FormFieldCustom(
              controller: addressIdCtrl,
              label: 'Address ID',
              hintText: 'From user saved addresses',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: AppColors.textTertiary,
                size: AppSizes.iconSm,
              ),
              validator: _required,
            ),
        ],
      ),
    );
  }
}

class _ChatLinkCard extends StatelessWidget {
  const _ChatLinkCard({required this.chatOrderIdCtrl});

  final TextEditingController chatOrderIdCtrl;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.link_outlined,
      title: 'Chat Link',
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FormFieldCustom(
            controller: chatOrderIdCtrl,
            label: 'Chat Order ID',
            hintText: 'e.g. chat_abc123',
            prefixIcon: const Icon(
              Icons.tag_outlined,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm,
            ),
            validator: _required,
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.source,
    required this.isRegistered,
    required this.restaurantDisplayCtrl,
    required this.restaurantIdCtrl,
    required this.restaurantNameCtrl,
    required this.restaurantAddressCtrl,
    required this.onToggle,
    required this.onPickerTap,
  });

  final String source;
  final bool isRegistered;
  final TextEditingController restaurantDisplayCtrl;
  final TextEditingController restaurantIdCtrl;
  final TextEditingController restaurantNameCtrl;
  final TextEditingController restaurantAddressCtrl;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickerTap;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.restaurant,
      title: 'Store',
      color: AppColors.secondaryDark,
      iconBackgroundColor: AppColors.secondarySurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          _SegmentedToggle(
            options: const [
              _ToggleOption(
                'registered',
                'Registered',
                Icons.verified_outlined,
              ),
              _ToggleOption('manual', 'Manual Entry', Icons.edit_outlined),
            ],
            selected: isRegistered ? 'registered' : 'manual',
            onChanged: (v) => onToggle(v == 'registered'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isRegistered) ...[
            InkWell(
              onTap: onPickerTap,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: AbsorbPointer(
                child: FormFieldCustom(
                  controller: restaurantDisplayCtrl,
                  label: 'Restaurant',
                  hintText: 'Tap to select restaurant',
                  readOnly: true,
                  prefixIcon: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.textTertiary,
                    size: AppSizes.iconSm,
                  ),
                  validator: (_) =>
                      restaurantIdCtrl.text.trim().isEmpty ? 'Required' : null,
                ),
              ),
            ),
            if (restaurantIdCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              TextCustom(
                text: 'Selected ID: ${restaurantIdCtrl.text.trim()}',
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ],
          ] else ...[
            FormFieldCustom(
              controller: restaurantNameCtrl,
              label: 'Store Name',
              hintText: 'Enter Store Name',
              prefixIcon: const Icon(
                Icons.restaurant,
                color: AppColors.textTertiary,
                size: AppSizes.iconSm,
              ),
              validator: _required,
            ),
            if (source == 'external') ...[
              const SizedBox(height: AppSpacing.md),
              FormFieldCustom(
                controller: restaurantAddressCtrl,
                label: 'Store Address',
                hintText: 'Enter Store Address',
                prefixIcon: const Icon(
                  Icons.store_outlined,
                  color: AppColors.textTertiary,
                  size: AppSizes.iconSm,
                ),
                isRequired: false,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.descriptionCtrl});

  final TextEditingController descriptionCtrl;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.description_outlined,
      title: 'Order Description',
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FormFieldCustom(
            controller: descriptionCtrl,
            label: 'Items Description',
            hintText: 'e.g. Chicken Burger x2, Large Fries x1',
            maxLines: 3,
            prefixIcon: const Icon(
              Icons.fastfood_outlined,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm,
            ),
            validator: _required,
          ),
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  const _PricingCard({
    required this.isPricePending,
    required this.onPricePendingChanged,
    required this.subtotalCtrl,
    required this.deliveryFeeCtrl,
    required this.totalCtrl,
    required this.restaurantTotalCtrl,
  });

  final bool isPricePending;
  final ValueChanged<bool> onPricePendingChanged;
  final TextEditingController subtotalCtrl;
  final TextEditingController deliveryFeeCtrl;
  final TextEditingController totalCtrl;
  final TextEditingController restaurantTotalCtrl;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.receipt_long_outlined,
      title: 'Pricing (SYP)',
      color: AppColors.success,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isPricePending
                  ? AppColors.warningSurface
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isPricePending
                    ? AppColors.warning.withValues(alpha: 0.18)
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pending_actions_outlined,
                  size: AppSizes.iconSm,
                  color: isPricePending
                      ? AppColors.warningDark
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Expanded(
                  child: TextCustom(
                    text: 'Price Pending',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Switch.adaptive(
                  value: isPricePending,
                  activeThumbColor: AppColors.warning,
                  activeTrackColor: AppColors.warning.withValues(alpha: 0.32),
                  onChanged: onPricePendingChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!isPricePending) ...[
            Row(
              children: [
                Expanded(
                  child: FormFieldCustom(
                    controller: subtotalCtrl,
                    label: 'Subtotal',
                    hintText: '0',
                    isRequired: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FormFieldCustom(
                    controller: deliveryFeeCtrl,
                    label: 'Delivery Fee',
                    hintText: '0',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FormFieldCustom(
                    controller: totalCtrl,
                    label: 'Total (Customer)',
                    hintText: '0',
                    isRequired: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FormFieldCustom(
                    controller: restaurantTotalCtrl,
                    label: 'Restaurant Total',
                    hintText: '0',
                    isRequired: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            FormFieldCustom(
              controller: deliveryFeeCtrl,
              label: 'Delivery Fee',
              hintText: '0',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _required,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isPricePending
                  ? AppColors.warningSurface
                  : AppColors.infoSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  isPricePending ? Icons.info_outline : Icons.info_outline,
                  size: AppSizes.iconSm,
                  color: isPricePending ? AppColors.warningDark : AppColors.info,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextCustom(
                    text: isPricePending
                        ? 'When Price Pending is on, only Delivery Fee is required now. Other prices can be set later.'
                        : 'Total = what customer pays to driver\nRestaurant Total = what driver gives to restaurant',
                    fontSize: 11,
                    color: isPricePending
                        ? AppColors.warningDark
                        : AppColors.infoDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.isScheduled,
    required this.scheduledAt,
    required this.onModeChanged,
    required this.onPickDateTime,
    required this.onClearDateTime,
  });

  final bool isScheduled;
  final DateTime? scheduledAt;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onPickDateTime;
  final VoidCallback onClearDateTime;

  @override
  Widget build(BuildContext context) {
    final display = scheduledAt == null
        ? 'No time selected'
        : DateFormat('yyyy-MM-dd HH:mm').format(scheduledAt!);

    return _SectionCard(
      icon: Icons.schedule_outlined,
      title: 'Delivery Timing',
      color: AppColors.secondaryDark,
      iconBackgroundColor: AppColors.secondarySurface,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          _SegmentedToggle(
            options: const [
              _ToggleOption('now', 'Immediate', Icons.flash_on_outlined),
              _ToggleOption('later', 'Scheduled', Icons.schedule_outlined),
            ],
            selected: isScheduled ? 'later' : 'now',
            onChanged: (value) => onModeChanged(value == 'later'),
          ),
          if (isScheduled) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: onPickDateTime,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      size: AppSizes.iconSm,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextCustom(
                        text: display,
                        fontSize: 13,
                        color: scheduledAt == null
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (scheduledAt != null)
                      GestureDetector(
                        onTap: onClearDateTime,
                        child: const Icon(
                          Icons.close,
                          size: AppSizes.iconSm,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const TextCustom(
              text: 'Scheduled orders must be at least 30 minutes ahead.',
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const _methods = [
    (value: 'cash', label: 'Cash', icon: Icons.money),
    (value: 'card', label: 'Card', icon: Icons.credit_card),
    (value: 'wallet', label: 'Wallet', icon: Icons.account_balance_wallet),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.payment,
      title: 'Payment Method',
      color: AppColors.info,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _methods.map((m) {
              final isSelected = selected == m.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(m.value),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          m.icon,
                          size: AppSizes.iconMd,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        TextCustom(
                          text: m.label,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notesCtrl});

  final TextEditingController notesCtrl;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.note_alt_outlined,
      title: 'Notes (Optional)',
      color: AppColors.textTertiary,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          FormFieldCustom(
            controller: notesCtrl,
            label: 'Notes',
            hintText: 'Any special instructions...',
            maxLines: 2,
            isRequired: false,
            prefixIcon: const Icon(
              Icons.note_outlined,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonLg,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: AppSizes.iconMd,
                height: AppSizes.iconMd,
                child: CircularProgressIndicator(
                  color: AppColors.textOnPrimary,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    size: AppSizes.iconSm,
                    color: AppColors.textOnPrimary,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  TextCustom(
                    text: 'Create Order',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnPrimary,
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Shared Primitives ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.iconBackgroundColor,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  final Color? iconBackgroundColor;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: iconBackgroundColor ?? color.withValues(alpha: 0.1),
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
          ),
          child,
        ],
      ),
    );
  }
}

class _ToggleOption {
  final String value;
  final String label;
  final IconData icon;
  const _ToggleOption(this.value, this.label, this.icon);
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final List<_ToggleOption> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt.value;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!enabled) return;
                if (selected != opt.value) onChanged(opt.value);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (enabled
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.6))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      opt.icon,
                      size: AppSizes.iconSm,
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : (enabled
                                ? AppColors.textSecondary
                                : AppColors.textTertiary),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    TextCustom(
                      text: opt.label,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : (enabled
                                ? AppColors.textSecondary
                                : AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Restaurants Picker Sheet ──────────────────────────────────────────────────

class _RestaurantsPickerSheet extends StatefulWidget {
  const _RestaurantsPickerSheet({
    required this.loading,
    required this.error,
    required this.restaurants,
    required this.onRetry,
    required this.onSelect,
  });

  final bool loading;
  final String? error;
  final List<RestaurantChoice> restaurants;
  final VoidCallback onRetry;
  final ValueChanged<RestaurantChoice> onSelect;

  @override
  State<_RestaurantsPickerSheet> createState() =>
      _RestaurantsPickerSheetState();
}

class _RestaurantsPickerSheetState extends State<_RestaurantsPickerSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.restaurants
        : widget.restaurants
              .where(
                (r) =>
                    r.name.toLowerCase().contains(query) ||
                    r.id.toString().contains(query),
              )
              .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                const Expanded(
                  child: TextCustom(
                    text: 'Select Restaurant',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _buildList(filtered)),
        ],
      ),
    );
  }

  Widget _buildList(List<RestaurantChoice> filtered) {
    if (widget.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (widget.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: AppSpacing.sm),
              TextCustom(
                text: widget.error!,
                fontSize: 13,
                color: AppColors.textSecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: AppSizes.iconSm),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const Center(
        child: TextCustom(
          text: 'No restaurants found',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: filtered.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, i) {
        final r = filtered[i];
        return ListTile(
          tileColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          leading: const Icon(Icons.restaurant),
          title: TextCustom(
            text: r.name,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          subtitle: TextCustom(
            text: 'ID: ${r.id}',
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
          onTap: () => widget.onSelect(r),
        );
      },
    );
  }
}

// ── Validator ─────────────────────────────────────────────────────────────────

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Required' : null;
