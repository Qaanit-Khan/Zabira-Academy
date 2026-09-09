import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_app_bar.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';

/// Zabira Academy — Scholarship & Financial Aid Page
///
/// Built precisely to match the 9-page design reference PDF:
/// - Brand Golden: #C9A84C
/// - Dark Navy Blue: #112039
/// - Lucide Icons throughout
/// - Preserves native app header, drawer, and bottom navigation
class ScholarshipPage extends StatefulWidget {
  const ScholarshipPage({super.key});

  @override
  State<ScholarshipPage> createState() => _ScholarshipPageState();
}

class _ScholarshipPageState extends State<ScholarshipPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // FAQ Accordion expanded state tracking
  final Set<int> _expandedFaqIndices = {0};

  static const Color _navy = Color(0xFF112039);
  static const Color _navyCard = Color(0xFF0F1E36);
  static const Color _navyBorder = Color(0xFF1E3253);
  static const Color _gold = Color(0xFFC9A84C);
  static const Color _goldLight = Color(0xFFDFBF65);
  static const Color _surfaceBg = Color(0xFFF8FAFC);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textLightMuted = Color(0xFF94A3B8);

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Who is eligible for the Zabira Academy Scholarship?',
      'answer':
          'Any student whose family cannot afford course fees due to financial constraints is eligible. We give priority to orphans, low-income households, and dedicated students eager to learn the Holy Quran and Arabic.',
    },
    {
      'question': 'What courses are covered under the scholarship?',
      'answer':
          'The scholarship covers 100% of tuition for Quran Reading, Tajweed Mastery, Arabic Language, and Islamic Studies courses, including all certified teacher sessions, live classes, digital books, exams, and certificates.',
    },
    {
      'question': 'How is financial need verified?',
      'answer':
          'All applications are reviewed with complete confidentiality and dignity by our scholarship committee through basic household verification to ensure funds reach those who need them most.',
    },
    {
      'question': 'How can I sponsor a student?',
      'answer':
          'You can sponsor a student by covering their monthly fee (₹499/month), quarterly tuition, or full annual course fee (₹4,999). You will receive regular progress reports and updates on the student\'s learning journey.',
    },
    {
      'question': 'Can I contribute small amounts to the Scholarship Fund?',
      'answer':
          'Yes! Support for the Zabira Scholarship Fund starts from just ₹10. Micro-donations pool together to support thousands of children across the Ummah.',
    },
    {
      'question': 'Is this scholarship Zakat and Sadaqah eligible?',
      'answer':
          'Yes, 100%. Sponsoring Islamic education for deserving and underprivileged students is directly eligible for both Zakat and Sadaqah Jariyah.',
    },
    {
      'question': 'How long does application review take?',
      'answer':
          'Applications are typically reviewed within 48 to 72 hours. Our team contacts the parents or guardians directly via WhatsApp or email with the enrollment confirmation.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: _surfaceBg,
      appBar: ZabiraAppBar(
        showBackButton: true,
        onBackPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.home);
          }
        },
        onMenuPressed: () => AppDrawer.open(context, AppRoutes.scholarship),
      ),
      drawer: const AppDrawer(currentRoute: AppRoutes.scholarship),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Hero Dark Section (Page 1) ──────────────────────────────────
            _buildHeroSection(),

            // ── 2. Our Commitment Section (Page 2) ─────────────────────────────
            _buildCommitmentSection(),

            // ── 3. Quranic Ayat Callout Box (Page 3) ───────────────────────────
            _buildQuranAyatCard(),

            // ── 4. How It Works 4-Step Process (Page 3) ────────────────────────
            _buildHowItWorksSection(),

            // ── 5. Ways To Help / Sponsor & Fund Cards (Pages 4 & 5) ────────────
            _buildWaysToHelpSection(),

            // ── 6. Help Build Next Generation Dark Banner (Page 5) ──────────────
            _buildBuildNextGenBanner(),

            // ── 7. Transparency You Can Trust Section (Page 6) ──────────────────
            _buildTransparencySection(),

            // ── 8. Need Financial Assistance Card (Page 7) ─────────────────────
            _buildNeedAssistanceSection(),

            // ── 9. Frequently Asked Questions (Page 7) ─────────────────────────
            _buildFaqSection(),

            // ── 10. Zabira Branding & Footer Ecosystem Links (Page 9) ──────────
            _buildScholarshipFooterSection(),

            // Breathing space for floating bottom navigation bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: HERO SECTION
  // ===========================================================================
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.md,
        AppSpacing.screenHorizontal,
        AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Breadcrumb & Category Badge Row
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              // Breadcrumb
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Home',
                        style: GoogleFonts.outfit(
                          color: _textLightMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Text(
                          '/',
                          style: GoogleFonts.outfit(
                            color: _textLightMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        'Scholarships',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Program Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 13, color: _gold),
                    const SizedBox(width: 6),
                    Text(
                      'ZABIRA SCHOLARSHIP PROGRAM',
                      style: GoogleFonts.outfit(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Main Headline
          Text(
            'Every Child Deserves\nIslamic Education.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              height: 1.22,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Highlighted Subtitle
          Text(
            'Financial hardship should never stop a child from learning the Quran, Arabic or Islamic Studies.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFFF1F5F9),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Body Description
          Text(
            'At Zabira Academy, we believe every child deserves access to high-quality Islamic education. If a family genuinely cannot afford the course fees, they may apply for financial assistance through our Scholarship Program. Through Zabira Academy and the generous support of sponsors, deserving students receive the same premium learning experience without financial barriers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textLightMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          // 1. Apply for Scholarship (Primary Gold)
          _buildActionButton(
            label: 'APPLY FOR SCHOLARSHIP',
            icon: LucideIcons.arrowRight,
            isGold: true,
            onTap: () => _openApplyScholarshipModal(context),
          ),

          const SizedBox(height: 10),

          // 2. Sponsor A Student (Navy Fill / Border)
          _buildActionButton(
            label: 'SPONSOR A STUDENT',
            icon: LucideIcons.heartHandshake,
            isGold: false,
            onTap: () => _openSponsorStudentModal(context),
          ),

          const SizedBox(height: 10),

          // 3. Support Scholarship Fund (Navy Fill / Border)
          _buildActionButton(
            label: 'SUPPORT SCHOLARSHIP FUND',
            icon: LucideIcons.coins,
            isGold: false,
            onTap: () => _openSupportFundModal(context),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Hero Image with Floating Pill Caption
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(25), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Image.asset(
                    'assets/images/home/scholarship/scholarship_hero.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 240,
                      color: _navyBorder,
                      child: const Center(
                        child: Icon(LucideIcons.graduationCap, size: 50, color: _gold),
                      ),
                    ),
                  ),

                  // Floating Caption Pill
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _navy.withAlpha(220),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withAlpha(70), width: 1),
                    ),
                    child: Text(
                      'Quality Islamic education — accessible to every child.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 2: OUR COMMITMENT (Page 2)
  // ===========================================================================
  Widget _buildCommitmentSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Banner Artwork Graphic
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/home/scholarship/scholarship_commitment_banner.png',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Badge: • OUR PROMISE •
          _buildPillBadge('OUR PROMISE'),

          const SizedBox(height: AppSpacing.sm),

          // Title: Our Commitment
          Text(
            'Our Commitment',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Mission statements
          Text(
            'Our mission is to make high-quality Islamic education accessible to every child.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF334155),
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Course fees help us build and sustain a professional learning platform, while our Scholarship Program ensures that deserving students are never turned away because of financial hardship.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textMuted,
              fontSize: 13,
              height: 1.55,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Two Callout Cards: Students & Sponsors
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check, size: 12, color: _navy),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Students who can pay help sustain the Academy.',
                        style: GoogleFonts.outfit(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFCBD5E1)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: _navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.heart, size: 12, color: _gold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sponsors help educate those who cannot.',
                        style: GoogleFonts.outfit(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: QURANIC AYAT CARD (Page 3)
  // ===========================================================================
  Widget _buildQuranAyatCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withAlpha(70), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _navy.withAlpha(40),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Arabic Ayat Calligraphy
          Text(
            'وَمَنْ أَحْيَاهَا فَكَأَنَّمَا أَحْيَا النَّاسَ جَمِيعًا',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: GoogleFonts.amiri(
              color: _gold,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 12),

          // Translation
          Text(
            'And whoever saves a life — it is as if he had saved mankind entirely.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFFF1F5F9),
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 10),

          // Reference
          Text(
            '— SURAH AL-MA\'IDAH 5:32',
            style: GoogleFonts.outfit(
              color: _goldLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 4: HOW IT WORKS (Page 3)
  // ===========================================================================
  Widget _buildHowItWorksSection() {
    final steps = [
      {
        'num': '1',
        'icon': LucideIcons.bookOpen,
        'title': 'Apply',
        'desc': 'Parents submit a scholarship application for financial assistance.',
      },
      {
        'num': '2',
        'icon': LucideIcons.shieldCheck,
        'title': 'Review',
        'desc': 'Every application is reviewed carefully based on need and available scholarship funds.',
      },
      {
        'num': '3',
        'icon': LucideIcons.heart,
        'title': 'Scholarship Approved',
        'desc': 'Eligible students are sponsored by Zabira Academy or generous supporters.',
      },
      {
        'num': '4',
        'icon': LucideIcons.sparkles,
        'title': 'Start Learning',
        'desc': 'Students receive the same premium courses, teachers, exams and certificates as every other student.',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPillBadge('PROCESS'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'How It Works',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A clear path from need to learning — with dignity and care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 4 Step Cards
          ...steps.map((step) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Step Number
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            step['num'] as String,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      // Lucide Icon
                      Icon(
                        step['icon'] as IconData,
                        size: 24,
                        color: _gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    step['title'] as String,
                    style: GoogleFonts.outfit(
                      color: _navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['desc'] as String,
                    style: GoogleFonts.outfit(
                      color: _textMuted,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 5: WAYS TO HELP (Pages 4 & 5)
  // ===========================================================================
  Widget _buildWaysToHelpSection() {
    return Container(
      color: _surfaceBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPillBadge('WAYS TO HELP'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Choose How You Want to Help',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Card 1: Sponsor a Student
          _buildHelpCard(
            imagePath: 'assets/images/home/scholarship/scholarship_sponsor_student.png',
            title: 'Sponsor a Student',
            description:
                'Sponsor one child by covering the complete fee of a course or supporting monthly learning.',
            highlight: 'Perfect for those who want to directly change a child\'s future.',
            buttonText: 'SPONSOR A STUDENT',
            onTap: () => _openSponsorStudentModal(context),
          ),

          const SizedBox(height: 20),

          // Card 2: Scholarship Fund
          _buildHelpCard(
            imagePath: 'assets/images/home/scholarship/scholarship_fund_students.png',
            title: 'Scholarship Fund',
            description:
                'Support the Scholarship Fund.\nEven a small contribution helps provide quality Islamic education to deserving students.',
            highlight: 'Support starts from just ₹10.',
            buttonText: 'SUPPORT SCHOLARSHIP FUND',
            onTap: () => _openSupportFundModal(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required String imagePath,
    required String title,
    required String description,
    required String highlight,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 190,
                color: _navyCard,
                child: const Center(
                  child: Icon(LucideIcons.graduationCap, size: 40, color: _gold),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF475569),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _gold.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    highlight,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF8C6D1F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 6: HELP BUILD THE NEXT GENERATION (Page 5)
  // ===========================================================================
  Widget _buildBuildNextGenBanner() {
    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Help Build the Next Generation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Whether you sponsor one student, contribute ₹10 or simply share our mission, you become part of spreading Islamic knowledge.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textLightMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Together we can ensure that no child is left behind because of financial hardship.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _goldLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // 3 Buttons Row / Column
          _buildActionButton(
            label: 'SPONSOR A STUDENT',
            icon: LucideIcons.heartHandshake,
            isGold: true,
            onTap: () => _openSponsorStudentModal(context),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'SUPPORT SCHOLARSHIP FUND',
            icon: LucideIcons.coins,
            isGold: false,
            onTap: () => _openSupportFundModal(context),
          ),
          const SizedBox(height: 10),
          _buildActionButton(
            label: 'APPLY FOR SCHOLARSHIP',
            icon: LucideIcons.arrowRight,
            isGold: false,
            onTap: () => _openApplyScholarshipModal(context),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 7: TRANSPARENCY YOU CAN TRUST (Page 6)
  // ===========================================================================
  Widget _buildTransparencySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Infographic Image Banner
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/home/scholarship/scholarship_annual_report.png',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _buildPillBadge('TRUST'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Transparency You Can Trust',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Every scholarship contribution is recorded and used only for student education.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: const Color(0xFF334155),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monthly, quarterly and annual reports are published so every supporter can see how scholarship funds are being used.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Bullet Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildTransparencyBullet('No hidden charges.'),
                const SizedBox(height: 6),
                _buildTransparencyBullet('No misuse.'),
                const SizedBox(height: 6),
                _buildTransparencyBullet('Complete transparency.'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openTransparencyReportModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VIEW TRANSPARENCY REPORT',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 15, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencyBullet(String text) {
    return Row(
      children: [
        const Icon(LucideIcons.shieldCheck, size: 16, color: _gold),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: _navy,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION 8: NEED FINANCIAL ASSISTANCE (Page 7)
  // ===========================================================================
  Widget _buildNeedAssistanceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            child: Image.asset(
              'assets/images/home/scholarship/scholarship_assistance.png',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 180,
                color: _navyCard,
                child: const Center(
                  child: Icon(LucideIcons.school, size: 40, color: _gold),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Need Financial Assistance?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'If your family is unable to afford course fees, you may request financial assistance.\n\nEvery application is reviewed with care and confidentiality.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _openApplyScholarshipModal(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'APPLY NOW',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 9: FREQUENTLY ASKED QUESTIONS (Page 7)
  // ===========================================================================
  Widget _buildFaqSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.x2l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPillBadge('FAQ'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Frequently Asked Questions',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // FAQ Accordion List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faqs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              final isExpanded = _expandedFaqIndices.contains(index);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFFF8FAFC) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded ? _gold.withAlpha(120) : const Color(0xFFE2E8F0),
                    width: isExpanded ? 1.4 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedFaqIndices.remove(index);
                          } else {
                            _expandedFaqIndices.add(index);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: isExpanded ? _navy : _navy.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.helpCircle,
                                size: 14,
                                color: isExpanded ? _gold : _navy,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                faq['question']!,
                                style: GoogleFonts.outfit(
                                  color: _navy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                              size: 18,
                              color: isExpanded ? _gold : _textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer']!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF475569),
                            fontSize: 13,
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
      ),
    );
  }

  // ===========================================================================
  // SECTION 10: SCHOLARSHIP FOOTER & PAYMENT BADGES (Page 9)
  // ===========================================================================
  Widget _buildScholarshipFooterSection() {
    return Container(
      color: _navy,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.x2l,
        AppSpacing.screenHorizontal,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Zabira Academy Logo / Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.bookOpen, color: _gold, size: 22),
              const SizedBox(width: 8),
              Text(
                'ZABIRA ACADEMY',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Where authentic Islamic education meets modern learning through courses, books, media, and meaningful learning experiences.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textLightMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Payment Methods Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/home/scholarship/scholarship_payment_methods.png',
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _navyCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.shieldCheck, size: 14, color: _gold),
                    const SizedBox(width: 8),
                    Text(
                      'SECURE PAYMENTS ACCEPTED: UPI, VISA, MASTERCARD',
                      style: GoogleFonts.outfit(
                        color: _textLightMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Copyright
          Text(
            '© 2026 Zabira Academy. All rights reserved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _textLightMuted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Privacy Policy • Terms of Service • Refund Policy',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: _gold.withAlpha(200),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPER WIDGETS
  // ===========================================================================
  Widget _buildPillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withAlpha(90)),
      ),
      child: Text(
        '• $text •',
        style: GoogleFonts.outfit(
          color: const Color(0xFF8C6D1F),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool isGold,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isGold ? _gold : _navyCard,
          foregroundColor: isGold ? _navy : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isGold
                ? BorderSide.none
                : const BorderSide(color: _navyBorder, width: 1.2),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: isGold ? _navy : Colors.white),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MODALS & FORMS
  // ===========================================================================

  /// 1. Apply For Scholarship Form Bottom Sheet
  void _openApplyScholarshipModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScholarshipApplicationModal(),
    );
  }

  /// 2. Sponsor A Student Bottom Sheet
  void _openSponsorStudentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SponsorStudentModal(),
    );
  }

  /// 3. Support Scholarship Fund Bottom Sheet
  void _openSupportFundModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SupportFundModal(),
    );
  }

  /// 4. Transparency Report Viewer Bottom Sheet
  void _openTransparencyReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TransparencyReportModal(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL 1: SCHOLARSHIP APPLICATION FORM
// ─────────────────────────────────────────────────────────────────────────────
class _ScholarshipApplicationModal extends StatefulWidget {
  @override
  State<_ScholarshipApplicationModal> createState() =>
      _ScholarshipApplicationModalState();
}

class _ScholarshipApplicationModalState
    extends State<_ScholarshipApplicationModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _guardianController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedCourse = 'Quran Reading & Tajweed';
  bool _isSubmitting = false;

  final List<String> _courseOptions = [
    'Quran Reading & Tajweed',
    'Understanding Quran & Tafseer',
    'Arabic Language for Beginners',
    'Namaz & Daily Duas',
    'Muslim Youth Life Skills',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _guardianController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF112039),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Color(0xFFC9A84C), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Scholarship application submitted! Our team will contact you within 48 hours.',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.graduationCap,
                        color: Color(0xFF112039), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apply for Scholarship',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF112039),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '100% confidential & fee-free application',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Student Name
              _buildInputField(
                label: 'Student Full Name',
                controller: _nameController,
                icon: LucideIcons.user,
                hint: 'Enter student name',
              ),

              const SizedBox(height: 12),

              // Guardian Name
              _buildInputField(
                label: 'Parent / Guardian Name',
                controller: _guardianController,
                icon: LucideIcons.users,
                hint: 'Enter guardian name',
              ),

              const SizedBox(height: 12),

              // Phone / WhatsApp
              _buildInputField(
                label: 'WhatsApp / Phone Number',
                controller: _phoneController,
                icon: LucideIcons.phone,
                hint: '+91 9876543210',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 12),

              // Email Address
              _buildInputField(
                label: 'Email Address (Optional)',
                controller: _emailController,
                icon: LucideIcons.mail,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                isRequired: false,
              ),

              const SizedBox(height: 12),

              // Course Selector
              Text(
                'Desired Course',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF112039),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCourse,
                    isExpanded: true,
                    icon: const Icon(LucideIcons.chevronDown,
                        size: 16, color: Color(0xFF64748B)),
                    items: _courseOptions.map((course) {
                      return DropdownMenuItem(
                        value: course,
                        child: Text(
                          course,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF112039),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCourse = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Reason Note
              _buildInputField(
                label: 'Reason for Financial Assistance',
                controller: _reasonController,
                icon: LucideIcons.fileText,
                hint: 'Briefly describe your situation...',
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A84C),
                    foregroundColor: const Color(0xFF112039),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF112039),
                          ),
                        )
                      : Text(
                          'SUBMIT APPLICATION',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF112039),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.outfit(
            color: const Color(0xFF112039),
            fontSize: 13,
          ),
          validator: isRequired
              ? (val) => val == null || val.trim().isEmpty
                  ? 'This field is required'
                  : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 13,
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 16, color: const Color(0xFF64748B))
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFC9A84C), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL 2: SPONSOR A STUDENT
// ─────────────────────────────────────────────────────────────────────────────
class _SponsorStudentModal extends StatefulWidget {
  @override
  State<_SponsorStudentModal> createState() => _SponsorStudentModalState();
}

class _SponsorStudentModalState extends State<_SponsorStudentModal> {
  int _selectedTierIndex = 0;

  final List<Map<String, dynamic>> _tiers = [
    {
      'title': '1 Month Sponsorship',
      'amount': '₹499',
      'period': '/ month',
      'desc': 'Covers full tuition and study books for 1 child for 1 month.',
      'popular': false,
    },
    {
      'title': '3 Months Term Sponsorship',
      'amount': '₹1,499',
      'period': '/ quarter',
      'desc': 'Complete foundational Quran Tajweed course term sponsorship.',
      'popular': true,
    },
    {
      'title': '1 Full Year Sponsorship',
      'amount': '₹4,999',
      'period': '/ year',
      'desc': 'Complete annual sponsorship covering all learning tracks and exams.',
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF112039),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.heartHandshake,
                    color: Color(0xFFC9A84C), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sponsor a Student',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF112039),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Directly transform a child\'s Islamic education',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Tiers
          ...List.generate(_tiers.length, (index) {
            final tier = _tiers[index];
            final isSelected = _selectedTierIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedTierIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFC9A84C).withAlpha(15)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFC9A84C)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC9A84C)
                              : const Color(0xFF94A3B8),
                          width: 2,
                        ),
                        color: isSelected
                            ? const Color(0xFFC9A84C)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(LucideIcons.check,
                                  size: 12, color: Color(0xFF112039)),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tier['title'] as String,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF112039),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (tier['popular'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC9A84C),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'POPULAR',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF112039),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tier['desc'] as String,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tier['amount'] as String,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF112039),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Proceed Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF112039),
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Proceeding to secure sponsorship payment of ${_tiers[_selectedTierIndex]['amount']}...',
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF112039),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'PROCEED TO SPONSOR (${_tiers[_selectedTierIndex]['amount']})',
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL 3: SUPPORT SCHOLARSHIP FUND (FROM ₹10)
// ─────────────────────────────────────────────────────────────────────────────
class _SupportFundModal extends StatefulWidget {
  @override
  State<_SupportFundModal> createState() => _SupportFundModalState();
}

class _SupportFundModalState extends State<_SupportFundModal> {
  final List<int> _quickAmounts = [10, 50, 100, 250, 500, 1000];
  int _selectedAmount = 50;
  final _customAmountController = TextEditingController();

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.coins,
                    color: Color(0xFF112039), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Scholarship Fund',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF112039),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Every small contribution starts from just ₹10',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            'Select Contribution Amount',
            style: GoogleFonts.outfit(
              color: const Color(0xFF112039),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          // Quick Amount Chips Grid
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAmounts.map((amt) {
              final isSelected = _selectedAmount == amt;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAmount = amt;
                    _customAmountController.clear();
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF112039)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF112039)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    '₹$amt',
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : const Color(0xFF112039),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Custom Amount Field
          TextField(
            controller: _customAmountController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null && parsed > 0) {
                setState(() => _selectedAmount = parsed);
              }
            },
            decoration: InputDecoration(
              hintText: 'Or enter custom amount in ₹',
              hintStyle: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.outfit(
                color: const Color(0xFF112039),
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFFC9A84C), width: 1.4),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Contribute Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF112039),
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Opening payment gateway for ₹$_selectedAmount contribution. May Allah reward you!',
                      style: GoogleFonts.outfit(color: Colors.white),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A84C),
                foregroundColor: const Color(0xFF112039),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'CONTRIBUTE ₹$_selectedAmount NOW',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL 4: TRANSPARENCY & IMPACT REPORT
// ─────────────────────────────────────────────────────────────────────────────
class _TransparencyReportModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF112039),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.fileSpreadsheet,
                      color: Color(0xFFC9A84C), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transparency & Audit Report',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF112039),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '100% Fund Utilization Breakdown',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Stat Cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Sponsored',
                    value: '1,749,163',
                    subtitle: 'Children in programs',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Fund Efficiency',
                    value: '100%',
                    subtitle: 'Direct to education',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Breakdown Rows
            _buildAuditRow('Quran & Tajweed Full Waivers', '62% of funds'),
            _buildAuditRow('Arabic & Islamic Studies Books', '23% of funds'),
            _buildAuditRow('Certified Mentor Stipends', '15% of funds'),
            _buildAuditRow('Administrative / Processing Fee', '0% (Zero Fee)'),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF112039),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'CLOSE REPORT',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF112039),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: const Color(0xFF334155),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF112039),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
