import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../data/models/course_api_model.dart';
import '../../data/repositories/course_repository.dart';
import '../controllers/enrollment_controller.dart';

/// Zabira Academy — Course Details Page
class CourseDetailsPage extends StatefulWidget {
  const CourseDetailsPage({
    super.key,
    required this.courseId,
  });

  final int courseId;

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage> {
  final CourseRepository _repository = CourseRepository();

  CourseApiModel? _course;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedPaymentPlanIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final course = await _repository.getCourseDetails(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  String _cleanHtml(String? html) {
    if (html == null || html.isEmpty) return '';
    return html
        .replaceAll(RegExp(r'<p>|</p>|<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<li>'), '• ')
        .replaceAll(RegExp(r'</li>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  Future<void> _onEnrollAction() async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthController>();
    final enrollment = context.read<EnrollmentController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/courses/${widget.courseId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to enroll in this course.')),
      );
      context.push(AppRoutes.login);
      return;
    }

    final isAlreadyEnrolled = enrollment.isEnrolled(widget.courseId);
    if (isAlreadyEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Continuing ${_course?.title ?? "course"}...'),
          backgroundColor: AppColors.navyDark,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final effectivePrice = _course?.paymentOptions.isNotEmpty == true &&
            _selectedPaymentPlanIndex < (_course?.paymentOptions.length ?? 0)
        ? _course!.paymentOptions[_selectedPaymentPlanIndex].finalPrice
        : (_course?.effectivePrice ?? 0.0);
    final isFree = effectivePrice <= 0 || _course?.isFree == true;

    if (isFree) {
      // Direct enrollment for free courses
      final success = await enrollment.enrollInCourse(
        courseId: widget.courseId,
        token: auth.currentToken,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enrolled successfully! You can now start learning.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enrollment.errorMessage ?? 'Enrollment failed. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Paid course: Initiate native Secure Checkout
    final plan = _course?.paymentOptions.isNotEmpty == true &&
            _selectedPaymentPlanIndex < (_course?.paymentOptions.length ?? 0)
        ? _course!.paymentOptions[_selectedPaymentPlanIndex]
        : null;

    context.push(
      '/checkout',
      extra: {
        'orderId': widget.courseId,
        'productType': 'course',
        'title': _course?.title ?? 'Course Enrollment',
        'amount': effectivePrice,
        'instructor': _course?.instructorName,
        'category': _course?.categoryName,
        'level': _course?.level,
        'language': _course?.language,
        'duration': _course?.duration,
        'mode': _course?.courseType,
        'planLabel': plan?.label,
        'courseId': widget.courseId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : (_errorMessage != null || _course == null)
                ? _buildError()
                : _buildContent(),
      ),
      bottomNavigationBar: _course != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildAppBar(title: 'Loading Course...'),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _buildAppBar(title: 'Course Details'),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _errorMessage ?? 'Course details not available.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _loadCourseDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: AppColors.gold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final c = _course!;
    final heroUrl = c.fullHeroBannerUrl ?? c.fullThumbnailUrl;

    return Column(
      children: [
        // Top App Bar
        _buildAppBar(title: c.title),

        // Scrollable Body
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Hero Banner Container ────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081D3A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDark.withAlpha(12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (heroUrl != null && heroUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            heroUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.gold),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(Icons.auto_stories_rounded, size: 48, color: AppColors.gold),
                        ),

                      // Preview Play Overlay
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(180), width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        ),
                      ),

                      // Badge Tag
                      if (c.badgeLabel != null)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.badgeLabel!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── 2. Meta Pills (Category, Level, Duration, Rating) ──────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (c.categoryName != null)
                      _buildPill(Icons.category_outlined, c.categoryName!),
                    _buildPill(Icons.schedule_rounded, c.duration),
                    _buildPill(Icons.signal_cellular_alt_rounded, c.level),
                    _buildPill(Icons.language_rounded, c.language),
                    _buildPill(Icons.star_rounded, c.ratingDisplay, iconColor: AppColors.gold),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── 3. Title & Short Description ────────────────────────────
                Text(
                  c.title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.25,
                  ),
                ),
                if (c.shortDescription != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    c.shortDescription!,
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],

                const Divider(height: 32, color: AppColors.borderLight),

                // ── 4. Flexible Payment Options ─────────────────────────────
                if (c.paymentOptions.isNotEmpty) ...[
                  Text(
                    'Select Payment Option',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...List.generate(c.paymentOptions.length, (index) {
                    final opt = c.paymentOptions[index];
                    final isSelected = _selectedPaymentPlanIndex == index;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPaymentPlanIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF9E6) : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.gold : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: isSelected ? AppColors.gold : AppColors.textTertiary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    opt.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                  if (opt.benefits.isNotEmpty)
                                    Text(
                                      opt.benefits.join(' • '),
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              opt.planType == 'monthly' && opt.installmentAmount != null
                                  ? '₹${opt.installmentAmount!.toInt()}/mo'
                                  : '₹${opt.finalPrice.toInt()}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 32, color: AppColors.borderLight),
                ],

                // ── 5. Full Description ─────────────────────────────────────
                Text(
                  'About this Course',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _cleanHtml(c.description).isNotEmpty
                      ? _cleanHtml(c.description)
                      : 'Comprehensive structured learning path by Zabira Academy scholars.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── 6. Course Curriculum ────────────────────────────────────
                if (c.curriculum.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Curriculum',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${c.curriculum.length} Sections',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...c.curriculum.map((section) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          title: Text(
                            section.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          subtitle: section.lessons.isNotEmpty
                              ? Text(
                                  '${section.lessons.length} Lessons',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : null,
                          children: section.lessons.map((lesson) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.play_circle_outline_rounded, size: 18, color: AppColors.gold),
                              title: Text(
                                lesson.title,
                                style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.navyDark),
                              ),
                              trailing: lesson.isPreview
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Preview',
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    )
                                  : (lesson.duration != null
                                      ? Text(lesson.duration!, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textTertiary))
                                      : null),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(IconData icon, String label, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor ?? AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar({required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withAlpha(150),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.navyDark),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.courses);
              }
            },
            tooltip: 'Back',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final c = _course!;
    final effectivePrice = c.discountPrice != null && c.discountPrice! > 0 ? c.discountPrice! : c.price;
    final enrollment = context.watch<EnrollmentController>();
    final isEnrolled = enrollment.isEnrolled(widget.courseId);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isEnrolled) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Tuition',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  '₹${effectivePrice.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: enrollment.isLoading ? null : _onEnrollAction,
              icon: Icon(
                isEnrolled ? Icons.play_circle_outline_rounded : Icons.check_circle_outline_rounded,
                size: 20,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnrolled ? AppColors.navyDark : AppColors.gold,
                foregroundColor: isEnrolled ? Colors.white : const Color(0xFF081D3A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              label: Text(
                isEnrolled
                    ? 'Continue Learning'
                    : (enrollment.isLoading ? 'Enrolling...' : 'Start Learning Now'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
