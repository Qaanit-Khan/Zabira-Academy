import 'package:flutter/material.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';

export '../../../../shared/widgets/zabira_bottom_nav.dart';

/// Legacy alias for [ZabiraBottomNav] to ensure complete backwards compatibility
/// across existing screens while adopting the exact new docked footer design.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, this.selectedIndex = 2, this.onItemTapped});

  final int selectedIndex;
  final ValueChanged<int>? onItemTapped;

  @override
  Widget build(BuildContext context) {
    return ZabiraBottomNav(
      selectedIndex: selectedIndex,
      onItemTapped: onItemTapped,
    );
  }
}
