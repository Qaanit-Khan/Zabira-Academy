import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../app/router.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/student_controller.dart';
import '../../data/models/student_profile_models.dart';
import '../../data/services/student_api_service.dart';
import '../widgets/student_breadcrumb.dart';
import '../widgets/student_hero_header.dart';
import '../widgets/student_nav_tabs_bar.dart';

/// Screen 6: Student My Profile (1:1 with `6 - profile my profile 6.pdf`)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final StudentApiService _apiService = StudentApiService();

  bool _isLoading = true;
  bool _isSaving = false;
  StudentProfileData _profile = StudentProfileData();

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _dobController;
  late TextEditingController _countryController;
  late TextEditingController _stateController;
  late TextEditingController _cityController;
  late TextEditingController _postalController;
  late TextEditingController _addressController;
  late TextEditingController _qualificationController;
  late TextEditingController _occupationController;
  late TextEditingController _institutionController;
  late TextEditingController _bioController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _websiteController;
  late TextEditingController _linkedinController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _youtubeController;

  String _gender = 'Male';
  String _preferredLanguage = 'English';
  String _timeZone = 'Asia/Kolkata';

  // Notifications
  bool _emailNotifs = true;
  bool _whatsappNotifs = true;
  bool _pushNotifs = false;
  bool _marketingNotifs = false;
  bool _assignmentNotifs = true;
  bool _liveClassNotifs = true;
  bool _eventNotifs = true;
  bool _courseNotifs = true;
  bool _paymentNotifs = true;
  bool _certNotifs = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _displayNameController = TextEditingController();
    _dobController = TextEditingController();
    _countryController = TextEditingController();
    _stateController = TextEditingController();
    _cityController = TextEditingController();
    _postalController = TextEditingController();
    _addressController = TextEditingController();
    _qualificationController = TextEditingController();
    _occupationController = TextEditingController();
    _institutionController = TextEditingController();
    _bioController = TextEditingController();
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
    _parentNameController = TextEditingController();
    _parentPhoneController = TextEditingController();
    _websiteController = TextEditingController();
    _linkedinController = TextEditingController();
    _twitterController = TextEditingController();
    _instagramController = TextEditingController();
    _youtubeController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _addressController.dispose();
    _qualificationController.dispose();
    _occupationController.dispose();
    _institutionController.dispose();
    _bioController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
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
            _populateFields(profile);
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

  void _populateFields(StudentProfileData p) {
    _firstNameController.text = p.firstName;
    _lastNameController.text = p.lastName;
    _displayNameController.text = p.displayName;
    _dobController.text = p.dateOfBirth;
    _countryController.text = p.country;
    _stateController.text = p.state;
    _cityController.text = p.city;
    _postalController.text = p.postalCode;
    _addressController.text = p.address;
    _qualificationController.text = p.qualification;
    _occupationController.text = p.occupation;
    _institutionController.text = p.institution;
    _bioController.text = p.bio;
    _emergencyNameController.text = p.emergencyName;
    _emergencyPhoneController.text = p.emergencyPhone;
    _parentNameController.text = p.parentName;
    _parentPhoneController.text = p.parentPhone;
    _websiteController.text = p.website;
    _linkedinController.text = p.linkedin;
    _twitterController.text = p.twitter;
    _instagramController.text = p.instagram;
    _youtubeController.text = p.youtube;

    _gender = p.gender.isNotEmpty ? p.gender : 'Male';
    _preferredLanguage = p.preferredLanguage.isNotEmpty ? p.preferredLanguage : 'English';
    _timeZone = p.timeZone.isNotEmpty ? p.timeZone : 'Asia/Kolkata';

    _emailNotifs = p.emailNotifications;
    _whatsappNotifs = p.whatsappNotifications;
    _pushNotifs = p.pushNotifications;
    _marketingNotifs = p.marketingEmails;
    _assignmentNotifs = p.assignmentReminders;
    _liveClassNotifs = p.liveClassReminders;
    _eventNotifs = p.eventNotifications;
    _courseNotifs = p.courseUpdates;
    _paymentNotifs = p.paymentUpdates;
    _certNotifs = p.certificateAlerts;
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) return;

    setState(() => _isSaving = true);

    final updated = _profile.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      gender: _gender,
      country: _countryController.text.trim(),
      state: _stateController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalController.text.trim(),
      address: _addressController.text.trim(),
      preferredLanguage: _preferredLanguage,
      timeZone: _timeZone,
      qualification: _qualificationController.text.trim(),
      occupation: _occupationController.text.trim(),
      institution: _institutionController.text.trim(),
      bio: _bioController.text.trim(),
      emergencyName: _emergencyNameController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
      parentName: _parentNameController.text.trim(),
      parentPhone: _parentPhoneController.text.trim(),
      website: _websiteController.text.trim(),
      linkedin: _linkedinController.text.trim(),
      twitter: _twitterController.text.trim(),
      instagram: _instagramController.text.trim(),
      youtube: _youtubeController.text.trim(),
      emailNotifications: _emailNotifs,
      whatsappNotifications: _whatsappNotifs,
      pushNotifications: _pushNotifs,
      marketingEmails: _marketingNotifs,
      assignmentReminders: _assignmentNotifs,
      liveClassReminders: _liveClassNotifs,
      eventNotifications: _eventNotifs,
      courseUpdates: _courseNotifs,
      paymentUpdates: _paymentNotifs,
      certificateAlerts: _certNotifs,
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

        // Sync with AuthController and SharedPreferences
        await auth.updateUserProfile(
          displayName: updated.displayName,
          photoUrl: updated.photoUrl,
        );

        if (!mounted) return;

        // Sync with Student Dashboard
        final studentCtrl = context.read<StudentController>();
        studentCtrl.loadDashboard(
          auth.currentToken,
          defaultName: updated.displayName,
          defaultEmail: updated.email,
          defaultPhoto: updated.photoUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: success ? const Color(0xFF112039) : Colors.red,
            content: Text(
              success ? 'Profile updated successfully!' : 'Failed to update profile.',
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

  bool _isUploadingPhoto = false;

  Future<void> _showImageSourceModal() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Profile Photo',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.image, color: Color(0xFF3B82F6), size: 20),
                  ),
                  title: Text('Choose from Gallery', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.camera, color: Color(0xFFC9A84C), size: 20),
                  ),
                  title: Text('Take Photo with Camera', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final auth = context.read<AuthController>();
    final studentCtrl = context.read<StudentController>();
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploadingPhoto = true);

      final bytes = await picked.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      String? newUrl;
      if (auth.currentToken != null) {
        newUrl = await _apiService.uploadAvatar(
          token: auth.currentToken!,
          imageBase64: base64Str,
        );
      }

      if (newUrl == null || newUrl.isEmpty) {
        newUrl = base64Str;
      }

      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _profile = _profile.copyWith(photoUrl: newUrl);
        });

        // 1. Update AuthController in-memory and SharedPreferences
        await auth.updateUserProfile(
          displayName: _profile.displayName,
          photoUrl: newUrl,
        );

        if (!mounted) return;

        // 2. Also update student controller dashboard
        studentCtrl.loadDashboard(
          auth.currentToken,
          defaultName: _profile.displayName,
          defaultEmail: _profile.email,
          defaultPhoto: newUrl,
        );

        // 3. Persist profile changes to backend
        if (auth.currentToken != null) {
          _apiService.updateProfile(
            token: auth.currentToken!,
            profile: _profile.copyWith(photoUrl: newUrl),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF112039),
            content: Text(
              'Profile photo updated successfully!',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to pick photo: $e', style: GoogleFonts.outfit(color: Colors.white)),
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

    final initials = (_profile.displayName.isNotEmpty ? _profile.displayName : (user?.displayName ?? 'Student'))
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: AppRoutes.profile),
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: -1),
      body: RefreshIndicator(
        color: const Color(0xFFC9A84C),
        onRefresh: () async {
          await _loadProfile();
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

                // 2. Horizontal Nav Bar (Index 5: My Profile)
                const StudentNavTabsBar(selectedIndex: 5),

                // 3. Breadcrumb & Section Title
                const StudentBreadcrumbHeader(
                  currentPage: 'My Profile',
                  title: 'My Profile',
                  subtitle: 'Manage your personal information, photo, and communication preferences.',
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
                        // ── Section 1: Profile Photo Card ─────────────────────
                        _buildProfilePhotoCard(initials),
                        const SizedBox(height: 24),

                        // ── Section 2: Verified Identity ──────────────────────
                        _buildSectionHeader('VERIFIED IDENTITY', 'These fields cannot be changed for security'),
                        const SizedBox(height: 12),
                        _buildVerifiedIdentityCard(),
                        const SizedBox(height: 24),

                        // ── Section 3: Personal Information ───────────────────
                        _buildSectionHeader('PERSONAL INFORMATION', 'Your name and basic details'),
                        const SizedBox(height: 12),
                        _buildPersonalInfoCard(),
                        const SizedBox(height: 24),

                        // ── Section 4: Location ───────────────────────────────
                        _buildSectionHeader('LOCATION', 'Where you study from'),
                        const SizedBox(height: 12),
                        _buildLocationCard(),
                        const SizedBox(height: 24),

                        // ── Section 5: Education & Work ───────────────────────
                        _buildSectionHeader('EDUCATION & WORK', 'Optional background details'),
                        const SizedBox(height: 12),
                        _buildEducationWorkCard(),
                        const SizedBox(height: 24),

                        // ── Section 6: Emergency & Guardian ───────────────────
                        _buildSectionHeader('EMERGENCY & GUARDIAN', 'Optional contact details'),
                        const SizedBox(height: 12),
                        _buildEmergencyGuardianCard(),
                        const SizedBox(height: 24),

                        // ── Section 7: Social Links ───────────────────────────
                        _buildSectionHeader('SOCIAL LINKS', 'Optional public profiles'),
                        const SizedBox(height: 12),
                        _buildSocialLinksCard(),
                        const SizedBox(height: 24),

                        // ── Section 8: Notification Preferences ───────────────
                        _buildSectionHeader('NOTIFICATION PREFERENCES', 'Choose how you want to hear from Zabira Academy'),
                        const SizedBox(height: 12),
                        _buildNotificationPreferencesCard(),
                        const SizedBox(height: 24),

                        // Save Profile Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF112039)),
                                  )
                                : const Icon(LucideIcons.save, size: 18, color: Color(0xFF112039)),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Profile',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF112039),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC9A84C),
                              foregroundColor: const Color(0xFF112039),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ───────────────────────────────────────────────────────────────────────────
  // Helper Section Header with Green Dot
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String tag, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            const SizedBox(width: 6),
            Text(
              tag,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Profile Photo Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProfilePhotoCard(String initials) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar box
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: _isUploadingPhoto
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFC9A84C)),
                        ),
                      )
                    : (_profile.photoUrl != null && _profile.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: ZabiraNetworkImage(imageUrl: _profile.photoUrl!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                            ),
                          )),
              ),
              const SizedBox(width: 16),

              // Info & Upload button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile photo',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'JPG, PNG, or WebP · max 5MB · cropped to a square before upload',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isUploadingPhoto ? null : _showImageSourceModal,
                      icon: _isUploadingPhoto
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(LucideIcons.camera, size: 14, color: Colors.white),
                      label: Text(
                        _isUploadingPhoto ? 'Uploading...' : 'Upload',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF112039),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Drag & drop box
          InkWell(
            onTap: _isUploadingPhoto ? null : _showImageSourceModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.cloudUpload, size: 28, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to choose an image',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                  ),
                  Text(
                    'Choose from gallery or take a photo',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Verified Identity Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildVerifiedIdentityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Email
          _buildReadOnlyField(
            label: 'Email address',
            value: _profile.email.isNotEmpty ? _profile.email : 'qaanitumar771@gmail.com',
            badgeText: 'Verified',
            badgeColor: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 14),

          // Phone
          _buildReadOnlyField(
            label: 'Mobile / WhatsApp',
            value: _profile.phone.isNotEmpty ? _profile.phone : '9579746616',
            badgeText: 'Verified',
            badgeColor: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 14),

          // Student ID & Reg date
          Row(
            children: [
              Expanded(
                child: _buildReadOnlyField(
                  label: 'Student ID',
                  value: _profile.studentId.isNotEmpty ? _profile.studentId : 'ZAB-STU-000044',
                  badgeText: 'Read only',
                  badgeColor: const Color(0xFF10B981),
                  badgeIcon: LucideIcons.lock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReadOnlyField(
                  label: 'Registration date',
                  value: _profile.registrationDate.isNotEmpty ? _profile.registrationDate : '11/08/2026',
                  badgeText: 'Read only',
                  badgeColor: const Color(0xFF10B981),
                  badgeIcon: LucideIcons.lock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Personal Information Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPersonalInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'First name *',
                  controller: _firstNameController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInputField(
                  label: 'Last name *',
                  controller: _lastNameController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInputField(
            label: 'Display name',
            controller: _displayNameController,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Date of birth',
                  controller: _dobController,
                  suffixIcon: LucideIcons.calendar,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Gender',
                  value: _gender,
                  items: const ['Male', 'Female', 'Other'],
                  onChanged: (v) => setState(() => _gender = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Location Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputField(label: 'Country', controller: _countryController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'State', controller: _stateController)),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _buildInputField(label: 'City', controller: _cityController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'Postal code', controller: _postalController)),
            ],
          ),
          const SizedBox(height: 14),

          _buildInputField(
            label: 'Address',
            controller: _addressController,
            maxLines: 3,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Preferred language',
                  value: _preferredLanguage,
                  items: const ['English', 'Arabic', 'Urdu', 'Hindi'],
                  onChanged: (v) => setState(() => _preferredLanguage = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Time zone',
                  value: _timeZone,
                  items: const ['Asia/Kolkata', 'UTC', 'Asia/Dubai', 'America/New_York'],
                  onChanged: (v) => setState(() => _timeZone = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Education & Work Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEducationWorkCard() {
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
              Expanded(child: _buildInputField(label: 'Education qualification', controller: _qualificationController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'Occupation', controller: _occupationController)),
            ],
          ),
          const SizedBox(height: 14),

          _buildInputField(label: 'Institution / Organization', controller: _institutionController),
          const SizedBox(height: 14),

          _buildInputField(
            label: 'Biography / About me',
            controller: _bioController,
            maxLines: 4,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('0/2000', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 6. Emergency & Guardian Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmergencyGuardianCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputField(label: 'Emergency contact name', controller: _emergencyNameController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'Emergency contact number', controller: _emergencyPhoneController)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildInputField(label: 'Parent / Guardian name', controller: _parentNameController)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'Parent / Guardian contact', controller: _parentPhoneController)),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 7. Social Links Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSocialLinksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInputField(label: 'Website', controller: _websiteController, hint: 'https://')),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'LinkedIn', controller: _linkedinController, hint: 'https://')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildInputField(label: 'X / Twitter', controller: _twitterController, hint: 'https://')),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(label: 'Instagram', controller: _instagramController, hint: 'https://')),
            ],
          ),
          const SizedBox(height: 14),
          _buildInputField(label: 'YouTube', controller: _youtubeController, hint: 'https://'),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 8. Notification Preferences Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildNotificationPreferencesCard() {
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
            subtitle: 'Sent when WhatsApp messaging is configured for the academy.',
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
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Course updates',
            value: _courseNotifs,
            onChanged: (v) => setState(() => _courseNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Payment updates',
            value: _paymentNotifs,
            onChanged: (v) => setState(() => _paymentNotifs = v),
          ),
          _buildDivider(),
          _buildToggleRow(
            title: 'Certificate alerts',
            value: _certNotifs,
            onChanged: (v) => setState(() => _certNotifs = v),
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

  // ───────────────────────────────────────────────────────────────────────────
  // Form Field Helpers
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required String badgeText,
    required Color badgeColor,
    IconData? badgeIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badgeIcon != null) ...[
                  Icon(badgeIcon, size: 10, color: badgeColor),
                  const SizedBox(width: 3),
                ],
                Text(
                  badgeText,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569)),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    IconData? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF94A3B8)),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 16, color: const Color(0xFF64748B)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC9A84C), width: 1.5),
            ),
          ),
        ),
      ],
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
