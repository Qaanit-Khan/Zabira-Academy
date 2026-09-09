import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/courses/presentation/controllers/wishlist_controller.dart';
import '../../features/store/presentation/controllers/cart_controller.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/presentation/widgets/auth_bottom_sheet.dart';

/// Modal dialogs and bottom sheets for auxiliary navigation links.
abstract final class ZabiraMenuModals {
  static const Color brandGold = Color(0xFFC9A84C);
  static const Color brandNavy = Color(0xFF112039);

  /// Show Wishlist Sheet with real data
  static void showWishlist(BuildContext context) {
    _showModalSheet(
      context,
      title: 'My Wishlist',
      icon: Icons.favorite_rounded,
      iconColor: brandGold,
      child: Consumer<WishlistController>(
        builder: (context, wishlist, _) {
          if (wishlist.isEmpty) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 52, color: brandGold),
                      const SizedBox(height: 12),
                      Text(
                        'Your Wishlist is Empty',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: brandNavy),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Save your favorite courses, books, and Islamic resources to access them anytime.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '${wishlist.count} Saved Items',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wishlist.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = wishlist.items[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: brandNavy.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: brandNavy,
                            child: item.resolvedImage != null && item.resolvedImage!.isNotEmpty
                                ? Image.network(
                                    item.resolvedImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(Icons.auto_stories_rounded, color: brandGold, size: 22),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.auto_stories_rounded, color: brandGold, size: 22),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: brandNavy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '₹${item.price.toInt()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: brandGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Add to Cart
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: brandNavy, size: 19),
                          tooltip: 'Add to Cart',
                          onPressed: () {
                            final auth = context.read<AuthController>();
                            if (!auth.isAuthenticated) {
                              Navigator.pop(context);
                              showAuthBottomSheet(context);
                              return;
                            }
                            final itemPayload = <String, dynamic>{
                              'quantity': '1',
                              'price': item.price,
                              'title': item.title,
                              'name': item.title,
                              'image': item.imageUrl,
                            };
                            if (item.type == 'store') {
                              itemPayload['product_id'] = item.id;
                              itemPayload['store_product_id'] = item.id;
                              itemPayload['product_type'] = 'product';
                            } else if (item.type == 'book') {
                              itemPayload['book_id'] = item.id;
                              itemPayload['product_type'] = 'book';
                            } else {
                              itemPayload['course_id'] = item.id;
                              itemPayload['product_type'] = 'course';
                            }

                            context.read<CartController>().addItem(
                              itemData: itemPayload,
                              token: auth.currentToken,
                            );
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added "${item.title}" to cart', style: GoogleFonts.outfit(color: Colors.white)),
                                backgroundColor: brandNavy,
                                duration: const Duration(milliseconds: 1800),
                              ),
                            );
                          },
                        ),
                        // Remove from Wishlist
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded, color: Color(0xFFEF4444), size: 20),
                          tooltip: 'Remove from Wishlist',
                          onPressed: () {
                            wishlist.removeItem(item.id, type: item.type);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  /// Show Donate Sheet
  static void showDonate(BuildContext context) {
    _showModalSheet(
      context,
      title: 'Support Zabira Academy',
      icon: Icons.volunteer_activism_rounded,
      iconColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Islamic Education & Scholarships',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Your contributions help underprivileged students access authentic Islamic education, free trial classes, and Quran learning resources worldwide.',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _donationChip(context, '\$25', 'Sponsor a Book'),
              const SizedBox(width: 8),
              _donationChip(context, '\$50', '1 Mo. Tuition'),
              const SizedBox(width: 8),
              _donationChip(context, '\$150', 'Full Term'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Online donation gateway will connect to your account.'),
                    backgroundColor: AppColors.navyDark,
                  ),
                );
              },
              icon: const Icon(Icons.favorite_rounded, color: AppColors.navyDark, size: 18),
              label: Text('Donate Now', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Widget _donationChip(BuildContext context, String amount, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(amount, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyDark)),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Show About Academy Sheet
  static void showAboutAcademy(BuildContext context) {
    _showModalSheet(
      context,
      title: 'About Zabira Academy',
      icon: Icons.account_balance_rounded,
      iconColor: AppColors.navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empowering the Ummah with Authentic Knowledge',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Zabira Academy is a premier global Islamic online education platform offering structured courses in Quran recitation, Tajweed, Islamic Studies, Arabic language, and youth character development.',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 14),
          _featureRow(Icons.verified_user_outlined, 'Certified Instructors & Scholars'),
          const SizedBox(height: 8),
          _featureRow(Icons.laptop_chromebook_rounded, 'Live 1-on-1 & Group Interactive Sessions'),
          const SizedBox(height: 8),
          _featureRow(Icons.auto_stories_outlined, 'Comprehensive Digital Islamic Library & Store'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show Contact Us Sheet
  static void showContactUs(BuildContext context) {
    _showModalSheet(
      context,
      title: 'Contact Us',
      icon: Icons.mail_outline_rounded,
      iconColor: AppColors.navyDark,
      child: Column(
        children: [
          _contactTile(Icons.email_outlined, 'Email Support', 'support@zabira.academy'),
          const SizedBox(height: 10),
          _contactTile(Icons.phone_outlined, 'Direct Helpline', '+44 20 7946 0912'),
          const SizedBox(height: 10),
          _contactTile(Icons.access_time_rounded, 'Working Hours', 'Mon - Sat: 8:00 AM - 10:00 PM (GMT)'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show Support & Help Center Sheet
  static void showHelpCenter(BuildContext context) {
    _showModalSheet(
      context,
      title: 'Support & Help Center',
      icon: Icons.help_outline_rounded,
      iconColor: AppColors.navyDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How can we assist your learning journey today?',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navyDark),
          ),
          const SizedBox(height: 12),
          _faqItem('How do I book a Free Trial Class?', 'Select any course and tap "Book Free Trial" to schedule a 1-on-1 evaluation with our certified teachers.'),
          const SizedBox(height: 10),
          _faqItem('Are certificates internationally recognized?', 'Yes, course completion certificates from Zabira Academy include verifiable credential IDs.'),
          const SizedBox(height: 10),
          _faqItem('What is the refund & cancellation policy?', 'We offer a 100% money-back guarantee within the first 14 days if you are not completely satisfied.'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show FAQs Sheet
  static void showFAQs(BuildContext context) {
    showHelpCenter(context);
  }

  /// Show Certificates Sheet
  static void showCertificates(BuildContext context) {
    _showModalSheet(
      context,
      title: 'My Certificates',
      icon: Icons.workspace_premium_outlined,
      iconColor: AppColors.gold,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(Icons.military_tech_outlined, size: 48, color: AppColors.gold),
                const SizedBox(height: 12),
                Text(
                  'No Certificates Yet',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete all modules and assessments in enrolled courses to earn verifiable official certificates.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show Settings Sheet
  static void showSettings(BuildContext context) {
    _showModalSheet(
      context,
      title: 'App Settings',
      icon: Icons.settings_outlined,
      iconColor: AppColors.navyDark,
      child: Column(
        children: [
          _settingSwitchTile(Icons.notifications_outlined, 'Push Notifications', 'Class reminders and new lesson alerts', true),
          const SizedBox(height: 8),
          _settingSwitchTile(Icons.audiotrack_outlined, 'Audio Background Playback', 'Continue Nasheed & lectures when screen is locked', true),
          const SizedBox(height: 8),
          _settingSwitchTile(Icons.language_rounded, 'Language: English (US)', 'Switch display language', false, isToggle: false),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show Gallery Sheet
  static void showGallery(BuildContext context) {
    _showModalSheet(
      context,
      title: 'Academy Gallery',
      icon: Icons.photo_library_outlined,
      iconColor: AppColors.navyDark,
      child: Column(
        children: [
          Text(
            'Moments from our global student graduations, Quran competitions, and youth seminars.',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/home/hero/home_banner.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/branding/hero_card.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show Blog & Articles Sheet
  static void showBlog(BuildContext context) {
    _showModalSheet(
      context,
      title: 'Articles & Insights',
      icon: Icons.article_outlined,
      iconColor: AppColors.navyDark,
      child: Column(
        children: [
          _articleItem(
            'The Beauty of Tajweed: Perfecting Quranic Pronunciation',
            'Learn why proper articulation and rhythm transform recitation.',
            '5 min read',
          ),
          const SizedBox(height: 10),
          _articleItem(
            'Teaching Children Islamic Values in the Digital Age',
            'Practical tips for parents navigating technology and character building.',
            '4 min read',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Show Join Academy / Careers Sheet
  static void showJoinAcademy(BuildContext context) {
    _showModalSheet(
      context,
      title: 'Join Zabira Academy',
      icon: Icons.people_outline_rounded,
      iconColor: AppColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Become a Teacher or Ambassador',
            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          ),
          const SizedBox(height: 6),
          Text(
            'We are always seeking certified Quran teachers, Islamic scholars, and passionate educators to join our international teaching faculty.',
            style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B), height: 1.45),
          ),
          const SizedBox(height: 16),
          _featureRow(Icons.check_circle_outline_rounded, 'Flexible online teaching hours'),
          const SizedBox(height: 6),
          _featureRow(Icons.check_circle_outline_rounded, 'Competitive compensation & benefits'),
          const SizedBox(height: 6),
          _featureRow(Icons.check_circle_outline_rounded, 'Global community of learners'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please send your resume to careers@zabira.academy'),
                    backgroundColor: AppColors.navyDark,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Apply to Teach', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────────

  static void _showModalSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
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
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  static Widget _contactTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navyDark, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _faqItem(String question, String answer) {
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
          Text(question, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
          const SizedBox(height: 4),
          Text(answer, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
        ],
      ),
    );
  }

  static Widget _settingSwitchTile(IconData icon, String title, String subtitle, bool value, {bool isToggle = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navyDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
                Text(subtitle, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          if (isToggle)
            Switch(
              value: value,
              activeThumbColor: AppColors.gold,
              onChanged: (_) {},
            )
          else
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  static Widget _articleItem(String title, String summary, String readTime) {
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
          Text(title, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
          const SizedBox(height: 4),
          Text(summary, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 6),
          Text(readTime, style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.gold)),
        ],
      ),
    );
  }
}
