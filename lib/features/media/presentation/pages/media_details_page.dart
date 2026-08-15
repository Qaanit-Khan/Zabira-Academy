import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/loaders/zabira_loader.dart';
import '../../../../shared/widgets/zabira_error_state.dart';
import '../../../../shared/widgets/zabira_network_image.dart';
import '../../data/models/media_item_model.dart';
import '../../data/services/media_api_service.dart';

class MediaDetailsPage extends StatefulWidget {
  const MediaDetailsPage({super.key, required this.mediaId, this.initialItem});

  final int mediaId;
  final MediaItemModel? initialItem;

  @override
  State<MediaDetailsPage> createState() => _MediaDetailsPageState();
}

class _MediaDetailsPageState extends State<MediaDetailsPage> {
  final MediaApiService _service = MediaApiService();
  MediaItemModel? _item;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _item = widget.initialItem;
    if (_item == null) {
      _fetchDetails();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await _service.getMediaDetails(id: widget.mediaId);
      setState(() {
        _item = item;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load media details.';
      });
    }
  }

  Future<void> _launchVideoUrl(String rawUrl) async {
    if (rawUrl.isEmpty) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open video URL: $rawUrl')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.navyDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Media Player',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: ZabiraLoader(size: 40));
    }

    if (_errorMessage != null || _item == null) {
      return ZabiraErrorState(
        title: 'Unable to Load Media',
        message: _errorMessage ?? 'Media item not found.',
        onRetry: _fetchDetails,
      );
    }

    final item = _item!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Video Preview / Play Header ─────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ZabiraNetworkImage(
                  imageUrl: item.resolvedThumbnail,
                  fit: BoxFit.cover,
                ),
                Container(
                  color: Colors.black.withAlpha(80),
                ),
                Center(
                  child: GestureDetector(
                    onTap: () => _launchVideoUrl(item.playUrl),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withAlpha(140),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF071B36),
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),
                if (item.duration != null && item.duration!.isNotEmpty)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(190),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.duration!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Video Details ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.categoryName != null && item.categoryName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.categoryName!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                Text(
                  item.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      'Zabira Academy Official',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                    if (item.language.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(width: 8),
                      Text(item.language, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Play on YouTube / Watch Stream Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchVideoUrl(item.playUrl),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                    label: const Text('Watch Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (item.description.isNotEmpty) ...[
                  Text(
                    'About this video',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
