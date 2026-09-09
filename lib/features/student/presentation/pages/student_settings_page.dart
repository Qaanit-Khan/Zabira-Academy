import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/student_controller.dart';
import '../../data/models/student_profile_models.dart';
import '../../data/services/student_api_service.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 11: Student Settings (1:1 with `11 - profile settings 11.pdf`)
class StudentSettingsPage extends StatefulWidget {
  const StudentSettingsPage({super.key});

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StudentApiService _apiService = StudentApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  StudentProfileData _profile = StudentProfileData();

  String _language = 'English';
  String _theme = 'System';
  String _timeZone = 'Asia/Kolkata';
  String _dateFormat = 'DD/MM/YYYY';

  bool _emailNotifs = true;
  bool _whatsappNotifs = true;
  bool _pushNotifs = false;
  bool _marketingNotifs = false;
  bool _assignmentNotifs = true;
  bool _liveClassNotifs = true;
  bool _eventNotifs = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
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
        final profile = await _apiService.getProfile(
          token: auth.currentToken ?? '',
          defaultEmail: auth.user!.email,
          defaultName: auth.user!.displayName,
          defaultPhoto: auth.user!.photoUrl,
        );

        if (mounted) {
          setState(() {
            _profile = profile;
            _language = profile.preferredLanguage.isNotEmpty ? profile.preferredLanguage : 'English';
            _theme = profile.theme.isNotEmpty ? profile.theme : 'System';
            _timeZone = profile.timeZone.isNotEmpty ? profile.timeZone : 'Asia/Kolkata';
            _dateFormat = profile.dateFormat.isNotEmpty ? profile.dateFormat : 'DD/MM/YYYY';

            _emailNotifs = profile.emailNotifications;
            _whatsappNotifs = profile.whatsappNotifications;
            _pushNotifs = profile.pushNotifications;
            _marketingNotifs = profile.marketingEmails;
            _assignmentNotifs = profile.assignmentReminders;
            _liveClassNotifs = profile.liveClassReminders;
            _eventNotifs = profile.eventNotifications;

            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) return;

    setState(() => _isSaving = true);

    final updated = _profile.copyWith(
      preferredLanguage: _language,
      theme: _theme,
      timeZone: _timeZone,
      dateFormat: _dateFormat,
      emailNotifications: _emailNotifs,
      whatsappNotifications: _whatsappNotifs,
      pushNotifications: _pushNotifs,
      marketingEmails: _marketingNotifs,
      assignmentReminders: _assignmentNotifs,
      liveClassReminders: _liveClassNotifs,
      eventNotifications: _eventNotifs,
    );

    try {
      final success = await _apiService.updateProfile(
        token: auth.currentToken ?? '',
        profile: updated,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _profile = updated;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? const Color(0xFF112039) : Colors.red,
            content: Text(
              success ? 'Settings saved successfully!' : 'Failed to save settings.',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: $e', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final studentCtrl = context.watch<StudentController>();
    final user = auth.user;
    final dashboard = studentCtrl.dashboard;

    final userEmail = _profile.email.isNotEmpty ? _profile.email : (user?.email ?? 'qaanitumar771@gmail.com');
    final studentId = _profile.studentId.isNotEmpty ? _profile.studentId : 'ZAB-STU-000044';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: RefreshIndicator(
        color: const Color(0xFFC9A84C),
        onRefresh: () async {
          await _loadSettings();
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

                // 2. Horizontal Nav Bar (Index 10: Settings)
                const StudentNavTabsBar(selectedIndex: 10),

                // 3. Breadcrumb & Section Title
                const StudentBreadcrumbHeader(
                  currentPage: 'Settings',
                  title: 'Settings',
                  subtitle: 'Manage your preferences and notification settings.',
                ),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: Color(0xFFC9A84C)),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 4. Preferences Card (Language, Theme, Time Zone, Date Format)
                        _buildPreferencesCard(),
                        const SizedBox(height: 16),

                        // 5. Notification Preferences Card
                        _buildNotificationsCard(),
                        const SizedBox(height: 16),

                        // 6. User Status Caption
                        Center(
                          child: Text(
                            'Signed in as $userEmail · Student ID $studentId',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 7. Save Settings Golden Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF112039)),
                                    ),
                                  )
                                : const Icon(LucideIcons.save, size: 16, color: Color(0xFF112039)),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save settings',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF112039),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC9A84C),
                              foregroundColor: const Color(0xFF112039),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
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
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Language',
                  value: _language,
                  items: const ['English', 'Arabic', 'Urdu', 'Hindi'],
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Theme',
                  value: _theme,
                  items: const ['System', 'Light', 'Dark'],
                  onChanged: (v) => setState(() => _theme = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Time zone',
                  value: _timeZone,
                  items: const ['Asia/Kolkata', 'UTC', 'Asia/Dubai', 'America/New_York'],
                  onChanged: (v) => setState(() => _timeZone = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Date format',
                  value: _dateFormat,
                  items: const ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD'],
                  onChanged: (v) => setState(() => _dateFormat = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Platform display is always DD/MM/YYYY in Asia/Kolkata (IST).',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            title: 'Email notifications',
            value: _emailNotifs,
            onChanged: (v) => setState(() => _emailNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'WhatsApp notifications (when configured)',
            subtitle: 'Delivery runs when WhatsApp messaging is configured for the academy.',
            value: _whatsappNotifs,
            onChanged: (v) => setState(() => _whatsappNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Push notifications',
            value: _pushNotifs,
            onChanged: (v) => setState(() => _pushNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Marketing emails',
            value: _marketingNotifs,
            onChanged: (v) => setState(() => _marketingNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Assignment reminders',
            value: _assignmentNotifs,
            onChanged: (v) => setState(() => _assignmentNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Live class reminders',
            value: _liveClassNotifs,
            onChanged: (v) => setState(() => _liveClassNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Event notifications',
            value: _eventNotifs,
            onChanged: (v) => setState(() => _eventNotifs = v),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }

  Widget _buildToggleRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFC9A84C) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value ? const Color(0xFFC9A84C) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              icon: const Icon(LucideIcons.chevronDown, size: 16, color: Color(0xFF64748B)),
              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
