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
import '../../../../shared/buttons/social_button.dart';
import '../../../../shared/inputs/zabira_text_field.dart';
import '../../../../shared/widgets/zabira_logo.dart';
import '../../auth_controller.dart';
import '../widgets/auth_tab_switcher.dart';
import '../widgets/feature_card.dart';

/// Zabira Academy — Student Sign In Screen
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      final returnTo = auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else {
        context.go(AppRoutes.studentDash);
      }
    } else if (auth.errorMessage != null) {
      context.showErrorSnackBar(auth.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    final success = await auth.signInWithGoogle(portal: 'student');

    if (!mounted) return;

    if (success) {
      final returnTo = auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else {
        context.go(AppRoutes.studentDash);
      }
    } else if (auth.errorMessage != null) {
      final msg = auth.errorMessage!;
      if (!msg.toLowerCase().contains('cancelled')) {
        context.showErrorSnackBar(msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Consumer<AuthController>(
        builder: (context, auth, _) {
          return Stack(
            children: [
              // ── Navy Background Pattern ─────────────────────────────────
              Positioned.fill(child: _NavyPatternBackground()),

              // ── Scrollable Content ───────────────────────────────────────
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Upper Branding Panel ───────────────────────────────
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
                            const SizedBox(height: AppSpacing.xl),
                            const LearningPortalBadge(),
                            const SizedBox(height: AppSpacing.lg),
                            _HeroText(),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Welcome to Zabira Academy — where students and teachers grow '
                              'together through Quran, Arabic, and Islamic studies, anytime and anywhere.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textWhite.withAlpha(180),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.x2l),
                            const StatsRow(),
                          ],
                        ),
                      ),
                    ),

                    // ── White Authentication Panel ─────────────────────────
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
                              // Segmented Control: [ Sign In ] [ Create Account ]
                              AuthTabSwitcher(
                                selectedIndex: 0,
                                tabs: const ['Sign In', 'Create Account'],
                                onTabSelected: (index) {
                                  if (index == 1) {
                                    context.push(AppRoutes.register);
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.x2l),

                              // Heading
                              Text('Welcome back', style: AppTypography.headlineLarge),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Sign in to continue your courses, live classes, and learning progress.',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.x2l),

                              // Form
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
                                      autofillHints: const [AutofillHints.email],
                                      focusNode: _emailFocus,
                                      validator: Validators.email,
                                      onFieldSubmitted: (_) =>
                                          FocusScope.of(context).requestFocus(_passwordFocus),
                                    ),
                                    const SizedBox(height: AppSpacing.formFieldGap),
                                    ZabiraTextField(
                                      controller: _passwordController,
                                      hintText: 'Password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [AutofillHints.password],
                                      focusNode: _passwordFocus,
                                      validator: Validators.loginPassword,
                                      onFieldSubmitted: (_) => _handleSignIn(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Remember Me + Forgot Password
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text('Remember me', style: AppTypography.bodySmall),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () => context.push(AppRoutes.forgotPassword),
                                    child: Text(
                                      'Forgot Password?',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.gold,
                                        fontSize: 13,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Primary Sign In Button
                              PrimaryButton(
                                label: 'Sign In',
                                icon: Icons.arrow_forward_rounded,
                                isLoading: auth.isLoading,
                                onPressed: _handleSignIn,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // OR Divider
                              const _OrDivider(),
                              const SizedBox(height: AppSpacing.lg),

                              // Google Sign In Button
                              SocialButton(
                                label: 'Continue with Google',
                                isLoading: auth.isLoading,
                                onPressed: _handleGoogleSignIn,
                              ),
                              const SizedBox(height: AppSpacing.x2l),

                              // MORE OPTIONS section
                              Center(
                                child: Text(
                                  'MORE OPTIONS',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: NavyButton(
                                      label: 'Login as Teacher',
                                      icon: Icons.school_rounded,
                                      onPressed: () => context.push(AppRoutes.teacherLogin),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: PrimaryButton(
                                      label: 'Back to Home',
                                      icon: Icons.home_rounded,
                                      onPressed: () {
                                        if (GoRouter.of(context).canPop()) {
                                          GoRouter.of(context).pop();
                                        } else {
                                          context.go(AppRoutes.home);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.x2l),

                              // Footer navigation link
                              Center(
                                child: RichText(
                                  text: TextSpan(
                                    text: 'New to Zabira Academy? ',
                                    style: AppTypography.bodySmall,
                                    children: [
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () => context.push(AppRoutes.register),
                                          child: Text(
                                            'Create an account',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.gold,
                                              fontSize: 12,
                                              letterSpacing: 0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
              ),

              if (auth.isLoading)
                const Positioned.fill(child: AbsorbPointer(child: SizedBox.shrink())),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HeroText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppTypography.displayLarge,
        children: const [
          TextSpan(text: 'Knowledge that '),
          TextSpan(
            text: 'elevates',
            style: TextStyle(color: AppColors.gold),
          ),
          TextSpan(text: '\nevery journey'),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderMedium)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderMedium)),
      ],
    );
  }
}

class _NavyPatternBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PatternPainter());
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height * 0.65; y += spacing) {
        final path = Path()
          ..moveTo(x + spacing / 2, y)
          ..lineTo(x + spacing, y + spacing / 2)
          ..lineTo(x + spacing / 2, y + spacing)
          ..lineTo(x, y + spacing / 2)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
