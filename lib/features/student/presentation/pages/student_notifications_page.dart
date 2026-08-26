import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/student_controller.dart';
import '../../data/models/student_dashboard_model.dart';
import '../../data/services/student_api_service.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 9: Student Notifications (1:1 with `9 - profile notification 9.pdf`)
class StudentNotificationsPage extends StatefulWidget {
  const StudentNotificationsPage({super.key});

  @override
  State<StudentNotificationsPage> createState() => _StudentNotificationsPageState();
}

class _StudentNotificationsPageState extends State<StudentNotificationsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StudentApiService _apiService = StudentApiService();

  bool _isLoading = true;
  List<StudentNotificationItem> _notifications = [];

  static final List<StudentNotificationItem> _defaultNotifications = [
    StudentNotificationItem(
      id: 1,
      title: 'Payment Successful',
      message: 'Your payment of ₹1,499 for Quran Recitation & Tajweed Mastery was confirmed.',
      type: 'PAYMENT',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    StudentNotificationItem(
      id: 2,
      title: 'Live Class Scheduled',
      message: 'Your live session "Surah Al-Mulk Analysis" with Sheikh Mansoor starts tomorrow at 6:00 PM IST.',
      type: 'LIVE CLASS',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    StudentNotificationItem(
      id: 3,
      title: 'Certificate Ready to Download',
      message: 'Congratulations! Your certificate of completion for "Arabic Basics" is now available.',
      type: 'CERTIFICATE',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    StudentNotificationItem(
      id: 4,
      title: 'New Course Launch: Fiqh Masterclass',
      message: 'Explore Islamic Jurisprudence with certified scholars. Early bird access is now live.',
      type: 'ANNOUNCEMENT',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated && auth.user != null) {
      context.read<StudentController>().loadDashboard(
            auth.currentToken,
            defaultName: auth.user!.displayName,
            defaultEmail: auth.user!.email,
            defaultPhoto: auth.user!.photoUrl,
          );

      setState(() => _isLoading = true);
      try {
        final notifs = await _apiService.getNotifications(token: auth.currentToken ?? '');
        if (mounted) {
          setState(() {
            _notifications = notifs.isNotEmpty ? notifs : _defaultNotifications;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _notifications = _defaultNotifications;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _notifications = _defaultNotifications;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    final auth = context.read<AuthController>();
    setState(() {
      _notifications = _notifications.map((n) {
        return StudentNotificationItem(
          id: n.id,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
    });

    if (auth.currentToken != null) {
      try {
        await _apiService.markNotificationsRead(token: auth.currentToken!);
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF112039),
          content: Text(
            'All notifications marked as read',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year, $hour:$minute $ampm';
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
      body: RefreshIndicator(
        color: const Color(0xFFC9A84C),
        onRefresh: () async {
          await _loadNotifications();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Dark Navy Top Hero Header
                StudentHeroHeader(user: user, dashboard: dashboard),

                // 2. Horizontal Nav Bar (Index 8: Notifications)
                const StudentNavTabsBar(selectedIndex: 8),

                // 3. Breadcrumb & Section Title
                StudentBreadcrumbHeader(
                  currentPage: 'Notifications',
                  title: 'Notifications',
                  subtitle: 'Course updates, payments, deadlines, live classes, events, and announcements',
                  actionWidget: OutlinedButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(LucideIcons.check, size: 14, color: Color(0xFF0F172A)),
                    label: Text(
                      'Mark all read',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),

                // 4. Notifications List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                          ),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : _buildNotificationsList(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.bell, size: 26, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'You are all caught up. Important updates will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final typeLower = notif.type.toLowerCase();
        final isPayment = typeLower.contains('pay');
        final isClass = typeLower.contains('class') || typeLower.contains('live');
        final isCert = typeLower.contains('cert');

        final IconData iconData = isPayment
            ? LucideIcons.creditCard
            : (isClass
                ? LucideIcons.video
                : (isCert ? LucideIcons.award : LucideIcons.bell));

        final Color iconBg = isPayment
            ? const Color(0xFFECFDF5)
            : (isClass
                ? const Color(0xFFEFF6FF)
                : (isCert ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC)));

        final Color iconColor = isPayment
            ? const Color(0xFF10B981)
            : (isClass
                ? const Color(0xFF3B82F6)
                : (isCert ? const Color(0xFFC9A84C) : const Color(0xFF64748B)));

        final tag = notif.type.isNotEmpty ? notif.type.toUpperCase() : 'NOTIFICATION';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? Colors.white : const Color(0xFFFCFDFE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notif.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(notif.isRead ? 3 : 6),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon card
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (!notif.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC9A84C),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Body
                    Text(
                      notif.message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tag Badge & Timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (notif.createdAt != null)
                          Text(
                            _formatDate(notif.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF94A3B8),
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
      },
    );
  }
}
