import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../auth_controller.dart';
import 'auth_tab_switcher.dart';

/// Shows the sign-in / create-account sheet sliding up over the current page.
void showAuthBottomSheet(BuildContext context, {int initialTab = 0}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    useSafeArea: false,
    enableDrag: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<AuthController>(),
      child: _AuthBottomSheet(initialTab: initialTab),
    ),
  );
}

// =============================================================================
// Bottom Sheet Widget
// =============================================================================
class _AuthBottomSheet extends StatefulWidget {
  const _AuthBottomSheet({this.initialTab = 0});
  final int initialTab;

  @override
  State<_AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<_AuthBottomSheet> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  void _switchTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.90,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      snap: true,
      snapSizes: const [0.90, 0.97],
      builder: (ctx, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 30,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Drag handle ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Tab switcher ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    8,
                    AppSpacing.screenHorizontal,
                    0,
                  ),
                  child: AuthTabSwitcher(
                    selectedIndex: _selectedTab,
                    tabs: const ['Sign In', 'Create Account'],
                    onTabSelected: _switchTab,
                  ),
                ),

                // ── Scrollable form with smooth AnimatedCrossFade ──────────────
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenHorizontal,
                      AppSpacing.lg,
                      AppSpacing.screenHorizontal,
                      AppSpacing.x3l + bottom + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Consumer<AuthController>(
                      builder: (context, auth, _) {
                        return AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          firstCurve: Curves.easeInOut,
                          secondCurve: Curves.easeInOut,
                          crossFadeState: _selectedTab == 0
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: _SheetSignInForm(
                            auth: auth,
                            onSwitchToRegister: () => _switchTab(1),
                          ),
                          secondChild: _SheetRegisterForm(
                            auth: auth,
                            onSwitchToSignIn: () => _switchTab(0),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sign In Form (sheet version)
// =============================================================================
class _SheetSignInForm extends StatefulWidget {
  const _SheetSignInForm({required this.auth, required this.onSwitchToRegister});
  final AuthController auth;
  final VoidCallback onSwitchToRegister;

  @override
  State<_SheetSignInForm> createState() => _SheetSignInFormState();
}

class _SheetSignInFormState extends State<_SheetSignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _rememberMe = false;
  bool _isSigningIn = false;
  bool _isGoogleSigningIn = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isSigningIn || _isGoogleSigningIn) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSigningIn = true);
    final success = await widget.auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSigningIn = false);

    if (success) {
      Navigator.of(context).pop(); // close sheet
      final returnTo = widget.auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      }
    } else if (widget.auth.errorMessage != null) {
      context.showErrorSnackBar(widget.auth.errorMessage!);
    }
  }

  Future<void> _googleSignIn() async {
    if (_isSigningIn || _isGoogleSigningIn) return;

    setState(() => _isGoogleSigningIn = true);
    final success = await widget.auth.signInWithGoogle(portal: 'student');
    if (!mounted) return;
    setState(() => _isGoogleSigningIn = false);

    if (success) {
      Navigator.of(context).pop();
      final returnTo = widget.auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      }
    } else if (widget.auth.errorMessage != null) {
      final msg = widget.auth.errorMessage!;
      if (!msg.toLowerCase().contains('cancelled')) {
        context.showErrorSnackBar(msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Welcome back', style: AppTypography.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Sign in to continue your courses and learning progress.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),

        Form(
          key: _formKey,
          child: Column(
            children: [
              ZabiraTextField(
                controller: _emailCtrl,
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
                controller: _passwordCtrl,
                hintText: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                focusNode: _passwordFocus,
                validator: Validators.loginPassword,
                onFieldSubmitted: (_) => _signIn(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

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
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.forgotPassword);
              },
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
        const SizedBox(height: AppSpacing.lg),

        PrimaryButton(
          label: 'Sign In',
          icon: Icons.arrow_forward_rounded,
          isLoading: _isSigningIn,
          onPressed: _signIn,
        ),
        const SizedBox(height: AppSpacing.md),

        _OrDivider(),
        const SizedBox(height: AppSpacing.md),

        SocialButton(
          label: 'Continue with Google',
          isLoading: _isGoogleSigningIn,
          onPressed: _googleSignIn,
        ),
        const SizedBox(height: AppSpacing.xl),

        Center(
          child: GestureDetector(
            onTap: widget.onSwitchToRegister,
            child: RichText(
              text: TextSpan(
                text: 'New to Zabira Academy? ',
                style: AppTypography.bodySmall,
                children: [
                  TextSpan(
                    text: 'Create an account',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Create Account Form (Full registration fields matching API & Reference)
// =============================================================================
class _SheetRegisterForm extends StatefulWidget {
  const _SheetRegisterForm({required this.auth, required this.onSwitchToSignIn});
  final AuthController auth;
  final VoidCallback onSwitchToSignIn;

  @override
  State<_SheetRegisterForm> createState() => _SheetRegisterFormState();
}

class _SheetRegisterFormState extends State<_SheetRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String _gender = 'Male';
  bool _acceptTerms = true;
  bool _isRegistering = false;
  bool _isGoogleSigningIn = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _dobCtrl.dispose();
    _countryCtrl.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
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
              onPrimary: AppColors.gold,
              onSurface: AppColors.navyDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final y = picked.year.toString().padLeft(4, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      setState(() {
        _dobCtrl.text = '$y-$m-$d';
      });
    }
  }

  Future<void> _register() async {
    if (_isRegistering || _isGoogleSigningIn) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      context.showErrorSnackBar('Please accept the Terms & Conditions.');
      return;
    }

    final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();

    setState(() => _isRegistering = true);
    final success = await widget.auth.register(
      fullName: fullName,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmPasswordCtrl.text,
      mobile: _mobileCtrl.text.trim(),
      gender: _gender,
      dateOfBirth: _dobCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      acceptTerms: _acceptTerms,
    );
    if (!mounted) return;
    setState(() => _isRegistering = false);

    if (success) {
      if (widget.auth.isAuthenticated) {
        Navigator.of(context).pop();
        final returnTo = widget.auth.consumePendingReturnTo();
        if (returnTo != null && returnTo.isNotEmpty) {
          context.go(returnTo);
        }
      } else {
        context.showSuccessSnackBar('Account created! Please sign in.');
        widget.onSwitchToSignIn();
      }
    } else {
      context.showErrorSnackBar(widget.auth.errorMessage ?? 'Registration failed.');
    }
  }

  Future<void> _googleSignIn() async {
    if (_isRegistering || _isGoogleSigningIn) return;

    setState(() => _isGoogleSigningIn = true);
    final success = await widget.auth.signInWithGoogle(portal: 'student');
    if (!mounted) return;
    setState(() => _isGoogleSigningIn = false);

    if (success) {
      Navigator.of(context).pop();
      final returnTo = widget.auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      }
    } else if (widget.auth.errorMessage != null) {
      final msg = widget.auth.errorMessage!;
      if (!msg.toLowerCase().contains('cancelled')) {
        context.showErrorSnackBar(msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Create your account', style: AppTypography.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Join Zabira Academy and begin your learning journey.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),

        SocialButton(
          label: 'Continue with Google',
          isLoading: _isGoogleSigningIn,
          onPressed: _googleSignIn,
        ),
        const SizedBox(height: AppSpacing.md),
        _OrDivider(),
        const SizedBox(height: AppSpacing.md),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. First Name & Last Name ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: ZabiraTextField(
                      controller: _firstNameCtrl,
                      hintText: 'First Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ZabiraTextField(
                      controller: _lastNameCtrl,
                      hintText: 'Last Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // ── 2. Email Address ───────────────────────────────────────────
              ZabiraTextField(
                controller: _emailCtrl,
                hintText: 'Email Address *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // ── 3. Mobile Number ───────────────────────────────────────────
              ZabiraTextField(
                controller: _mobileCtrl,
                hintText: 'Mobile Number *',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Mobile number required' : null,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // ── 4. Gender & Date of Birth ──────────────────────────────────
              Row(
                children: [
                  // Gender Dropdown
                  Expanded(
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _gender,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                                style: GoogleFonts.outfit(fontSize: 13.5, color: AppColors.navyDark),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _gender = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Date of Birth
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _dobCtrl.text.isNotEmpty ? _dobCtrl.text : 'DOB (Optional)',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: _dobCtrl.text.isNotEmpty ? AppColors.navyDark : AppColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // ── 5. Location Details (Country, State, City) ──────────────────
              Row(
                children: [
                  Expanded(
                    child: ZabiraTextField(
                      controller: _countryCtrl,
                      hintText: 'Country *',
                      prefixIcon: Icons.public_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZabiraTextField(
                      controller: _stateCtrl,
                      hintText: 'State *',
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ZabiraTextField(
                      controller: _cityCtrl,
                      hintText: 'City *',
                      prefixIcon: Icons.apartment_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // ── 6. Password & Confirm Password ─────────────────────────────
              ZabiraTextField(
                controller: _passwordCtrl,
                hintText: 'Password *',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: Validators.newPassword,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              ZabiraTextField(
                controller: _confirmPasswordCtrl,
                hintText: 'Confirm Password *',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── 7. Terms & Conditions Checkbox ────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RichText(
                text: TextSpan(
                  text: 'I accept the ',
                  style: AppTypography.bodySmall,
                  children: [
                    TextSpan(
                      text: 'Terms & Conditions *',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gold,
                        fontSize: 12,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        PrimaryButton(
          label: 'Create Account',
          icon: Icons.arrow_forward_rounded,
          isLoading: _isRegistering,
          onPressed: _register,
        ),
        const SizedBox(height: AppSpacing.lg),

        Center(
          child: GestureDetector(
            onTap: widget.onSwitchToSignIn,
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: AppTypography.bodySmall,
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Divider
// =============================================================================
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderLight, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderLight, height: 1)),
      ],
    );
  }
}
