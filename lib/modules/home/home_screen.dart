import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superdriver_admin/core/locator.dart';
import 'package:superdriver_admin/core/shared_pref.dart';
import 'package:superdriver_admin/modules/add_order/add_order_screen.dart';
import 'package:superdriver_admin/modules/admin_work_hours/admin_work_hours_screen.dart';
import 'package:superdriver_admin/modules/chat/admin_chats_screen.dart';
import 'package:superdriver_admin/modules/login/login_screen.dart';
import 'package:superdriver_admin/modules/new_order/new_order_screen.dart';
import 'package:superdriver_admin/modules/notification/notification_screen.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

import 'cubit/home_cubit.dart';
import 'cubit/home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nav model
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({required this.icon, required this.title});

  final IconData icon;
  final String title;
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

// Pages are kept as a getter (not a top-level list) because StatelessWidget
// constructors run at widget-tree build time. A top-level `final _pages`
// initialised at program start can cause issues with context-dependent widgets.
List<Widget> _buildPages() => [
  NewOrdersScreen(),
  ManualOrderScreen(),
  AdminWorkHoursScreen(),
  AdminChatsScreen(),
  NotificationsScreen(),
];

const _navItems = <_NavItem>[
  _NavItem(icon: Icons.list_alt_rounded, title: 'New Orders'),
  _NavItem(icon: Icons.add_circle_outline, title: 'Add Manual Order'),
  _NavItem(icon: Icons.access_time_rounded, title: 'Work Hours'),
  _NavItem(icon: Icons.chat_bubble_outline, title: 'Chats'),
  _NavItem(icon: Icons.notifications_outlined, title: 'Notifications'),
];

const double _avatarRingPadding = AppSpacing.xxs;

// ─────────────────────────────────────────────────────────────────────────────
// HomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final HomeCubit _homeCubit;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit()..refreshAdminFcmToken();
    _pages = _buildPages();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // close drawer
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const TextCustom(
          text: 'Sign Out',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        content: const TextCustom(
          text: 'Are you sure you want to sign out?',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TextCustom(
              text: 'Cancel',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _homeCubit.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: const TextCustom(
              text: 'Sign Out',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is HomeLoggedOut && context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: TextCustom(
              text: _navItems[_selectedIndex].title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: false,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          drawer: _AppDrawer(
            selectedIndex: _selectedIndex,
            onItemTap: _onNavTap,
            onLogout: () => _showLogoutDialog(context),
          ),
          body: _pages[_selectedIndex],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer
// ─────────────────────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.selectedIndex,
    required this.onItemTap,
    required this.onLogout,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTap;
  final VoidCallback onLogout;

  ({String userName, String userPhone}) _loadUserInfo() {
    String firstName = '';
    String lastName = '';
    String userPhone = '';

    try {
      final prefs = locator<SharedPreferencesRepository>();
      firstName = (prefs.getData(key: 'user_first_name') ?? '')
          .toString()
          .trim();
      lastName = (prefs.getData(key: 'user_last_name') ?? '').toString().trim();
      userPhone = (prefs.getData(key: 'user_phone') ?? '').toString().trim();
    } catch (_) {}

    final fullName = '$firstName $lastName'.trim();
    return (
      userName: fullName.isNotEmpty ? fullName : 'Admin',
      userPhone: userPhone.isNotEmpty ? userPhone : 'Welcome back',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = _loadUserInfo();

    return Drawer(
      backgroundColor: AppColors.primarySoft,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(
              userName: userInfo.userName,
              userPhone: userInfo.userPhone,
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.xs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextCustom(
                  text: 'MENU',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: _navItems.length,
                itemBuilder: (context, index) => _DrawerTile(
                  item: _navItems[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onItemTap(index),
                ),
              ),
            ),
            _DrawerFooter(onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer Header
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.userName, required this.userPhone});

  final String userName;
  final String userPhone;

  @override
  Widget build(BuildContext context) {
    const double ringSize = AppSizes.avatarLg + _avatarRingPadding * 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: ColorsCustom.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar with glowing ring ──────────────────────────────────────
          Stack(
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: _avatarRingPadding,
                left: _avatarRingPadding,
                child: Container(
                  width: AppSizes.avatarLg,
                  height: AppSizes.avatarLg,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: Image.asset(
                    'assets/icons/support_avatar.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: AppSpacing.md),

          // ── User info ─────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextCustom(
                  text: userName,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textOnPrimary,
                  maxLines: 1,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 12,
                      color: AppColors.textOnPrimary.withValues(alpha: 0.65),
                    ),
                    const SizedBox(width: 4),
                    TextCustom(
                      text: userPhone,
                      fontSize: 12,
                      color: AppColors.textOnPrimary.withValues(alpha: 0.75),
                      maxLines: 1,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.round),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: AppColors.primaryDark,
                      ),
                      SizedBox(width: 4),
                      TextCustom(
                        text: 'Admin',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Drawer Tile
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border(
          left: !isRtl && isSelected
              ? const BorderSide(color: AppColors.primary, width: 3)
              : BorderSide.none,
          right: isRtl && isSelected
              ? const BorderSide(color: AppColors.primary, width: 3)
              : BorderSide.none,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        leading: AnimatedContainer(
          duration: AppDurations.fast,
          width: AppSizes.buttonSm,
          height: AppSizes.buttonSm,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          ),
          child: Icon(
            item.icon,
            size: AppSizes.iconSm,
            color: isSelected
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
          ),
        ),
        title: TextCustom(
          text: item.title,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logout Tile
// ─────────────────────────────────────────────────────────────────────────────

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          leading: Container(
            width: AppSizes.buttonSm,
            height: AppSizes.buttonSm,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.logout_rounded,
              size: AppSizes.iconSm,
              color: AppColors.error,
            ),
          ),
          title: const TextCustom(
            text: 'Sign Out',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer Footer
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Center(
            child: Container(
              width: 60,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
            ),
          ),
        ),
        _LogoutTile(onTap: onLogout),
        const SizedBox(height: AppSpacing.sm),
        const TextCustom(
          text: 'SuperDriver Admin',
          fontSize: 11,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
