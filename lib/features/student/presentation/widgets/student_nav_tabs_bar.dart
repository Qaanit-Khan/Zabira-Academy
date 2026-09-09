import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TabItemData {
  const TabItemData({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

const List<TabItemData> kProfileTabs = [
  TabItemData(label: 'Dashboard', icon: LucideIcons.layoutDashboard, route: '/student'),
  TabItemData(label: 'My Courses', icon: LucideIcons.bookOpen, route: '/student/courses'),
  TabItemData(label: 'My Books', icon: LucideIcons.library, route: '/student/my-books'),
  TabItemData(label: 'Continue Learning', icon: LucideIcons.playCircle, route: '/student/continue'),
  TabItemData(label: 'Certificates', icon: LucideIcons.award, route: '/student/certificates'),
  TabItemData(label: 'My Profile', icon: LucideIcons.user, route: '/student/profile'),
  TabItemData(label: 'My Orders', icon: LucideIcons.shoppingBag, route: '/student/orders'),
  TabItemData(label: 'Wishlist', icon: LucideIcons.heart, route: '/student/wishlist'),
  TabItemData(label: 'Notifications', icon: LucideIcons.bell, route: '/student/notifications'),
  TabItemData(label: 'Help Center', icon: LucideIcons.helpCircle, route: '/student/help'),
  TabItemData(label: 'Settings', icon: LucideIcons.settings, route: '/student/settings'),
];

/// Horizontal Nav Tabs Bar matching the exact Reference Design
class StudentNavTabsBar extends StatefulWidget {
  const StudentNavTabsBar({
    super.key,
    required this.selectedIndex,
    this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  State<StudentNavTabsBar> createState() => _StudentNavTabsBarState();
}

class _StudentNavTabsBarState extends State<StudentNavTabsBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void didUpdateWidget(covariant StudentNavTabsBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final targetOffset = (widget.selectedIndex * 110.0) - 40.0;
    _scrollController.animateTo(
      targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: List.generate(kProfileTabs.length, (index) {
            final tab = kProfileTabs[index];
            final isSelected = index == widget.selectedIndex;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (widget.onTabSelected != null) {
                      widget.onTabSelected!(index);
                    } else {
                      context.go(tab.route);
                    }
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF112039) : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF112039) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 15,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tab.label,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
