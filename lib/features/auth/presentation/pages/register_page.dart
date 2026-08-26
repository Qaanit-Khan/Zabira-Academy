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
import '../widgets/location_fields.dart';

/// Zabira Academy — Create Account Screen
///
/// Native mobile adaptation of the web registration form.
/// Includes all required fields in a vertically scrollable layout.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Field Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = 'Male';
  bool _acceptTerms = false;

  bool get _hasSelectedCountry => zabiraCountryOptions.any(
    (country) =>
        country.toLowerCase() == _countryController.text.trim().toLowerCase(),
  );

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyDark,
              onPrimary: AppColors.textWhite,
              surface: AppColors.surfaceWhite,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptTerms) {
      context.showErrorSnackBar(
        'Please accept the Terms & Conditions to proceed.',
      );
      return;
    }

    final fullName =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
            .trim();

    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    final success = await auth.register(
      fullName: fullName,
      email: _emailController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      mobile: _mobileController.text.trim(),
      gender: _selectedGender,
      dateOfBirth: _dobController.text.trim(),
      country: _countryController.text.trim(),
      state: _stateController.text.trim(),
      city: _cityController.text.trim(),
      acceptTerms: _acceptTerms,
    );

    if (!mounted) return;

    if (success) {
      if (auth.isAuthenticated) {
        final returnTo = auth.consumePendingReturnTo();
        if (returnTo != null && returnTo.isNotEmpty) {
          context.go(returnTo);
        } else {
          context.go(AppRoutes.studentDash);
        }
      } else {
        context.showSuccessSnackBar(
          'Account created successfully! Please sign in.',
        );
        context.go(AppRoutes.login);
      }
    } else {
      context.showErrorSnackBar(
        auth.errorMessage ?? 'Registration failed. Please check your details.',
      );
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
      context.showSuccessSnackBar(
        'Welcome to Zabira Academy, ${auth.user?.displayName ?? "Student"}!',
      );
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
              // ── Background Pattern ───────────────────────────────────────
              Positioned.fill(child: _NavyPatternBackground()),

              // ── Main Scroll View ─────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Upper Branding Header ───────────────────────────────
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
                            RichText(
                              text: TextSpan(
                                style: AppTypography.displayMedium,
                                children: const [
                                  TextSpan(text: 'Join the '),
                                  TextSpan(
                                    text: 'Zabira',
                                    style: TextStyle(color: AppColors.gold),
                                  ),
                                  TextSpan(text: '\ncommunity'),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Start your journey of Quran, Arabic, and Islamic learning today.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textWhite.withAlpha(180),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── White Registration Form Card (Scrollable) ───────────
                    SliverToBoxAdapter(
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
                              // Top Segmented Control: [ Sign In ] [ Create Account ]
                              AuthTabSwitcher(
                                selectedIndex: 1,
                                tabs: const ['Sign In', 'Create Account'],
                                onTabSelected: (index) {
                                  if (index == 0) {
                                    if (GoRouter.of(context).canPop()) {
                                      GoRouter.of(context).pop();
                                    } else {
                                      context.go(AppRoutes.login);
                                    }
                                  }
                                },
                              ),
                              const SizedBox(height: AppSpacing.x2l),

                              // Form Headings
                              Text(
                                'Create your account',
                                style: AppTypography.headlineLarge,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Join Zabira Academy and begin your learning journey today.',
                                style: AppTypography.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Social Registration Button
                              SocialButton(
                                label: 'Continue with Google',
                                isLoading: auth.isGoogleLoading,
                                onPressed: auth.isLoading
                                    ? null
                                    : _handleGoogleSignIn,
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              const _OrDivider(),
                              const SizedBox(height: AppSpacing.xl),

                              // Section Header: REGISTRATION DETAILS
                              Text(
                                'REGISTRATION DETAILS',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.gold,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Registration Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // 1. First Name * & Last Name *
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ZabiraTextField(
                                            controller: _firstNameController,
                                            hintText: 'First Name *',
                                            prefixIcon:
                                                Icons.person_outline_rounded,
                                            validator: Validators.required,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: ZabiraTextField(
                                            controller: _lastNameController,
                                            hintText: 'Last Name *',
                                            prefixIcon:
                                                Icons.person_outline_rounded,
                                            validator: Validators.required,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 2. Email Address *
                                    ZabiraTextField(
                                      controller: _emailController,
                                      hintText: 'Email Address *',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: Validators.email,
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 3. Mobile Number *
                                    ZabiraTextField(
                                      controller: _mobileController,
                                      hintText: 'Mobile Number *',
                                      prefixIcon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: Validators.required,
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 4. Gender * & Date of Birth (Optional)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _GenderDropdown(
                                            value: _selectedGender,
                                            onChanged: (v) {
                                              if (v != null) {
                                                setState(
                                                  () => _selectedGender = v,
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _selectDateOfBirth,
                                            child: AbsorbPointer(
                                              child: ZabiraTextField(
                                                controller: _dobController,
                                                hintText: 'DOB (Optional)',
                                                prefixIcon: Icons
                                                    .calendar_today_outlined,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 5. Country *
                                    CountrySelectionField(
                                      controller: _countryController,
                                      onSelected: (_) {
                                        setState(() {
                                          _stateController.clear();
                                          _cityController.clear();
                                        });
                                      },
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 6. State * & City *
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DependentLocationField(
                                            controller: _stateController,
                                            hintText: 'State *',
                                            prefixIcon: Icons.map_outlined,
                                            enabled: _hasSelectedCountry,
                                            disabledMessage:
                                                'Please select a country first.',
                                            onChanged: (_) {
                                              if (_cityController
                                                  .text
                                                  .isNotEmpty) {
                                                _cityController.clear();
                                              }
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: DependentLocationField(
                                            controller: _cityController,
                                            hintText: 'City *',
                                            prefixIcon:
                                                Icons.location_city_outlined,
                                            enabled: _stateController.text
                                                .trim()
                                                .isNotEmpty,
                                            disabledMessage:
                                                'Select state first.',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 7. Password *
                                    ZabiraTextField(
                                      controller: _passwordController,
                                      hintText: 'Password *',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator: Validators.newPassword,
                                    ),
                                    const SizedBox(
                                      height: AppSpacing.formFieldGap,
                                    ),

                                    // 8. Confirm Password *
                                    ZabiraTextField(
                                      controller: _confirmPasswordController,
                                      hintText: 'Confirm Password *',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      validator: Validators.confirmPassword(
                                        _passwordController.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Terms Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _acceptTerms,
                                      onChanged: (v) => setState(
                                        () => _acceptTerms = v ?? false,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySmall,
                                        children: [
                                          const TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'Terms & Conditions *',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                                  color: AppColors.gold,
                                                  fontSize: 12,
                                                  letterSpacing: 0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Create Account Primary Button
                              PrimaryButton(
                                label: 'Create Account',
                                isLoading: auth.isLoading,
                                onPressed: _handleRegister,
                              ),
                              const SizedBox(height: AppSpacing.x2l),

                              // Bottom Footer Link -> Sign In
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    if (GoRouter.of(context).canPop()) {
                                      GoRouter.of(context).pop();
                                    } else {
                                      context.go(AppRoutes.login);
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an account? ',
                                      style: AppTypography.bodySmall,
                                      children: [
                                        TextSpan(
                                          text: 'Sign In',
                                          style: AppTypography.labelSmall
                                              .copyWith(
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
              ),

              if (auth.isLoading)
                const Positioned.fill(
                  child: AbsorbPointer(child: SizedBox.shrink()),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      style: AppTypography.inputText,
      dropdownColor: AppColors.surfaceWhite,
      decoration: const InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: AppSpacing.sm),
          child: Icon(
            Icons.person_pin_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 48, minHeight: 48),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male *')),
        DropdownMenuItem(value: 'Female', child: Text('Female *')),
        DropdownMenuItem(value: 'Other', child: Text('Other *')),
      ],
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
