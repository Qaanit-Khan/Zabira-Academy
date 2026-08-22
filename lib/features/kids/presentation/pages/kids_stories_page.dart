import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/zabira_bottom_nav.dart';
import '../../data/models/kids_models.dart';
import '../controllers/kids_controller.dart';

class KidsStoriesPage extends StatefulWidget {
  const KidsStoriesPage({super.key});

  @override
  State<KidsStoriesPage> createState() => _KidsStoriesPageState();
}

class _KidsStoriesPageState extends State<KidsStoriesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kidsCtrl = context.watch<KidsController>();
    final allStories = kidsCtrl.stories;

    final query = _searchCtrl.text.trim().toLowerCase();
    final displayedStories = allStories.where((story) {
      if (query.isNotEmpty) {
        final title = story.title.toLowerCase();
        final desc = (story.shortDescription ?? story.description ?? '').toLowerCase();
        final prophet = (story.prophetName ?? '').toLowerCase();
        if (!title.contains(query) && !desc.contains(query) && !prophet.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      extendBody: true,
      bottomNavigationBar: const ZabiraBottomNav(selectedIndex: 1),
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Quran Stories for Kids',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.navyDark),
                decoration: InputDecoration(
                  hintText: 'Search stories, prophets, lessons...',
                  hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (displayedStories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 42, color: AppColors.gold),
                      const SizedBox(height: 12),
                      Text(
                        'No stories found',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try searching for another prophet or lesson.',
                        style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...displayedStories.map((story) {
                final coverUrl = story.resolvedCoverImage ?? story.resolvedThumbnail;

                return GestureDetector(
                  onTap: () => context.push('/kids/story/${story.id}?slug=${story.slug}', extra: story),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            color: AppColors.navyDark,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (coverUrl != null && coverUrl.isNotEmpty)
                                  Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => _buildFallbackCover(story),
                                  )
                                else
                                  _buildFallbackCover(story),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      story.readTimeLabel,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (story.prophetName != null && story.prophetName!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    story.prophetName!,
                                    style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF1D4ED8)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                story.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              if (story.shortDescription != null && story.shortDescription!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  story.shortDescription!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Text(
                                    'Read Story',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF2563EB)),
                                  const Spacer(),
                                  Text(
                                    '+20 XP',
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

            // Bottom clearance
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackCover(KidsStoryItem story) {
    return Container(
      color: const Color(0xFF0F2B48),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 36),
            const SizedBox(height: 6),
            Text(
              story.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
