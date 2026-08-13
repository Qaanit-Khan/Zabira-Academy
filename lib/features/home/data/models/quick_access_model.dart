/// Identifies which custom-painted icon to render for a Quick Access item.
enum QaIconType {
  courses,
  kidsPortal,
  library,
  nasheed,
  store,
  events,
  scholarship,
  media,
}

/// Data model for a single Quick Access grid item.
class QuickAccessModel {
  const QuickAccessModel({
    required this.label,
    required this.route,
    required this.semanticLabel,
    this.iconPath,
    this.imagePath,
    this.iconType,
  });

  final String label;

  /// Placeholder route — wire to GoRouter push when page is ready.
  final String route;

  /// Accessibility semantic label for screen readers.
  final String semanticLabel;

  /// Local SVG asset path for category icon (e.g. 'assets/images/home/icons/lesson.svg')
  final String? iconPath;

  /// Optional local asset path for PNG icon.
  final String? imagePath;

  /// Optional enum type for custom-painted fallback icon.
  final QaIconType? iconType;
}
