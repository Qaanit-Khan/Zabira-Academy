import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/auth_controller.dart';
import '../../../../features/auth/presentation/widgets/auth_bottom_sheet.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/scholarship_promo_banner.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/event_item_model.dart';
import '../../data/services/events_api_service.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage({
    super.key,
    required this.eventId,
    this.initialEvent,
    this.scrollToRegister = false,
  });

  final int eventId;
  final EventItemModel? initialEvent;
  final bool scrollToRegister;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  final EventsApiService _service = EventsApiService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _registrationSectionKey = GlobalKey();

  EventFullDetailsModel? _details;
  bool _isLoading = true;
  String? _errorMessage;

  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gradeController = TextEditingController();
  final _schoolController = TextEditingController();
  bool _isSubmitting = false;

  // Brand Colors
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  @override
  void initState() {
    super.initState();
    _fetchFullDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gradeController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullData = await _service.getFullEventDetails(id: widget.eventId);
      if (mounted) {
        setState(() {
          _details = fullData;
          _isLoading = false;
        });

        _prefillUserInfo();

        if (widget.scrollToRegister) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToRegistrationSection();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        if (widget.initialEvent != null) {
          setState(() {
            _details = EventFullDetailsModel(
              event: widget.initialEvent!,
              description: widget.initialEvent!.shortDescription,
            );
            _isLoading = false;
          });
          _prefillUserInfo();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Unable to load event details.';
          });
        }
      }
    }
  }

  void _prefillUserInfo() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated && auth.user != null) {
      final user = auth.user!;
      if (_nameController.text.isEmpty) _nameController.text = user.displayName;
      if (_emailController.text.isEmpty) _emailController.text = user.email;
      final phone = user.phone ?? user.mobile;
      if (_phoneController.text.isEmpty && phone != null && phone.isNotEmpty) {
        _phoneController.text = phone;
      }
    }
  }

  void _scrollToRegistrationSection() {
    final context = _registrationSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleRegisterSubmit() async {
    final auth = context.read<AuthController>();
    final event = _details?.event ?? widget.initialEvent;
    if (event == null) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final grade = _gradeController.text.trim();
    final school = _schoolController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in your name and email address',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      await _service.registerForEvent(
        eventId: event.id,
        name: name,
        email: email,
        phone: phone.isNotEmpty ? phone : '9999999999',
        grade: grade.isNotEmpty ? grade : event.grade,
        notes: school.isNotEmpty ? 'School: $school' : null,
        token: auth.currentToken,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration submitted! We will send updates to $email.'),
          backgroundColor: brandNavy,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: brandGold, size: 28),
            const SizedBox(width: 10),
            Text(
              'Registration Confirmed',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: brandNavy,
              ),
            ),
          ],
        ),
        content: Text(
          'You have successfully registered for "${_details?.event.title ?? "this event"}". Further details and study kits will be emailed to you.',
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF475569)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGold,
              foregroundColor: brandNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _shareEvent() {
    final event = _details?.event ?? widget.initialEvent;
    if (event != null) {
      final shareText = 'Check out "${event.title}" on Zabira Academy! Date: ${event.formattedDate} • ${event.formattedLocation}. Join here: https://zabiraacademy.com/events/${event.slug}';
      Clipboard.setData(ClipboardData(text: shareText));
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: brandGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'Event link copied to clipboard!',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: brandNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isAuth = auth.isAuthenticated && auth.user != null;

    if (_isLoading && _details == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: ZabiraLoader(size: 40)),
      );
    }

    if (_errorMessage != null && _details == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: brandNavy, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: ZabiraErrorState(
          title: 'Event Not Found',
          message: _errorMessage!,
          onRetry: _fetchFullDetails,
        ),
      );
    }

    final event = _details!.event;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: brandNavy, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: brandNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: brandNavy, size: 20),
            onPressed: _shareEvent,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStickyBar(event),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Full Hero Banner with Overlay & Badges ───────────────────
            _buildHeroBanner(event),

            // ── 2. Header Info & Key Attributes ────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tag Chips (Category, Mode, Age Group, Grade)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPillTag(event.category.toUpperCase(), brandGold, brandNavy),
                      _buildPillTag(event.eventType.toUpperCase(), brandNavy, Colors.white),
                      if (event.grade.isNotEmpty)
                        _buildPillTag(event.grade, const Color(0xFFE2E8F0), brandNavy),
                      if (event.ageGroup.isNotEmpty)
                        _buildPillTag(event.ageGroup, const Color(0xFFE2E8F0), brandNavy),
                      if (event.language.isNotEmpty)
                        _buildPillTag(event.language, const Color(0xFFE2E8F0), brandNavy),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── 3. Quick Registration Summary Card (Dark Navy #112039) ─
                  _buildQuickStatsCard(event),

                  const SizedBox(height: 24),

                  // ── 4. Direct Registration Form Section ───────────────────
                  Container(
                    key: _registrationSectionKey,
                    child: _buildRegistrationForm(isAuth, event),
                  ),

                  const SizedBox(height: 24),

                  // ── 5. About Event Overview ────────────────────────────────
                  _buildAboutSection(event),

                  const SizedBox(height: 24),

                  // ── 6. Event Roadmap / Schedule (Phases 1 - 5) ──────────────
                  if (_details!.roadmap.isNotEmpty) ...[
                    _buildRoadmapTimeline(_details!.roadmap),
                    const SizedBox(height: 24),
                  ],

                  // ── 7. Organizer & Mentor Card ─────────────────────────────
                  _buildOrganizerCard(event),

                  const SizedBox(height: 24),

                  // ── 8. FAQs Accordion ──────────────────────────────────────
                  if (_details!.faqs.isNotEmpty) ...[
                    _buildFaqSection(_details!.faqs),
                    const SizedBox(height: 24),
                  ],

                  // ── 9. Universal Scholarship Promo ────────────────────────
                  const ScholarshipPromoBanner(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Banner ────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(EventItemModel event) {
    final bannerUrl = event.resolvedBannerImage ?? event.resolvedFeaturedImage;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          bannerUrl != null && bannerUrl.isNotEmpty
              ? ZabiraNetworkImage(
                  imageUrl: bannerUrl,
                  fit: BoxFit.cover,
                  fallbackIcon: Icons.event_rounded,
                )
              : Container(
                  color: brandNavy,
                  child: const Center(
                    child: Icon(Icons.event_rounded, color: brandGold, size: 48),
                  ),
                ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          // Top Right Free / Fee Badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: event.registrationFee <= 0 ? const Color(0xFF00A884) : brandNavy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: brandGold, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                event.registrationFee <= 0 ? '100% FREE EVENT' : '₹${event.registrationFee.toInt()}',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pill Tag ───────────────────────────────────────────────────────────────
  Widget _buildPillTag(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  // ── Quick Registration Stats Card (Dark Navy #112039) ──────────────────────
  Widget _buildQuickStatsCard(EventItemModel event) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brandNavy,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brandGold.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_available_rounded, color: brandGold, size: 22),
              const SizedBox(width: 8),
              Text(
                'EVENT DETAILS',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: brandGold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildQuickStatRow(Icons.calendar_today_rounded, 'Date', event.formattedDate),
          const Divider(color: Color(0xFF1E3A63), height: 16),
          _buildQuickStatRow(Icons.access_time_rounded, 'Time', event.formattedTime),
          const Divider(color: Color(0xFF1E3A63), height: 16),
          _buildQuickStatRow(Icons.location_on_rounded, 'Venue', event.formattedLocation),
          const Divider(color: Color(0xFF1E3A63), height: 16),
          _buildQuickStatRow(
            Icons.confirmation_number_rounded,
            'Registration',
            event.registrationFee <= 0 ? 'Free Entry' : '₹${event.registrationFee.toInt()}',
            isGoldValue: true,
          ),

          const SizedBox(height: 16),

          // Direct Scroll to Form Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _scrollToRegistrationSection,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGold,
                foregroundColor: brandNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Register for this Event',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_downward_rounded, size: 16, color: brandNavy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(IconData icon, String label, String value, {bool isGoldValue = false}) {
    return Row(
      children: [
        Icon(icon, color: brandGold, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isGoldValue ? brandGold : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Registration Form Section ──────────────────────────────────────────────
  Widget _buildRegistrationForm(bool isAuth, EventItemModel event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: brandNavy.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.08),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: brandNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.how_to_reg_rounded, color: brandGold, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Registration',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: brandNavy,
                      ),
                    ),
                    Text(
                      isAuth ? 'Logged in as ${context.read<AuthController>().user?.displayName}' : 'Fill in your details below to register',
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

          const SizedBox(height: 18),

          // Form Fields
          _buildFormField('Full Name *', _nameController, Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _buildFormField('Email Address *', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildFormField('Phone / WhatsApp Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _buildFormField('Grade / Age Group', _gradeController, Icons.school_outlined, hint: event.grade.isNotEmpty ? event.grade : 'e.g. Grade 5 / 12 Years'),
          const SizedBox(height: 12),
          _buildFormField('School / Institution', _schoolController, Icons.location_city_outlined, hint: 'Participating School Name'),

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleRegisterSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGold,
                foregroundColor: brandNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: brandNavy),
                    )
                  : Text(
                      'Confirm & Submit Registration',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: brandNavy,
                      ),
                    ),
            ),
          ),

          if (!isAuth) ...[
            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () => showAuthBottomSheet(context),
                child: Text(
                  'Already have an account? Sign in for 1-tap registration',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: brandNavy,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: brandNavy,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: GoogleFonts.outfit(fontSize: 13.5, color: brandNavy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8)),
              prefixIcon: Icon(icon, size: 18, color: brandNavy),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            ),
          ),
        ),
      ],
    );
  }

  // ── About Event Section ───────────────────────────────────────────────────
  Widget _buildAboutSection(EventItemModel event) {
    final desc = _details?.description.isNotEmpty == true
        ? _details!.description
        : event.shortDescription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this Event',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: brandNavy,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            desc.replaceAll(RegExp(r'<[^>]*>'), ''), // strip html tags
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ── Roadmap & Agenda Timeline ──────────────────────────────────────────────
  Widget _buildRoadmapTimeline(List<EventRoadmapPhase> roadmap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline_rounded, color: brandGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Event Schedule & Roadmap',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: brandNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roadmap.length,
          itemBuilder: (context, index) {
            final phase = roadmap[index];
            final isLast = index == roadmap.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number circle & timeline vertical line
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: brandNavy,
                          shape: BoxShape.circle,
                          border: Border.all(color: brandGold, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${phase.phaseNumber}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: brandGold,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: brandGold.withValues(alpha: 0.5),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Phase Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (phase.dateRange.isNotEmpty) ...[
                              Text(
                                phase.dateRange.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: brandGold,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              phase.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: brandNavy,
                              ),
                            ),
                            if (phase.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                phase.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF64748B),
                                  height: 1.45,
                                ),
                              ),
                            ],
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
      ],
    );
  }

  // ── Organizer & Mentor Card ────────────────────────────────────────────────
  Widget _buildOrganizerCard(EventItemModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: brandNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.school_rounded, color: brandGold, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORGANIZED BY',
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: brandGold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  event.organizer,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: brandNavy,
                  ),
                ),
                if (event.instructor.isNotEmpty)
                  Text(
                    'Mentors: ${event.instructor}',
                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── FAQs Section ───────────────────────────────────────────────────────────
  Widget _buildFaqSection(List<EventFaqItem> faqs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: brandGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: brandNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: faqs.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                iconColor: brandGold,
                collapsedIconColor: brandNavy,
                title: Text(
                  faq.question,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: brandNavy,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Text(
                      faq.answer,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Bottom Sticky Bar ──────────────────────────────────────────────────────
  Widget _buildBottomStickyBar(EventItemModel event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Share Button
            IconButton(
              onPressed: _shareEvent,
              icon: const Icon(Icons.share_outlined, color: brandNavy),
            ),

            const SizedBox(width: 8),

            // Register CTA Button (Golden #C9A84C)
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _scrollToRegistrationSection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGold,
                    foregroundColor: brandNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    event.registrationFee <= 0 ? 'Register Now (Free)' : 'Register Now (₹${event.registrationFee.toInt()})',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: brandNavy,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
