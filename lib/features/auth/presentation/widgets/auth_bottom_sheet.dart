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
/// The background stays visible (transparent barrier) — the home page shows
/// through behind the white panel.
void showAuthBottomSheet(BuildContext context, {int initialTab = 0}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
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
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      snap: true,
      snapSizes: const [0.88, 0.97],
      builder: (ctx, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              // ~88% opaque white — lets home page show through subtly
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 30,
                  offset: Offset(0, -8),
                ),
              ],
            ),
            child: Column(
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
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
                12,
                AppSpacing.screenHorizontal,
                0,
              ),
              child: AuthTabSwitcher(
                selectedIndex: _selectedTab,
                tabs: const ['Sign In', 'Create Account'],
                onTabSelected: _switchTab,
              ),
            ),

            // ── Scrollable form ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.x2l,
                  AppSpacing.screenHorizontal,
                  AppSpacing.x3l + bottom + MediaQuery.of(context).padding.bottom,
                ),
                child: Consumer<AuthController>(
                  builder: (context, auth, _) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedTab),
                        child: _selectedTab == 0
                            ? _SheetSignInForm(
                                auth: auth,
                                onSwitchToRegister: () => _switchTab(1),
                              )
                            : _SheetRegisterForm(
                                auth: auth,
                                onSwitchToSignIn: () => _switchTab(0),
                              ),
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
  final _formKey          = GlobalKey<FormState>();
  final _emailCtrl        = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _emailFocus       = FocusNode();
  final _passwordFocus    = FocusNode();
  bool  _rememberMe       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (widget.auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await widget.auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
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
    if (widget.auth.isLoading) return;
    final success = await widget.auth.signInWithGoogle(portal: 'student');
    if (!mounted) return;
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
        const SizedBox(height: AppSpacing.x2l),

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
        const SizedBox(height: AppSpacing.md),

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
        const SizedBox(height: AppSpacing.xl),

        PrimaryButton(
          label: 'Sign In',
          icon: Icons.arrow_forward_rounded,
          isLoading: widget.auth.isLoading,
          onPressed: _signIn,
        ),
        const SizedBox(height: AppSpacing.lg),

        _OrDivider(),
        const SizedBox(height: AppSpacing.lg),

        SocialButton(
          label: 'Continue with Google',
          isLoading: widget.auth.isLoading,
          onPressed: _googleSignIn,
        ),
        const SizedBox(height: AppSpacing.x2l),

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
// Create Account Form (sheet version — simplified)
// =============================================================================
class _SheetRegisterForm extends StatefulWidget {
  const _SheetRegisterForm({required this.auth, required this.onSwitchToSignIn});
  final AuthController auth;
  final VoidCallback onSwitchToSignIn;

  @override
  State<_SheetRegisterForm> createState() => _SheetRegisterFormState();
}

class _SheetRegisterFormState extends State<_SheetRegisterForm> {
  final _formKey                   = GlobalKey<FormState>();
  final _firstNameCtrl             = TextEditingController();
  final _lastNameCtrl              = TextEditingController();
  final _emailCtrl                 = TextEditingController();
  final _mobileCtrl                = TextEditingController();
  final _passwordCtrl              = TextEditingController();
  final _confirmPasswordCtrl       = TextEditingController();
  bool  _acceptTerms               = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (widget.auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptTerms) {
      context.showErrorSnackBar('Please accept the Terms & Conditions.');
      return;
    }
    final fullName =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final success = await widget.auth.register(
      fullName: fullName,
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      confirmPassword: _confirmPasswordCtrl.text,
      mobile: _mobileCtrl.text.trim(),
      gender: 'Male',
      dateOfBirth: '',
      country: '',
      state: '',
      city: '',
      acceptTerms: _acceptTerms,
    );
    if (!mounted) return;
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
    if (widget.auth.isLoading) return;
    final success = await widget.auth.signInWithGoogle(portal: 'student');
    if (!mounted) return;
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
        const SizedBox(height: AppSpacing.xl),

        SocialButton(
          label: 'Continue with Google',
          isLoading: widget.auth.isLoading,
          onPressed: _googleSignIn,
        ),
        const SizedBox(height: AppSpacing.lg),
        _OrDivider(),
        const SizedBox(height: AppSpacing.xl),

        Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ZabiraTextField(
                      controller: _firstNameCtrl,
                      hintText: 'First Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.required,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ZabiraTextField(
                      controller: _lastNameCtrl,
                      hintText: 'Last Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              ZabiraTextField(
                controller: _emailCtrl,
                hintText: 'Email Address *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
              ZabiraTextField(
                controller: _mobileCtrl,
                hintText: 'Mobile Number *',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),
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
                validator: Validators.confirmPassword(_passwordCtrl.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

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
                  style: AppTypography.bodySmall,
                  children: [
                    const TextSpan(text: 'I accept the '),
                    TextSpan(
                      text: 'Terms & Conditions',
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
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        PrimaryButton(
          label: 'Create Account',
          isLoading: widget.auth.isLoading,
          onPressed: _register,
        ),
        const SizedBox(height: AppSpacing.x2l),

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
// Shared helpers
// =============================================================================
class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE4EAF2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'OR',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE4EAF2))),
      ],
    );
  }
}
