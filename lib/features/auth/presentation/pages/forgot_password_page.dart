import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/inputs/zabira_text_field.dart';
import '../../../../shared/buttons/primary_button.dart';
import '../../../../shared/widgets/zabira_logo.dart';
import '../../auth_controller.dart';
import '../../../../app/router.dart';

/// Zabira Academy — Forgot Password Page
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final success = await auth.sendPasswordReset(_emailController.text);
    if (success && mounted) {
      setState(() => _sent = true);
    } else if (!success && mounted) {
      context.showErrorSnackBar(auth.errorMessage ?? 'Failed to send reset email.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Consumer<AuthController>(
        builder: (context, auth, _) {
          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.x2l,
                      AppSpacing.screenHorizontal,
                      AppSpacing.x4l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: const ZabiraLogo(size: LogoSize.medium),
                        ),
                        const SizedBox(height: AppSpacing.x3l),
                        RichText(
                          text: TextSpan(
                            style: AppTypography.displayMedium,
                            children: const [
                              TextSpan(text: 'Reset your\n'),
                              TextSpan(
                                text: 'password',
                                style: TextStyle(color: AppColors.gold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          "Enter your email address and we'll send you a link to reset your password.",
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
                      child: _sent
                          ? _SuccessState(email: _emailController.text)
                          : _FormState(
                              formKey: _formKey,
                              emailController: _emailController,
                              isLoading: auth.isLoading,
                              onSend: _handleSend,
                              onBack: () => context.go(AppRoutes.login),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FormState extends StatelessWidget {
  const _FormState({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSend,
    required this.onBack,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reset Password', style: AppTypography.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text("We'll send a reset link to your email.", style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.x2l),
        Form(
          key: formKey,
          child: ZabiraTextField(
            controller: emailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Send Reset Link', isLoading: isLoading, onPressed: onSend),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.textSecondary),
            label: Text(
              'Back to Sign In',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: AppColors.success.withAlpha(20), shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Reset link sent!', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a password reset link to\n$email',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x3l),
        PrimaryButton(label: 'Back to Sign In', onPressed: () => context.go(AppRoutes.login)),
      ],
    );
  }
}
