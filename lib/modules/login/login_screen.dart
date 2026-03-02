import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:superdriver_admin/modules/home/home_screen.dart';
import 'package:superdriver_admin/modules/login/cubit/login_cubit.dart';
import 'package:superdriver_admin/modules/login/cubit/login_state.dart';
import 'package:superdriver_admin/shared/themes/style.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => LoginCubit(), child: const _LoginView());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login View
// ─────────────────────────────────────────────────────────────────────────────

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final cubit = LoginCubit.get(context);
    final isSmall = MediaQuery.of(context).size.height < 700;

    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        if (state is LoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.background,
                  AppColors.background,
                  AppColors.primary.withValues(alpha: 0.07),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                    vertical: isSmall ? AppSpacing.md : AppSpacing.xxl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: cubit.formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Logo(isSmall: isSmall),
                          SizedBox(
                            height: isSmall ? AppSpacing.md : AppSpacing.xl,
                          ),
                          _Header(isSmall: isSmall),
                          SizedBox(
                            height: isSmall ? AppSpacing.xl : AppSpacing.xxxl,
                          ),
                          _FormCard(
                            cubit: cubit,
                            isSmall: isSmall,
                            isLoading: isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo
// ─────────────────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo({required this.isSmall});

  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 90.0 : 120.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Image.asset(
          'assets/icons/login_illustration.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.isSmall});

  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextCustom(
          text: 'Control Panel',
          fontSize: isSmall ? 22 : 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        const SizedBox(height: AppSpacing.xs),
        const TextCustom(
          text: 'Sign in to continue',
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Card
// ─────────────────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.cubit,
    required this.isSmall,
    required this.isLoading,
  });

  final LoginCubit cubit;
  final bool isSmall;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormFieldCustom(
            controller: cubit.phoneController,
            label: 'Phone Number',
            hintText: '09XXXXXXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm,
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please enter your phone number'
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          FormFieldCustom(
            controller: cubit.passwordController,
            label: 'Password',
            hintText: '••••••••',
            isPassword: true,
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.textTertiary,
              size: AppSizes.iconSm,
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Please enter your password'
                : null,
          ),
          SizedBox(height: isSmall ? AppSpacing.xl : AppSpacing.xxl),
          SizedBox(
            height: AppSizes.buttonLg,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (cubit.formKey.currentState!.validate()) {
                        cubit.loginUser();
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(
                        color: AppColors.textOnPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const TextCustom(
                      text: 'Sign In',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
