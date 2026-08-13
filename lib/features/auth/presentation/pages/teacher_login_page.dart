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

/// Zabira Academy — Teacher Login Page
///
/// Mirrors the Student login design but with teacher-specific branding.
/// Uses the same Firebase Auth but validates the teacher role via Firestore.
class TeacherLoginPage extends StatefulWidget {
  const TeacherLoginPage({super.key});

  @override
  State<TeacherLoginPage> createState() => _TeacherLoginPageState();
}

class _TeacherLoginPageState extends State<TeacherLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthController>();
    final success = await auth.signInAsTeacher(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!success && mounted) {
      context.showErrorSnackBar(auth.errorMessage ?? 'Teacher sign in failed.');
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
                      AppSpacing.x3l,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: const ZabiraLogo(size: LogoSize.medium),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const LearningPortalBadge(),
                        const SizedBox(height: AppSpacing.lg),
                        RichText(
                          text: TextSpan(
                            style: AppTypography.displayLarge,
                            children: const [
                              TextSpan(text: 'Teacher\n'),
                              TextSpan(
                                text: 'Portal',
                                style: TextStyle(color: AppColors.gold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Welcome back! Sign in to manage your classes, students, and learning sessions.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textWhite.withAlpha(180),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Teacher features row
                        _TeacherFeatures(),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.navyDark.withAlpha(15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: AppColors.navyDark,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Teacher Sign In', style: AppTypography.headlineMedium),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Welcome back! Sign in to your teacher portal.',
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.x2l),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                ZabiraTextField(
                                  controller: _emailController,
                                  hintText: 'Email Address',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: AppSpacing.formFieldGap),
                                ZabiraTextField(
                                  controller: _passwordController,
                                  hintText: 'Password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  validator: Validators.loginPassword,
                                  onFieldSubmitted: (_) => _handleSignIn(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          PrimaryButton(
                            label: 'Sign In',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: auth.isLoading,
                            onPressed: _handleSignIn,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          // Notice
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withAlpha(15),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.gold.withAlpha(60)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.gold,
                                  size: 18,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'This portal is for verified Zabira Academy teachers only.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.navyText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.x2l),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go(AppRoutes.login),
                              child: RichText(
                                text: TextSpan(
                                  text: 'Not a teacher? ',
                                  style: AppTypography.bodySmall,
                                  children: [
                                    TextSpan(
                                      text: 'Student / Parent Login',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.gold,
                                        fontSize: 12,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _TeacherFeatures extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.video_camera_front_outlined, 'Live Classes'),
      (Icons.people_outline_rounded, 'My Students'),
      (Icons.bar_chart_rounded, 'Progress Reports'),
    ];
    return Row(
      children: features.map((f) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: features.indexOf(f) < 2 ? AppSpacing.sm : 0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBgOnDark,
                border: Border.all(color: AppColors.cardBorderOnDark),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                children: [
                  Icon(f.$1, color: AppColors.gold, size: 18),
                  const SizedBox(height: 4),
                  Text(
                    f.$2,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
