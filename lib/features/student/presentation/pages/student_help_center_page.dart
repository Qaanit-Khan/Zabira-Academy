import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/student_controller.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 10: Student Help Center & Support (1:1 with `10 - profile help centre 10.pdf`)
class StudentHelpCenterPage extends StatefulWidget {
  const StudentHelpCenterPage({super.key});

  @override
  State<StudentHelpCenterPage> createState() => _StudentHelpCenterPageState();
}

class _StudentHelpCenterPageState extends State<StudentHelpCenterPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I access my enrolled courses?',
      'answer': 'Go to your Dashboard or My Courses section and tap on any enrolled course to start learning immediately.',
    },
    {
      'question': 'I paid but cannot see my course.',
      'answer': 'Payments may take a few moments to sync. If your order shows "Payment Successful" under My Orders, try refreshing. If the issue persists, contact support with your Payment ID.',
    },
    {
      'question': 'Can I change my email or phone number?',
      'answer': 'For account security, verified email and phone numbers cannot be changed directly in the app. Please contact support if you need to update them.',
    },
    {
      'question': 'Where are my certificates?',
      'answer': 'Certificates are automatically generated upon 100% course completion and will appear in your Certificates tab for download and verification.',
    },
    {
      'question': 'How do free trial classes work?',
      'answer': 'Free trials allow you to experience one-on-one sessions with our qualified teachers before committing to full enrollment.',
    },
  ];

  int? _expandedFaqIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.isAuthenticated && auth.user != null) {
        context.read<StudentController>().loadDashboard(
              auth.currentToken,
              defaultName: auth.user!.displayName,
              defaultEmail: auth.user!.email,
              defaultPhoto: auth.user!.photoUrl,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final studentCtrl = context.watch<StudentController>();
    final user = auth.user;
    final dashboard = studentCtrl.dashboard;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Dark Navy Top Hero Header
              StudentHeroHeader(user: user, dashboard: dashboard),

              // 2. Horizontal Nav Bar (Index 9: Help Center)
              const StudentNavTabsBar(selectedIndex: 9),

              // 3. Breadcrumb & Section Title
              const StudentBreadcrumbHeader(
                currentPage: 'Help & Support',
                title: 'Help & Support',
                subtitle: 'Find answers quickly or reach the Zabira Academy support team.',
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 4. 2x2 Support Cards Grid
                  _buildSupportCardsGrid(context),
                  const SizedBox(height: 28),

                  // 5. Frequently Asked Questions Section Header
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Frequently asked questions',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 6. Expandable FAQ List
                  _buildFaqList(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildSupportCardsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                icon: LucideIcons.mail,
                title: 'Contact support',
                subtitle: 'support@zabira.academy',
                onTap: () => launchUrl(Uri.parse('mailto:support@zabira.academy')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSupportCard(
                icon: LucideIcons.messageCircle,
                title: 'WhatsApp support',
                subtitle: 'Chat with our team',
                onTap: () => launchUrl(Uri.parse('https://wa.me/919579746616'), mode: LaunchMode.externalApplication),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSupportCard(
                icon: LucideIcons.ticket,
                title: 'Raise a ticket',
                subtitle: 'Include Student ID and order number',
                onTap: () => launchUrl(Uri.parse('mailto:support@zabira.academy?subject=Support Ticket: Student ID')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSupportCard(
                icon: LucideIcons.helpCircle,
                title: 'Account help',
                subtitle: 'Update profile details',
                onTap: () => context.go('/student/profile'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: const Color(0xFFC9A84C)),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _faqs.length,
        separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          final isExpanded = _expandedFaqIndex == index;

          return InkWell(
            onTap: () {
              setState(() {
                _expandedFaqIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          faq['question']!,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isExpanded ? '−' : '+',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Text(
                      faq['answer']!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
