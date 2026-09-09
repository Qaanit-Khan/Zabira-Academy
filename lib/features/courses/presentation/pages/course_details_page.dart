import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../store/presentation/controllers/cart_controller.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../data/models/course_api_model.dart';
import '../../data/repositories/course_repository.dart';
import '../controllers/enrollment_controller.dart';
import '../controllers/wishlist_controller.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CourseRepository _repository = CourseRepository();

  CourseApiModel? _course;
  List<CourseApiModel> _relatedCourses = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedPaymentPlanIndex = 0; // 0: Pay in Full, 1: Monthly
  int _selectedLanguageIndex = 0; // 0: English, 1: Roman English, 2: Urdu
  int _expandedFaqIndex = -1;

  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);
  static const Color brandNavyDark = Color(0xFF0D1B2E);
  static const Color brandNavyCard = Color(0xFF162744);

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
  }

  @override
  void didUpdateWidget(covariant CourseDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courseId != widget.courseId) {
      _loadCourseDetails();
    }
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courseFuture = _repository.getCourseDetails(widget.courseId);
      final allCoursesFuture = _repository.getCourses();

      final results = await Future.wait([courseFuture, allCoursesFuture]);
      final course = results[0] as CourseApiModel;
      final allCourses = results[1] as List<CourseApiModel>;

      if (!mounted) return;
      setState(() {
        _course = course;
        _relatedCourses = allCourses.where((c) => c.id != widget.courseId).take(4).toList();
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
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .trim();
  }

  String _getLangCode() {
    switch (_selectedLanguageIndex) {
      case 1:
        return 're';
      case 2:
        return 'ur';
      case 0:
      default:
        return 'en';
    }
  }

  String _getActiveTitle(CourseApiModel course) {
    final lang = _getLangCode();
    return course.getTitle(lang);
  }

  String _getActiveShortDescription(CourseApiModel course) {
    final lang = _getLangCode();
    final s = course.getShortDescription(lang);
    if (s != null && s.isNotEmpty) return _cleanHtml(s);
    return _cleanHtml(course.shortDescription);
  }

  String _getActiveDescription(CourseApiModel course) {
    final lang = _getLangCode();
    final raw = course.getDescription(lang);
    final cleaned = _cleanHtml(raw);
    if (cleaned.isNotEmpty) return cleaned;

    return _cleanHtml(course.description ?? course.shortDescription).isNotEmpty
        ? _cleanHtml(course.description ?? course.shortDescription)
        : 'Learn and master this comprehensive certification course step-by-step with Zabira Academy scholars.';
  }

  // ── Multi-Language Translation Map for all sections down to payment ────────
  String _tr(String en, {String? re, String? ur}) {
    final lang = _getLangCode();
    if (lang == 'ur' && ur != null && ur.isNotEmpty) return ur;
    if (lang == 're' && re != null && re.isNotEmpty) return re;
    return en;
  }

  String _translateCurriculumTitle(String title) {
    final lang = _getLangCode();
    if (lang == 'en') return title;

    final lower = title.toLowerCase().trim();

    if (lower.contains('module 1') || lower.contains('introduction to the quran') || lower.contains('arabic basics')) {
      return lang == 'ur'
          ? 'ماڈیول 1 - قرآن اور عربی کے بنیادی اصولوں کا تعارف'
          : 'Module 1 - Quran Aur Arabic Ke Bunyadi Usool';
    }
    if (lower.contains('module 2') || lower.contains('makharij') || lower.contains('pronunciation')) {
      return lang == 'ur'
          ? 'ماڈیول 2 - مخارج اور حروف کا صحیح تلفظ'
          : 'Module 2 - Sahi Makharij Aur Talaffuz Ke Usool';
    }
    if (lower.contains('module 3') || lower.contains('noon sakinah') || lower.contains('tanween')) {
      return lang == 'ur'
          ? 'ماڈیول 3 - نون ساکنہ اور تنوین کے احکام و قواعد'
          : 'Module 3 - Noon Sakinah Aur Tanween Ke Ahkaam';
    }
    if (lower.contains('module 4') || lower.contains('meem sakinah')) {
      return lang == 'ur'
          ? 'ماڈیول 4 - میم ساکنہ کے احکام اور قواعد'
          : 'Module 4 - Meem Sakinah Ke Qawaid Aur Ahkaam';
    }
    if (lower.contains('module 5') || lower.contains('madd') || lower.contains('prolongation')) {
      return lang == 'ur'
          ? 'ماڈیول 5 - مد کے قواعد اور اس کی اقسام'
          : 'Module 5 - Madd Ke Qawaid Aur Uski Aqsaam';
    }
    if (lower.contains('module 6') || lower.contains('tafkheem') || lower.contains('tarqeeq') || lower.contains('heavy and light')) {
      return lang == 'ur'
          ? 'ماڈیول 6 - تفخیم اور ترقیق (موٹے اور باریک حروف)'
          : 'Module 6 - Tafkheem Aur Tarqeeq (Mote Aur Bareek Huroof)';
    }
    if (lower.contains('module 7') || lower.contains('waqf') || lower.contains('stopping rules')) {
      return lang == 'ur'
          ? 'ماڈیول 7 - وقف کے قواعد اور رموز و اوقاف'
          : 'Module 7 - Waqf Ke Qawaid Aur Romooz o Auqaaf';
    }
    if (lower.contains('module 8') || lower.contains('practical recitation') || lower.contains('recitation with tajweed')) {
      return lang == 'ur'
          ? 'ماڈیول 8 - تجوید کے ساتھ عملی تلاوت کی مشق'
          : 'Module 8 - Tajweed Ke Sath Tilawat Ki Amali Mashq';
    }
    if (lower.contains('module 9') || lower.contains('memorization') || lower.contains('selected surahs')) {
      return lang == 'ur'
          ? 'ماڈیول 9 - منتخب سورتوں کا حفظ اور ترتیل'
          : 'Module 9 - Muntakhab Suraton Ka Hifz Aur Tarteel';
    }
    if (lower.contains('module 10') || lower.contains('daily adhkar') || lower.contains('duas')) {
      return lang == 'ur'
          ? 'ماڈیول 10 - مسنون اذکار اور روزمرہ کی دعائیں'
          : 'Module 10 - Masnoon Azkaar Aur Rozmarrah Ki Duayein';
    }
    if (lower.contains('module 11') || lower.contains('final revision') || lower.contains('assessment')) {
      return lang == 'ur'
          ? 'ماڈیول 11 - حتمی دہرائی اور جامع امتحان'
          : 'Module 11 - Final Revision Aur Imtehan';
    }
    if (lower.contains('module 12') || lower.contains('certification') || lower.contains('ijazah')) {
      return lang == 'ur'
          ? 'ماڈیول 12 - سند اور اجازت نامے کی تیاری'
          : 'Module 12 - Sanad Aur Ijazah Ki Tayyari';
    }

    final moduleMatch = RegExp(r'Module\s*(\d+)[\s\-:]*(.*)', caseSensitive: false).firstMatch(title);
    if (moduleMatch != null) {
      final num = moduleMatch.group(1);
      final rest = moduleMatch.group(2) ?? '';
      if (lang == 'ur') {
        return 'ماڈیول $num ${rest.isNotEmpty ? '- $rest' : ''}';
      } else {
        return 'Module $num ${rest.isNotEmpty ? '- $rest' : ''}';
      }
    }

    return title;
  }

  String _translateLessonTitle(String title) {
    final lang = _getLangCode();
    if (lang == 'en') return title;

    final lower = title.toLowerCase().trim();
    if (lower.contains('lesson 1') || lower.contains('arabic alphabet')) {
      return lang == 'ur' ? 'سبق 1: عربی حروف تہجی کی شناخت اور ادائیگی' : 'Sabaq 1: Arabic Huroof Tahajji Ki Pehchan';
    }
    if (lower.contains('lesson 2') || lower.contains('vowels') || lower.contains('harakat')) {
      return lang == 'ur' ? 'سبق 2: حرکات (زبر، زیر، پیش) اور تنوین' : 'Sabaq 2: Harakaat Aur Tanween Ka Bayaan';
    }
    if (lower.contains('lesson 3') || lower.contains('sukoon') || lower.contains('shaddah')) {
      return lang == 'ur' ? 'سبق 3: جزم (سکون) اور تشدید کے قواعد' : 'Sabaq 3: Jazm Aur Tashdeed Ke Qawaid';
    }
    if (lower.contains('lesson 4') || lower.contains('makharij') || lower.contains('throat')) {
      return lang == 'ur' ? 'سبق 4: حلقی حروف کے مخارج' : 'Sabaq 4: Halqi Huroof Ke Makharij';
    }
    if (lower.contains('lesson 5') || lower.contains('tongue letters')) {
      return lang == 'ur' ? 'سبق 5: لسانی حروف کے مخارج اور مشق' : 'Sabaq 5: Lisani Huroof Ke Makharij';
    }
    if (lower.contains('lesson 6') || lower.contains('lip letters')) {
      return lang == 'ur' ? 'سبق 6: شفوی حروف (لبوں سے ادا ہونے والے حروف)' : 'Sabaq 6: Shafwi Huroof Ke Makharij';
    }
    if (lower.contains('lesson 7') || lower.contains('quiz') || lower.contains('test')) {
      return lang == 'ur' ? 'سبق 7: عملی جانچ اور ٹیسٹ' : 'Sabaq 7: Amali Jaanch Aur Test';
    }

    final sabaqMatch = RegExp(r'Lesson\s*(\d+)[\s\-:]*(.*)', caseSensitive: false).firstMatch(title);
    if (sabaqMatch != null) {
      final num = sabaqMatch.group(1);
      final rest = sabaqMatch.group(2) ?? '';
      return lang == 'ur' ? 'سبق $num: $rest' : 'Sabaq $num: $rest';
    }

    return title;
  }

  Future<void> _addToCart() async {
    HapticFeedback.mediumImpact();
    final c = _course;
    if (c == null) return;

    final cart = context.read<CartController>();
    final auth = context.read<AuthController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/courses/${widget.courseId}');
      showAuthBottomSheet(context);
      return;
    }

    final isMonthly = _selectedPaymentPlanIndex == 1;
    final planPrice = isMonthly
        ? (c.paymentOptions.length > 1 && c.paymentOptions[1].installmentAmount != null
            ? c.paymentOptions[1].installmentAmount!
            : (c.effectivePrice / 6).ceilToDouble())
        : c.effectivePrice;

    final success = await cart.addItem(
      itemData: {
        'course_id': c.id,
        'title': c.title,
        'name': c.title,
        'image': c.fullThumbnailUrl ?? c.fullHeroBannerUrl ?? c.thumbnail,
        'thumbnail': c.fullThumbnailUrl ?? c.thumbnail,
        'product_type': 'course',
        'quantity': '1',
        'price': planPrice,
        'discount_price': planPrice,
        'plan_type': isMonthly ? 'monthly' : 'full',
        'payment_plan': isMonthly ? 'monthly' : 'full',
      },
      token: auth.currentToken,
    );

    if (!mounted) return;

    // Fast auto-dismissing toast with plan-specific price
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: brandGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                success
                    ? 'Added "${c.title}" (${isMonthly ? '₹${planPrice.toInt()}/mo' : '₹${planPrice.toInt()}'})'
                    : 'Item added to cart',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: brandNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 2500),
        action: SnackBarAction(
          label: 'View Cart',
          textColor: brandGold,
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            context.push(AppRoutes.cart);
          },
        ),
      ),
    );
  }

  void _shareCourse() {
    HapticFeedback.lightImpact();
    final c = _course;
    if (c == null) return;
    Clipboard.setData(
      ClipboardData(text: 'Check out "${c.title}" on Zabira Academy: https://zabiraacademy.com/courses/${c.id}'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Course link copied to clipboard!',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: brandNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _bookFreeTrial() {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/courses/${widget.courseId}');
      showAuthBottomSheet(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Free Trial booked successfully! Our team will contact you shortly.',
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF00A884),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onEnrollAction() async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthController>();
    final enrollment = context.read<EnrollmentController>();

    if (!auth.isAuthenticated) {
      auth.setPendingReturnTo('/courses/${widget.courseId}');
      showAuthBottomSheet(context);
      return;
    }

    final isAlreadyEnrolled = enrollment.isEnrolled(widget.courseId);
    if (isAlreadyEnrolled) {
      context.push('/courses/${widget.courseId}/learn');
      return;
    }

    final isMonthly = _selectedPaymentPlanIndex == 1;
    final effectivePrice = isMonthly
        ? (_course?.paymentOptions.length != null &&
                _course!.paymentOptions.length > 1 &&
                _course!.paymentOptions[1].installmentAmount != null
            ? _course!.paymentOptions[1].installmentAmount!
            : ((_course?.effectivePrice ?? 0.0) / 6).ceilToDouble())
        : (_course?.effectivePrice ?? 0.0);

    final isFree = effectivePrice <= 0 || _course?.isFree == true;

    if (isFree) {
      final enrollRes = await enrollment.enrollInCourse(
        courseId: widget.courseId,
        token: auth.currentToken,
      );

      if (!mounted) return;

      final isSuccess = enrollRes['success'] == true || enrollRes['status'] == 'success';
      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enrolled successfully! You can now start learning.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/courses/${widget.courseId}/learn');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enrollment.errorMessage ?? 'Enrollment failed. Please try again.',
              style: GoogleFonts.outfit(color: Colors.white),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Paid course checkout
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
        'planLabel': isMonthly ? 'Monthly Installment' : 'Pay in Full',
        'courseId': widget.courseId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cart = context.watch<CartController>();
    final user = auth.user;
    final isAuth = auth.isAuthenticated && user != null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Navigation Bar: Exact HomeHeader ─────────────────────────
            HomeHeader(
              isAuthenticated: isAuth,
              notificationCount: isAuth ? 2 : 0,
              cartCount: cart.itemCount,
              userInitial: isAuth && user.displayName.isNotEmpty ? user.displayName[0] : null,
              onMenuTap: () => AppDrawer.open(context),
              onCartTap: () => context.push(AppRoutes.cart),
              onSignIn: () => showAuthBottomSheet(context),
              onProfileTap: () {
                if (isAuth) {
                  context.push(AppRoutes.studentDash);
                } else {
                  showAuthBottomSheet(context);
                }
              },
            ),

            // ── Scrollable Body ──────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildLoading()
                  : (_errorMessage != null || _course == null)
                      ? _buildError()
                      : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _course != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: brandGold),
    );
  }

  Widget _buildError() {
    return Center(
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
                backgroundColor: brandNavy,
                foregroundColor: brandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Try Again', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Scrollable Content ────────────────────────────────────────────────
  Widget _buildContent() {
    final c = _course!;
    final heroUrl = c.fullHeroBannerUrl ?? c.fullThumbnailUrl;
    final isUrdu = _selectedLanguageIndex == 2;
    final currentTitle = _getActiveTitle(c);
    final currentShortDesc = _getActiveShortDescription(c);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Hero Banner with Dark Navy Overlay & Breadcrumb ─────────────
          Stack(
            children: [
              // Background Image (Clean banner without text)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 300),
                decoration: const BoxDecoration(color: brandNavy),
                child: heroUrl != null && heroUrl.isNotEmpty
                    ? Image.network(
                        heroUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, _) => Container(color: brandNavy),
                      )
                    : Container(color: brandNavy),
              ),

              // Gradient Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        brandNavy.withValues(alpha: 0.85),
                        brandNavy.withValues(alpha: 0.96),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content inside Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
                child: Column(
                  crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Breadcrumb
                    Row(
                      mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Home', re: 'Home', ur: 'ہوم'),
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('/', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ),
                        Text(
                          _tr('Courses', re: 'Courses', ur: 'کورسز'),
                          style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF94A3B8)),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('/', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ),
                        Flexible(
                          child: Text(
                            currentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 12.5, color: brandGold, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Badges Row
                    Row(
                      mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (c.categoryName != null) ...[
                          _buildHeroBadge(c.categoryName!.toUpperCase(), brandGold.withValues(alpha: 0.15), brandGold, isBordered: true),
                          const SizedBox(width: 8),
                        ],
                        if (c.isPopular) ...[
                          _buildHeroBadge('POPULAR', const Color(0xFF00A884), Colors.white),
                          const SizedBox(width: 8),
                        ],
                        if (c.isFeatured) ...[
                          _buildHeroBadge('FEATURED', brandGold, brandNavy),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Course Title
                    Text(
                      currentTitle,
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Short Description
                    if (currentShortDesc.isNotEmpty)
                      Text(
                        currentShortDesc,
                        textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: const Color(0xFFE2E8F0),
                          height: 1.45,
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Meta Chips: Language · Level · Rating
                    Row(
                      mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 14, color: brandGold),
                              const SizedBox(width: 5),
                              Text(
                                _tr('Language · ${c.languagesDisplay}', re: 'Language · ${c.languagesDisplay}', ur: 'زبان · ${c.languagesDisplay}'),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            c.level,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rating & Duration Line
                    Row(
                      mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.star_rounded, size: 16, color: brandGold),
                        const SizedBox(width: 4),
                        Text(
                          '${c.rating.toStringAsFixed(1)} (${c.reviewCount} students)',
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          c.duration,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── 2. Standard 3-Language Converter Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Tab 0: English
                  Expanded(
                    child: _buildExactLangTab(
                      index: 0,
                      iconWidget: Icon(
                        Icons.translate_rounded,
                        size: 15,
                        color: _selectedLanguageIndex == 0 ? Colors.white : const Color(0xFF64748B),
                      ),
                      label: 'English',
                    ),
                  ),
                  // Tab 1: Roman English
                  Expanded(
                    child: _buildExactLangTab(
                      index: 1,
                      iconWidget: Icon(
                        Icons.text_fields_rounded,
                        size: 15,
                        color: _selectedLanguageIndex == 1 ? Colors.white : const Color(0xFF64748B),
                      ),
                      label: 'Roman English',
                    ),
                  ),
                  // Tab 2: Urdu (Lucide Book Open Icon)
                  Expanded(
                    child: _buildExactLangTab(
                      index: 2,
                      iconWidget: _LucideBookOpenIcon(
                        size: 15,
                        color: _selectedLanguageIndex == 2 ? brandGold : const Color(0xFF64748B),
                      ),
                      label: 'اردو',
                      isUrduTab: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 3. "About This Course" Section with Golden Accent Bar ──────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: brandNavy.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Heading
                  Text(
                    _tr('About This Course', re: 'Is Course Ke Baare Mein', ur: 'اس کورس کے بارے میں'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Golden Accent Underline Bar (#c4a95b)
                  Container(
                    width: 44,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: brandGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Body Description Text
                  Directionality(
                    textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                    child: Text(
                      _getActiveDescription(c),
                      textAlign: isUrdu ? TextAlign.right : TextAlign.left,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        color: const Color(0xFF334155),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),

                  // 4 Feature Pillars Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeaturePillar(
                          Icons.workspace_premium_rounded,
                          _tr('Certificate', re: 'Certificate', ur: 'سند / سرٹیفکیٹ'),
                          _tr('Upon Completion', re: 'Khatam hone par', ur: 'تکمیل پر'),
                        ),
                      ),
                      Expanded(
                        child: _buildFeaturePillar(
                          Icons.devices_rounded,
                          _tr('Any Device', re: 'Har Device Par', ur: 'ہر ڈیوائس پر'),
                          _tr('Mobile, Tablet & TV', re: 'Mobile, Tablet & TV', ur: 'موبائل، ٹیبلٹ اور ٹی وی'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFeaturePillar(
                          Icons.all_inclusive_rounded,
                          _tr('Lifetime Access', re: 'Lifetime Access', ur: 'تاحیات رسائی'),
                          _tr('Watch anytime', re: 'Kabhi bhi dekhein', ur: 'کسی بھی وقت دیکھیں'),
                        ),
                      ),
                      Expanded(
                        child: _buildFeaturePillar(
                          Icons.bolt_rounded,
                          _tr('Instant Access', re: 'Instant Access', ur: 'فوری رسائی'),
                          _tr('Start learning now', re: 'Abhi shuru karein', ur: 'ابھی سیکھنا شروع کریں'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 4. "What You Will Learn" (Dark Navy Card #112039) ───────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: brandNavyDark,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: brandNavy.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: brandGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _tr('What You Will Learn', re: 'Aap Kya Sikhenge', ur: 'آپ کیا سیکھیں گے'),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildBulletPoint(_tr(
                    'Authentic teachings and deep scholarly perspectives on ${c.title}.',
                    re: '${c.title} ke baare mein mustanad ilm aur taleemat.',
                    ur: '${c.title} کے بارے میں مستند اسلامی تعلیمات اور رہنمائی۔',
                  )),
                  _buildBulletPoint(_tr(
                    'Practical spiritual and moral guidance applicable to modern life.',
                    re: 'Rozmarrah ki zindagi ke liye roohani aur ikhlaqi rehnumai.',
                    ur: 'روزمرہ کی زندگی کے لیے عملی روحانی اور اخلاقی رہنمائی۔',
                  )),
                  _buildBulletPoint(_tr(
                    'Step-by-step structured lessons designed for all learning levels.',
                    re: 'Har level ke talib e ilm ke liye aasan step-by-step sabaq.',
                    ur: 'ہر سطح کے طالب علم کے لیے مرحلہ وار آسان اسباق۔',
                  )),
                  _buildBulletPoint(_tr(
                    'Interactive assessments and accredited certificate upon completion.',
                    re: 'Assessments aur completion par official certificate.',
                    ur: 'مکمل کرنے پر باضابطہ تصدیق شدہ سند۔',
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 5. Requirements ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Requirements', re: 'Zaroori Cheezein (Requirements)', ur: 'شرائط و ضروریات'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildReqItem(_tr(
                    'Basic understanding of ${c.languagesDisplay} language.',
                    re: '${c.languagesDisplay} zabaan ki bunyadi samajh.',
                    ur: '${c.languagesDisplay} زبان کی بنیادی سمجھ۔',
                  )),
                  _buildReqItem(_tr(
                    'A smartphone, tablet, or computer with internet connection.',
                    re: 'Internet ke sath smartphone, tablet ya computer.',
                    ur: 'انٹرنیٹ کے ساتھ اسمارٹ فون، ٹیبلٹ یا کمپیوٹر۔',
                  )),
                  _buildReqItem(_tr(
                    'Dedication and enthusiasm to enrich your Islamic knowledge.',
                    re: 'Islami ilm seekhne ka jazba aur lagan.',
                    ur: 'اسلامی علم سیکھنے کا سچا جذبہ اور لگن۔',
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 6. Skills & Topics Tags ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Skills & Topics Covered', re: 'Skills aur Topics', ur: 'مہارتیں اور موضوعات'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (c.categoryName != null) _buildSkillTag(_tr(c.categoryName!, re: c.categoryName, ur: c.categoryName == 'Quran Studies' ? 'قرآنی علوم' : (c.categoryName == 'Islamic Essentials' ? 'اسلامی ضروریات' : c.categoryName))),
                      _buildSkillTag(_getActiveTitle(c)),
                      _buildSkillTag(_tr('Islamic Knowledge', re: 'Islami Ilm', ur: 'اسلامی علم')),
                      _buildSkillTag(_tr('Sunnah & Ethics', re: 'Sunnah & Ethics', ur: 'سنت اور اخلاق')),
                      _buildSkillTag(_tr('Accredited Certification', re: 'Official Certificate', ur: 'منظور شدہ سرٹیفکیٹ')),
                      _buildSkillTag(_tr('Beginner Friendly', re: 'Beginner Friendly', ur: 'ابتدائی طلبہ کے لیے موزوں')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 7. Course Curriculum Section ───────────────────────────────────
          if (c.curriculum.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _tr('Course Curriculum', re: 'Course Curriculum', ur: 'کورس کا نصاب'),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: brandNavy,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${c.curriculum.length} ${_tr('Sections', re: 'Sections', ur: 'حصے')}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...c.curriculum.map((section) {
                      final translatedSectionTitle = _translateCurriculumTitle(section.title);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(
                              translatedSectionTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: brandNavy,
                              ),
                            ),
                            subtitle: section.lessons.isNotEmpty
                                ? Text(
                                    '${section.lessons.length} ${_tr('Lessons', re: 'Lessons', ur: 'اسباق')}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  )
                                : null,
                            children: section.lessons.map((lesson) {
                              final translatedLessonTitle = _translateLessonTitle(lesson.title);
                              return ListTile(
                                dense: true,
                                onTap: () {
                                  final enrollment = context.read<EnrollmentController>();
                                  final isEnrolled = enrollment.isEnrolled(widget.courseId);
                                  if (isEnrolled || lesson.isPreview) {
                                    context.push('/courses/${widget.courseId}/learn?lesson_id=${lesson.id}');
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _tr('Enroll in this course to access all lessons.', re: 'Enroll karein tamam lessons dekhne ke liye.', ur: 'تمام اسباق تک رسائی کے لیے داخلہ لیں۔'),
                                          style: GoogleFonts.outfit(),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                leading: const Icon(Icons.play_circle_outline_rounded, size: 18, color: brandGold),
                                title: Text(
                                  translatedLessonTitle,
                                  style: GoogleFonts.outfit(fontSize: 12.5, color: brandNavy),
                                ),
                                trailing: lesson.isPreview
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _tr('Preview', re: 'Preview', ur: 'جھلک'),
                                          style: GoogleFonts.outfit(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF15803D),
                                          ),
                                        ),
                                      )
                                    : (lesson.duration != null
                                        ? Text(lesson.duration!, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)))
                                        : null),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── 8. Instructor Section ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Your Instructor', re: 'Aapke Ustaad (Instructor)', ur: 'آپ کے استاد'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: brandNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.person_rounded, color: brandGold, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.instructorName ?? 'Zabira Academy Faculty',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: brandNavy,
                              ),
                            ),
                            Text(
                              _tr('Islamic Scholar & Lead Educator', re: 'Islamic Scholar & Lead Educator', ur: 'اسلامی اسکالر اور سینئر معلم'),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tr(
                      'Experienced Islamic educator dedicated to authentic and transformative learning at Zabira Academy.',
                      re: 'Tajurbakar Islami ustaad jo Zabira Academy par ilm sikhate hain.',
                      ur: 'ذبیرا اکیڈمی کے تجربہ کار اور مستند اسلامی اساتذہ۔',
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 9. Frequently Asked Questions (FAQ) ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Frequently Asked Questions', re: 'Aam Sawalat (FAQ)', ur: 'اکثر پوچھے جانے والے سوالات'),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    index: 0,
                    question: _tr('How do I get my verified certificate?', re: 'Certificate kaise milega?', ur: 'مجھے تصدیق شدہ سند کیسے ملے گی؟'),
                    answer: _tr('Once you complete 100% of the course lectures and pass the final assessment, your official digital certificate will be instantly generated in your student dashboard.', re: 'Course mukammal karne par aapke dashboard me certificate aa jayega.', ur: 'کورس کے تمام اسباق مکمل کرنے کے بعد آپ کے طالب علم ڈیش بورڈ میں سند جاری کر دی جائے گی۔'),
                  ),
                  _buildFaqItem(
                    index: 1,
                    question: _tr('Are the lectures live or pre-recorded?', re: 'Lectures live hain ya recorded?', ur: 'کیا اسباق لائیو ہیں یا ریکارڈ شدہ؟'),
                    answer: _tr('All lectures are pre-recorded in studio HD quality so you can learn at your own pace anytime, with periodic live Q&A sessions with the instructors.', re: 'HD quality recorded lectures hain jinhein aap kabhi bhi dekh sakte hain.', ur: 'تمام اسباق ایچ ڈی کوالٹی میں ریکارڈ شدہ ہیں تاکہ آپ اپنی سہولت کے مطابق سیکھ سکیں۔'),
                  ),
                  _buildFaqItem(
                    index: 2,
                    question: _tr('Can I pay via monthly installments?', re: 'Kya monthly installment me pay kar sakte hain?', ur: 'کیا ماہانہ اقساط میں ادائیگی ممکن ہے؟'),
                    answer: _tr('Yes! Zabira Academy supports flexible monthly payment plans (EMI) with zero extra interest fees.', re: 'Ji haan, aap aasan mahana aqsaat me adaigi kar sakte hain.', ur: 'جی ہاں، ذبیرا اکیڈمی آسان ماہانہ اقساط کی سہولت فراہم کرتی ہے۔'),
                  ),
                  _buildFaqItem(
                    index: 3,
                    question: _tr('Is this course beginner-friendly?', re: 'Kya yeh course beginners ke liye hai?', ur: 'کیا یہ کورس ابتدائی طلبہ کے لیے ہے؟'),
                    answer: _tr('Yes, this course is crafted from the ground up to ensure concepts are easy to understand for beginners while offering rich depth for advanced learners.', re: 'Ji haan, bilkul bunyad se aasan andaz me sikhaya gaya hai.', ur: 'جی ہاں، یہ کورس بنیادی سطح سے آسان انداز میں تیار کیا گیا ہے۔'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── 10. CHOOSE PAYMENT PLAN Section ────────────────────────────────
          _buildPaymentPlanSection(),

          const SizedBox(height: 20),

          // ── 11. Universal Scholarship Promotional Banner ───────────────────
          const ScholarshipPromoBanner(),

          const SizedBox(height: 20),

          // ── 12. Similar Courses Section ────────────────────────────────────
          if (_relatedCourses.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('Similar Courses', re: 'Miltay Jultay Courses', ur: 'ملتے جلتے کورسز'),
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._relatedCourses.map((rc) {
                    final rcImg = rc.fullHeroBannerUrl ?? rc.fullThumbnailUrl;
                    return GestureDetector(
                      onTap: () {
                        context.push('/courses/${rc.id}');
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 80,
                                height: 60,
                                color: brandNavy,
                                child: rcImg != null && rcImg.isNotEmpty
                                    ? Image.network(rcImg, fit: BoxFit.cover, errorBuilder: (ctx, e, _) => Container(color: brandNavy))
                                    : Container(color: brandNavy),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rc.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: brandNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 14, color: brandGold),
                                      const SizedBox(width: 3),
                                      Text(
                                        rc.rating.toStringAsFixed(1),
                                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: brandNavy),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${rc.effectivePrice.toInt()}',
                                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: brandNavy),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── 13. Zabira Branding Footer ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            color: const Color(0xFFF1F5F9),
            child: Column(
              children: [
                Text(
                  'ZABIRA ACADEMY',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: brandNavy,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Empowering Islamic Learning Worldwide',
                  style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Text(
                  '© 2026 Zabira Academy. All rights reserved.',
                  style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ── Payment Plan Section ───────────────────────────────────────────────────
  Widget _buildPaymentPlanSection() {
    final c = _course!;
    final wishlist = context.watch<WishlistController>();
    final isWishlisted = wishlist.isWishlisted(c.id);

    final isMonthly = _selectedPaymentPlanIndex == 1;

    final fullPrice = c.effectivePrice.toInt();
    final originalPrice = (c.price > c.effectivePrice ? c.price : c.effectivePrice * 1.5).toInt();
    final savings = (originalPrice - fullPrice).clamp(0, originalPrice);

    final installmentAmount = c.paymentOptions.length > 1 && c.paymentOptions[1].installmentAmount != null
        ? c.paymentOptions[1].installmentAmount!.toInt()
        : (fullPrice / 6).ceil();
    final totalMonthlyCourseFee = (installmentAmount * 6);
    final remainingMonthly = (totalMonthlyCourseFee - installmentAmount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: brandNavyDark,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: brandNavy.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: One-to-One Class • Group Class
            Text(
              _tr('One-to-One Class • Group Class', re: 'One-to-One Class • Group Class', ur: 'ون ٹو ون کلاس • گروپ کلاس'),
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              c.shortDescription != null && c.shortDescription!.isNotEmpty
                  ? _cleanHtml(c.shortDescription)
                  : 'Learn with correct pronunciation, proper Tajweed rules, and confidence. This beginner-friendly course is tailored for comprehensive mastery.',
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: const Color(0xFFCBD5E1),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // CHOOSE PAYMENT PLAN Header & Badge
            Row(
              children: [
                Text(
                  _tr('CHOOSE PAYMENT PLAN', re: 'CHOOSE PAYMENT PLAN', ur: 'ادائیگی کا منصوبہ منتخب کریں'),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: brandGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: brandGold, width: 1.0),
                  ),
                  child: Text(
                    _tr('FULL PAYMENT OFFER', re: 'FULL PAYMENT OFFER', ur: 'مکمل ادائیگی کی پیشکش'),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: brandGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2 Payment Plan Tabs (Side-by-side)
            Row(
              children: [
                // Tab 1: Pay in Full
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPaymentPlanIndex = 0);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: !isMonthly ? brandGold : brandNavyCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _tr('Pay in Full', re: 'Pay in Full', ur: 'مکمل ادائیگی'),
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: !isMonthly ? brandNavy : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$fullPrice',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !isMonthly ? brandNavy.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Tab 2: Monthly
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPaymentPlanIndex = 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isMonthly ? brandGold : brandNavyCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _tr('Monthly', re: 'Monthly (Mahana)', ur: 'ماہانہ ادائیگی'),
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isMonthly ? brandNavy : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$installmentAmount/mo',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMonthly ? brandNavy.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Plan Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: brandNavyDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: brandGold, width: 1.2),
              ),
              child: isMonthly
                  ? _buildMonthlyPlanDetails(installmentAmount, totalMonthlyCourseFee)
                  : _buildFullPlanDetails(fullPrice, originalPrice, savings),
            ),
            const SizedBox(height: 16),

            // PRICING SUMMARY Table
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: brandNavyCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tr('PRICING SUMMARY', re: 'PRICING SUMMARY', ur: 'قیمت کی تفصیل'),
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!isMonthly) ...[
                    _buildSummaryRow(_tr('Amount payable today', re: 'Aaj ki adaigi', ur: 'آج ادا کی جانے والی رقم'), '₹$fullPrice', isGold: true),
                    _buildSummaryRow(_tr('Total course fee', re: 'Total Course Fee', ur: 'کل کورس فیس'), '₹$fullPrice'),
                    if (savings > 0) _buildSummaryRow(_tr('Discount', re: 'Discount', ur: 'رعایت'), '- ₹$savings'),
                    if (savings > 0) _buildSummaryRow(_tr('Total savings', re: 'Total Bachat', ur: 'کل بچت'), '₹$savings', isGreen: true),
                  ] else ...[
                    _buildSummaryRow(_tr('Amount payable today', re: 'Aaj ki adaigi', ur: 'آج ادا کی جانے والی رقم'), '₹$installmentAmount', isGold: true),
                    _buildSummaryRow(_tr('Total course fee', re: 'Total Course Fee', ur: 'کل کورس فیس'), '₹$totalMonthlyCourseFee'),
                    _buildSummaryRow(_tr('Monthly installment', re: 'Mahana qist', ur: 'ماہانہ قسط'), '₹$installmentAmount'),
                    _buildSummaryRow(_tr('Remaining payments', re: 'Baqi adaigi', ur: 'باقی ادائیگیاں'), '₹$remainingMonthly'),
                    _buildSummaryRow(_tr('Course duration', re: 'Duration', ur: 'کورس کی مدت'), c.duration.isNotEmpty ? c.duration : '6 months'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // [🛒 Add to Cart] Golden Button (#c4a95b)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart_outlined, size: 19),
                label: Text(
                  _tr('Add to Cart', re: 'Add to Cart', ur: 'کارٹ میں شامل کریں'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGold,
                  foregroundColor: brandNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // [⚡ Pay ₹... Today] Dark Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _onEnrollAction,
                icon: const Icon(Icons.bolt_rounded, size: 20, color: brandGold),
                label: Text(
                  _tr('Pay ₹${isMonthly ? installmentAmount : fullPrice} Today', re: 'Pay ₹${isMonthly ? installmentAmount : fullPrice} Today', ur: 'آج ₹${isMonthly ? installmentAmount : fullPrice} ادا کریں'),
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: brandGold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandNavyCard,
                  foregroundColor: brandGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // [♡] + [🎁 Book Free Trial]
            Row(
              children: [
                // Wishlist button: Golden #c4a95b
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final added = wishlist.toggleCourse(c);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added ? 'Saved to Wishlist ⭐' : 'Removed from Wishlist',
                          style: GoogleFonts.outfit(color: Colors.white),
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: brandNavy,
                      ),
                    );
                  },
                  child: Container(
                    width: 50,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brandNavyCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isWishlisted ? brandGold : Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Book Free Trial button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _bookFreeTrial,
                      icon: const Icon(Icons.card_giftcard_rounded, size: 18, color: Colors.white),
                      label: Text(
                        _tr('Book Free Trial', re: 'Book Free Trial', ur: 'مفت ٹرائل بک کریں'),
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: brandNavyCard,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // [🔗 Share] Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: _shareCourse,
                icon: const Icon(Icons.share_outlined, size: 18, color: Colors.white),
                label: Text(
                  _tr('Share', re: 'Share', ur: 'شیئر کریں'),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: brandNavyCard,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // "This course includes:" 7 Items
            Text(
              _tr('This course includes:', re: 'Is Course Mein Shamil Hai:', ur: 'اس کورس میں شامل ہے:'),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildCourseIncludeItem(Icons.play_circle_outline_rounded, '${c.totalLessons > 0 ? c.totalLessons : 98} ${_tr('lessons', re: 'lessons', ur: 'اسباق')}'),
            _buildCourseIncludeItem(Icons.description_outlined, _tr('Study material provided', re: 'Study material provided', ur: 'مطالعاتی مواد شامل ہے')),
            _buildCourseIncludeItem(Icons.military_tech_outlined, _tr('Certificate on completion', re: 'Certificate on completion', ur: 'تکمیل پر سند')),
            _buildCourseIncludeItem(Icons.workspace_premium_outlined, _tr('Quizzes included', re: 'Quizzes included', ur: 'کوئزز شامل ہیں')),
            _buildCourseIncludeItem(Icons.assignment_outlined, _tr('Assignments included', re: 'Assignments included', ur: 'اسائنمنٹس شامل ہیں')),
            _buildCourseIncludeItem(Icons.access_time_rounded, c.duration.isNotEmpty ? c.duration : '6 months'),
            _buildCourseIncludeItem(Icons.language_rounded, c.languagesDisplay),
          ],
        ),
      ),
    );
  }

  Widget _buildFullPlanDetails(int fullPrice, int originalPrice, int savings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: brandGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: brandNavy, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              _tr('Pay in Full', re: 'Pay in Full', ur: 'مکمل ادائیگی'),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: brandGold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '✨ BEST VALUE',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: brandNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹$fullPrice',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            if (originalPrice > fullPrice) ...[
              const SizedBox(width: 8),
              Text(
                '₹$originalPrice',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  decoration: TextDecoration.lineThrough,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
        if (savings > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${_tr('Save', re: 'Bachat', ur: 'بچت')} ₹$savings • ${_tr('One-time payment', re: 'One-time payment', ur: 'ایک بار ادائیگی')}',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00A884),
            ),
          ),
        ],
        const SizedBox(height: 12),

        // 4 Checkmarks
        Row(
          children: [
            Expanded(child: _buildCheckItem(_tr('Best Value', re: 'Best Value', ur: 'بہترین قیمت'))),
            Expanded(child: _buildCheckItem(_tr('One-Time Payment', re: 'One-Time Payment', ur: 'یک وقتی ادائیگی'))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildCheckItem(_tr('Instant Enrollment', re: 'Instant Enrollment', ur: 'فوری داخلہ'))),
            Expanded(child: _buildCheckItem(_tr('No Monthly Bills', re: 'No Monthly Bills', ur: 'ماہانہ بلوں سے پاک'))),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyPlanDetails(int installmentAmount, int totalFee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: brandGold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.autorenew_rounded, color: brandNavy, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              _tr('Pay Monthly', re: 'Monthly (Mahana)', ur: 'ماہانہ ادائیگی'),
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Price Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹$installmentAmount',
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '/ month',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '6 months • Total ₹$totalFee',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: const Color(0xFFCBD5E1),
          ),
        ),
        const SizedBox(height: 12),

        // 4 Checkmarks
        Row(
          children: [
            Expanded(child: _buildCheckItem(_tr('Flexible Payments', re: 'Flexible Payments', ur: 'آسان ادائیگیاں'))),
            Expanded(child: _buildCheckItem(_tr('Lower Upfront Cost', re: 'Kam Kharcha', ur: 'کم ابتدائی لاگت'))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildCheckItem(_tr('Pay From Dashboard', re: 'Dashboard Se Pay Karein', ur: 'ڈیش بورڈ سے ادائیگی'))),
            Expanded(child: _buildCheckItem(_tr('Easy Installments', re: 'Aasan Aqsaat', ur: 'آسان اقساط'))),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckItem(String label) {
    return Row(
      children: [
        const Icon(Icons.check_rounded, color: brandGold, size: 14),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String title, String val, {bool isGold = false, bool isGreen = false}) {
    Color col = Colors.white;
    if (isGold) col = brandGold;
    if (isGreen) col = const Color(0xFF00A884);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: const Color(0xFFCBD5E1),
            ),
          ),
          const Spacer(),
          Text(
            val,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: col,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseIncludeItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: brandGold, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFE2E8F0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _buildHeroBadge(String text, Color bg, Color textCol, {bool isBordered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: isBordered ? Border.all(color: brandGold, width: 1.0) : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textCol,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Exact Matching 3-Language Segmented Tab Switcher ───────────────────────
  Widget _buildExactLangTab({
    required int index,
    required Widget iconWidget,
    required String label,
    bool isUrduTab = false,
  }) {
    final isSelected = _selectedLanguageIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedLanguageIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? brandNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandNavy.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturePillar(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Center(
            child: Icon(icon, size: 18, color: brandGold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: brandNavy,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: brandGold, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFFE2E8F0),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReqItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.arrow_forward_ios_rounded, color: brandNavy, size: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        tag,
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: brandNavy,
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required int index,
    required String question,
    required String answer,
  }) {
    final isExpanded = _expandedFaqIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _expandedFaqIndex = isExpanded ? -1 : index;
              });
            },
            title: Text(
              question,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: brandNavy,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.remove_rounded : Icons.add_rounded,
              color: brandNavy,
              size: 18,
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                answer,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom Fixed Action Bar: Wishlist - Quick Enroll - Add to Cart ──────────
  Widget _buildBottomBar() {
    final c = _course!;
    final enrollment = context.watch<EnrollmentController>();
    final wishlist = context.watch<WishlistController>();
    final isEnrolled = enrollment.isEnrolled(widget.courseId);
    final isWishlisted = wishlist.isWishlisted(c.id);

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 8 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Wishlist Button (Left)
          SizedBox(
            width: 48,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                final added = wishlist.toggleCourse(c);
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      added ? 'Saved to Wishlist ⭐' : 'Removed from Wishlist',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    backgroundColor: brandNavy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isWishlisted ? brandGold : brandNavy,
                backgroundColor: isWishlisted ? const Color(0xFFFFFBEB) : Colors.white,
                side: BorderSide(
                  color: isWishlisted ? brandGold : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(
                isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isWishlisted ? const Color(0xFFDC2626) : brandNavy,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Quick Enroll / Start Learning Button (Center)
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: enrollment.isLoading ? null : _onEnrollAction,
                icon: Icon(
                  isEnrolled ? Icons.play_circle_outline_rounded : Icons.bolt_rounded,
                  size: 19,
                  color: Colors.white,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                label: Text(
                  isEnrolled
                      ? 'Continue Learning'
                      : (enrollment.isLoading ? 'Processing...' : 'Quick Enroll'),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          // 3. Add to Cart Button (Right)
          if (!isEnrolled) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: OutlinedButton(
                onPressed: _addToCart,
                style: OutlinedButton.styleFrom(
                  foregroundColor: brandNavy,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 21, color: brandNavy),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Exact Lucide Book-Open Icon implementation
class _LucideBookOpenIcon extends StatelessWidget {
  const _LucideBookOpenIcon({this.size = 18, this.color = const Color(0xFF112039)});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LucideBookOpenPainter(color),
    );
  }
}

class _LucideBookOpenPainter extends CustomPainter {
  final Color color;
  _LucideBookOpenPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Center spine: M12 5v16
    final p1 = Path();
    p1.moveTo(12 * scale, 5 * scale);
    p1.lineTo(12 * scale, 21 * scale);
    canvas.drawPath(p1, paint);

    // Left page: M12 5a5 5 0 00-4-2H4a2 2 0 00-2 2v12a2 2 0 001.999 2H8a5 5 0 014 2 5 5 0 014-2z
    final pLeft = Path();
    pLeft.moveTo(12 * scale, 5 * scale);
    pLeft.cubicTo(10 * scale, 3 * scale, 6 * scale, 3 * scale, 4 * scale, 3 * scale);
    pLeft.lineTo(2 * scale, 5 * scale);
    pLeft.lineTo(2 * scale, 17 * scale);
    pLeft.lineTo(4 * scale, 19 * scale);
    pLeft.cubicTo(6 * scale, 19 * scale, 10 * scale, 21 * scale, 12 * scale, 21 * scale);
    canvas.drawPath(pLeft, paint);

    // Right page: M20.001 19A2 2 0 0022 17V5a2 2 0 00-1.999-2L16 3.002A5 5 0 0012 5
    final pRight = Path();
    pRight.moveTo(12 * scale, 5 * scale);
    pRight.cubicTo(14 * scale, 3 * scale, 18 * scale, 3 * scale, 20 * scale, 3 * scale);
    pRight.lineTo(22 * scale, 5 * scale);
    pRight.lineTo(22 * scale, 17 * scale);
    pRight.lineTo(20 * scale, 19 * scale);
    pRight.cubicTo(18 * scale, 19 * scale, 14 * scale, 21 * scale, 12 * scale, 21 * scale);
    canvas.drawPath(pRight, paint);
  }

  @override
  bool shouldRepaint(covariant _LucideBookOpenPainter oldDelegate) => oldDelegate.color != color;
}
