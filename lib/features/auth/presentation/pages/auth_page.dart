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
import '../../../../shared/widgets/zabira_logo.dart';
import '../../auth_controller.dart';
import '../widgets/auth_tab_switcher.dart';
import '../widgets/feature_card.dart';
import '../widgets/location_fields.dart';

/// Zabira Academy — Unified Authentication Page
///
/// Hosts both Sign In (tab 0) and Create Account (tab 1) in a single screen,
/// eliminating the blank-screen flicker that occurred when navigating between
/// two separate routes.
///
/// Features:
///  • Entrance slide-up: on first load the CustomScrollView scrolls smoothly
///    to reveal the white panel rising over the hero (800 ms, easeOutCubic).
///  • SliverFillRemaining ensures the white panel always fills the remaining
///    viewport — no dark navy gap below the form on any screen size.
///  • Horizontal AnimatedSwitcher + SlideTransition between tabs — directional
///    slide with no blank frames, no flicker, fully natural content height.
///  • [initialTab] controls which tab is active on entry (0 = Sign In, 1 = Register).
class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialTab = 0});

  /// 0 → Sign In  |  1 → Create Account
  final int initialTab;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // ── Scroll / entrance animation ────────────────────────────────────────────
  final _scrollController = ScrollController();
  bool _entranceDone = false;

  // ── Tab state ──────────────────────────────────────────────────────────────
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;

    // After the first frame fire the smooth entrance scroll so the white
    // authentication panel slides up into view (hero stays behind it).
    WidgetsBinding.instance.addPostFrameCallback((_) => _triggerEntrance());
  }

  void _triggerEntrance() {
    if (_entranceDone || !_scrollController.hasClients) return;
    _entranceDone = true;
    // Scroll to ~190px: hero (≈300px tall) remains partially visible at the
    // top while the white panel rises smoothly into the lower viewport area.
    // 800 ms easeOutCubic feels premium — not sluggish, not jarring.
    _scrollController.animateTo(
      190.0,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
    );
  }

  void _switchTab(int index) {
    if (index == _selectedTab) return;
    setState(() => _selectedTab = index);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

              // ── Main Scrollable Content ─────────────────────────────────
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Hero / Branding Panel ─────────────────────────────
                    SliverToBoxAdapter(child: _HeroSection()),

                    // ── White Authentication Panel ────────────────────────
                    // SliverFillRemaining(hasScrollBody: false) guarantees the
                    // panel fills at least the remaining viewport height on every
                    // screen size — eliminates the dark navy gap below the form.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppRadius.x2l),
                            topRight: Radius.circular(AppRadius.x2l),
                          ),
                          // Subtle upward shadow gives the panel premium elevation
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(20),
                              blurRadius: 24,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenHorizontal,
                          AppSpacing.x2l,
                          AppSpacing.screenHorizontal,
                          AppSpacing.x3l + context.bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tab Switcher
                            AuthTabSwitcher(
                              selectedIndex: _selectedTab,
                              tabs: const ['Sign In', 'Create Account'],
                              onTabSelected: _switchTab,
                            ),
                            const SizedBox(height: AppSpacing.x2l),

                            // Sliding form content
                            _SlidingTabContent(
                              selectedTab: _selectedTab,
                              onTabSwitch: _switchTab,
                              auth: auth,
                            ),
                          ],
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
// Hero Section
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
              style: AppTypography.displayLarge,
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Start your journey of Quran, Arabic, and Islamic learning today.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textWhite.withAlpha(180),
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x2l),
          const StatsRow(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliding Tab Content
// Directional horizontal slide: Sign In ↔ Create Account
// Uses AnimatedSwitcher + SlideTransition. No PageView, no custom RenderObject.
// ─────────────────────────────────────────────────────────────────────────────

class _SlidingTabContent extends StatefulWidget {
  const _SlidingTabContent({
    required this.selectedTab,
    required this.onTabSwitch,
    required this.auth,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSwitch;
  final AuthController auth;

  @override
  State<_SlidingTabContent> createState() => _SlidingTabContentState();
}

class _SlidingTabContentState extends State<_SlidingTabContent> {
  // Tracks previous tab so we know which direction to slide.
  int _previousTab = 0;

  @override
  void didUpdateWidget(_SlidingTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      _previousTab = oldWidget.selectedTab;
    }
  }

  @override
  Widget build(BuildContext context) {
    // isForward = going from lower index to higher (Sign In → Create Account)
    final isForward = widget.selectedTab > _previousTab;

    // Incoming widget starts off-screen in the slide direction.
    final inOffset = Offset(isForward ? 1.0 : -1.0, 0.0);
    // Outgoing widget exits in the opposite direction.
    final outOffset = Offset(isForward ? -1.0 : 1.0, 0.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      // Custom layoutBuilder: stack old behind new, both top-aligned.
      // This prevents height collapse during transition and keeps the
      // container expanding to whichever child is taller.
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (child, animation) {
        // Determine whether this child is incoming or outgoing by comparing
        // its ValueKey to the current selected tab.
        final key = child.key as ValueKey<int>;
        final isIncoming = key.value == widget.selectedTab;

        // Incoming: animate from inOffset → Offset.zero (animation 0→1)
        // Outgoing: animate from Offset.zero → outOffset
        //   but animation runs reversed (1→0), so we write:
        //   begin=outOffset, end=Offset.zero  →  at 1.0 = Offset.zero ✓
        //                                          at 0.0 = outOffset  ✓
        final tween = isIncoming
            ? Tween<Offset>(begin: inOffset, end: Offset.zero)
            : Tween<Offset>(begin: outOffset, end: Offset.zero);

        return ClipRect(
          child: SlideTransition(
            position: animation.drive(
              tween.chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(widget.selectedTab),
        child: widget.selectedTab == 0
            ? _SignInForm(
                auth: widget.auth,
                onSwitchToRegister: () => widget.onTabSwitch(1),
              )
            : _RegisterForm(
                auth: widget.auth,
                onSwitchToSignIn: () => widget.onTabSwitch(0),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign In Form
// ─────────────────────────────────────────────────────────────────────────────

class _SignInForm extends StatefulWidget {
  const _SignInForm({required this.auth, required this.onSwitchToRegister});
  final AuthController auth;
  final VoidCallback onSwitchToRegister;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
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
    if (widget.auth.isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await widget.auth.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      final returnTo = widget.auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else {
        context.go(AppRoutes.studentDash);
      }
    } else if (widget.auth.errorMessage != null) {
      context.showErrorSnackBar(widget.auth.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (widget.auth.isLoading) return;
    final success = await widget.auth.signInWithGoogle(portal: 'student');
    if (!mounted) return;
    if (success) {
      final returnTo = widget.auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else {
        context.go(AppRoutes.studentDash);
      }
      context.showSuccessSnackBar(
        'Welcome back, ${widget.auth.user?.displayName ?? "Student"}!',
      );
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
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sign in to continue your courses, live classes, and learning progress.',
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

        PrimaryButton(
          label: 'Sign In',
          icon: Icons.arrow_forward_rounded,
          isLoading: widget.auth.isLoading,
          onPressed: _handleSignIn,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),

        SocialButton(
          label: 'Continue with Google',
          isLoading: widget.auth.isLoading,
          onPressed: _handleGoogleSignIn,
        ),
        const SizedBox(height: AppSpacing.x2l),

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

        Center(
          child: RichText(
            text: TextSpan(
              text: 'New to Zabira Academy? ',
              style: AppTypography.bodySmall,
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: widget.onSwitchToRegister,
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
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register Form
// ─────────────────────────────────────────────────────────────────────────────

class _RegisterForm extends StatefulWidget {
  const _RegisterForm({required this.auth, required this.onSwitchToSignIn});
  final AuthController auth;
  final VoidCallback onSwitchToSignIn;

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDark,
            onPrimary: AppColors.textWhite,
            surface: AppColors.surfaceWhite,
            onSurface: AppColors.navyDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (widget.auth.isLoading) return;
    final success = await widget.auth.signInWithGoogle(portal: 'student');
    if (!mounted) return;
    if (success) {
      final returnTo = widget.auth.consumePendingReturnTo();
      if (returnTo != null && returnTo.isNotEmpty) {
        context.go(returnTo);
      } else {
        context.go(AppRoutes.studentDash);
      }
      context.showSuccessSnackBar(
        'Welcome to Zabira Academy, ${widget.auth.user?.displayName ?? "Student"}!',
      );
    } else if (widget.auth.errorMessage != null) {
      final msg = widget.auth.errorMessage!;
      if (!msg.toLowerCase().contains('cancelled')) {
        context.showErrorSnackBar(msg);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (widget.auth.isLoading) return;
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
    final success = await widget.auth.register(
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
      if (widget.auth.isAuthenticated) {
        final returnTo = widget.auth.consumePendingReturnTo();
        if (returnTo != null && returnTo.isNotEmpty) {
          context.go(returnTo);
        } else {
          context.go(AppRoutes.studentDash);
        }
      } else {
        context.showSuccessSnackBar(
          'Account created successfully! Please sign in.',
        );
        widget.onSwitchToSignIn();
      }
    } else {
      context.showErrorSnackBar(
        widget.auth.errorMessage ?? 'Registration failed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Create your account', style: AppTypography.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Join Zabira Academy and begin your learning journey today.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),

        SocialButton(
          label: 'Continue with Google',
          isLoading: widget.auth.isLoading,
          onPressed: _handleGoogleSignIn,
        ),
        const SizedBox(height: AppSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: 6),

        Center(
          child: Text(
            'Create your Zabira Academy account',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Form(
          key: _formKey,
          child: Column(
            children: [
              // First + Last Name
              Row(
                children: [
                  Expanded(
                    child: ZabiraTextField(
                      controller: _firstNameController,
                      hintText: 'First Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.required,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ZabiraTextField(
                      controller: _lastNameController,
                      hintText: 'Last Name *',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: Validators.required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // Email
              ZabiraTextField(
                controller: _emailController,
                hintText: 'Email Address *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // Mobile
              ZabiraTextField(
                controller: _mobileController,
                hintText: 'Mobile Number *',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.required,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // Gender + DOB
              Row(
                children: [
                  Expanded(
                    child: _GenderDropdown(
                      value: _selectedGender,
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedGender = v);
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
                          prefixIcon: Icons.calendar_today_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // Country
              CountrySelectionField(
                controller: _countryController,
                onSelected: (_) {
                  setState(() {
                    _stateController.clear();
                    _cityController.clear();
                  });
                },
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // State + City
              Row(
                children: [
                  Expanded(
                    child: DependentLocationField(
                      controller: _stateController,
                      hintText: 'State *',
                      prefixIcon: Icons.map_outlined,
                      enabled: _hasSelectedCountry,
                      disabledMessage: 'Please select a country first.',
                      onChanged: (_) {
                        if (_cityController.text.isNotEmpty) {
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
                      prefixIcon: Icons.location_city_outlined,
                      enabled: _stateController.text.trim().isNotEmpty,
                      disabledMessage: 'Select state first.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // Password
              ZabiraTextField(
                controller: _passwordController,
                hintText: 'Password *',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: Validators.newPassword,
              ),
              const SizedBox(height: AppSpacing.formFieldGap),

              // Confirm Password
              ZabiraTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password *',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: Validators.confirmPassword(_passwordController.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Terms checkbox
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
                      text: 'Terms & Conditions *',
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
          onPressed: _handleRegister,
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
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
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
  Widget build(BuildContext context) => CustomPaint(painter: _PatternPainter());
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
