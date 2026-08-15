import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/buttons/primary_button.dart';
import '../../../../shared/inputs/zabira_text_field.dart';
import '../../../../shared/widgets/zabira_logo.dart';
import '../../auth_controller.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    final success = await auth.resetPassword(
      token: _tokenController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() => _success = true);
    } else {
      context.showErrorSnackBar(auth.errorMessage ?? 'Password reset failed. Invalid or expired token.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.x2l,
                  AppSpacing.screenHorizontal,
                  AppSpacing.x3l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.home),
                      child: const ZabiraLogo(size: LogoSize.medium),
                    ),
                    const SizedBox(height: AppSpacing.x2l),
                    RichText(
                      text: TextSpan(
                        style: AppTypography.displayMedium,
                        children: const [
                          TextSpan(text: 'Set New '),
                          TextSpan(
                            text: 'Password',
                            style: TextStyle(color: AppColors.gold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Enter your reset token and your new password.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textWhite.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.x2l),
                    topRight: Radius.circular(AppRadius.x2l),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    AppSpacing.x2l,
                    AppSpacing.screenHorizontal,
                    AppSpacing.x3l + context.bottomPadding,
                  ),
                  child: _success ? _buildSuccess() : _buildForm(auth),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthController auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New Password', style: AppTypography.headlineLarge),
          const SizedBox(height: AppSpacing.sm),
          Text('Your new password must be at least 8 characters long.', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.x2l),

          ZabiraTextField(
            controller: _tokenController,
            hintText: 'Reset Token *',
            prefixIcon: Icons.vpn_key_outlined,
            validator: Validators.required,
          ),
          const SizedBox(height: AppSpacing.formFieldGap),

          ZabiraTextField(
            controller: _passwordController,
            hintText: 'New Password *',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: Validators.newPassword,
          ),
          const SizedBox(height: AppSpacing.formFieldGap),

          ZabiraTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm New Password *',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: Validators.confirmPassword(_passwordController.text),
          ),
          const SizedBox(height: AppSpacing.xl),

          PrimaryButton(
            label: 'Reset Password',
            isLoading: auth.isLoading,
            onPressed: _handleReset,
          ),
          const SizedBox(height: AppSpacing.lg),

          Center(
            child: TextButton.icon(
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
              label: Text(
                'Back to Sign In',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.success.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Password Reset Successful!', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your password has been changed. You can now sign in with your new credentials.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x3l),
        PrimaryButton(label: 'Sign In Now', onPressed: () => context.go(AppRoutes.login)),
      ],
    );
  }
}
