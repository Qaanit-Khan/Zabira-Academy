import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/router.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../../data/models/course_api_model.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/services/progress_api_service.dart';
import '../controllers/enrollment_controller.dart';

/// Zabira Academy — Native Mobile Course Learning & Lesson Player Screen
///
/// Designed exclusively for mobile screens adhering to the Zabira design system:
/// - Dark Navy (#081D3A), Gold (#D19A42), Clean surfaces
/// - Real Video Player with controls, buffering, and error handling
/// - Expandable Curriculum Modules with Lesson switching
/// - Real-time Progress Tracking and Backend Completion Updates
class CourseLearningPage extends StatefulWidget {
  const CourseLearningPage({
    super.key,
    required this.courseId,
    this.initialLessonId,
  });

  final int courseId;
  final int? initialLessonId;

  @override
  State<CourseLearningPage> createState() => _CourseLearningPageState();
}

class _CourseLearningPageState extends State<CourseLearningPage> {
  final CourseRepository _repository = CourseRepository();
  final ProgressApiService _progressService = ProgressApiService();

  CourseApiModel? _course;
  bool _isLoading = true;
  String? _errorMessage;

  // Active Lesson State
  CourseCurriculumSection? _activeSection;
  CourseLessonItem? _activeLesson;
  int _activeSectionIndex = 0;
  int _activeLessonIndex = 0;

  // Completed Lessons tracking
  final Set<int> _completedLessonIds = {};
  double _courseProgressPercent = 0.0;
  bool _isUpdatingProgress = false;

  // Video Player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadCourseAndProgress();
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;
    _isVideoError = false;
  }

  void _videoListener() {
    if (_videoController == null) return;
    final isPlaying = _videoController!.value.isPlaying;
    if (isPlaying != _isPlaying) {
      if (mounted) {
        setState(() => _isPlaying = isPlaying);
      }
    }
  }

  Future<void> _loadCourseAndProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();

    try {
      final results = await Future.wait([
        _repository.getCourseDetails(widget.courseId),
        _progressService.getCourseProgress(courseId: widget.courseId, token: auth.currentToken),
      ]);

      final course = results[0] as CourseApiModel;
      final progressData = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      _course = course;

      // Parse progress data
      if (progressData['success'] == true && progressData['data'] != null) {
        final data = progressData['data'] is Map<String, dynamic> ? progressData['data'] as Map<String, dynamic> : progressData;
        final rawCompleted = data['completed_lessons'] ?? data['completed_lesson_ids'] ?? [];
        if (rawCompleted is List) {
          for (final item in rawCompleted) {
            final id = int.tryParse(item.toString());
            if (id != null) _completedLessonIds.add(id);
          }
        }
        _courseProgressPercent = double.tryParse((data['progress_percent'] ?? data['progress'] ?? '0').toString()) ?? 0.0;
      }

      // Determine starting lesson
      _selectStartingLesson(widget.initialLessonId);

      setState(() => _isLoading = false);

      // Initialize video for starting lesson
      if (_activeLesson != null) {
        _initLessonMedia(_activeLesson!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        _isLoading = false;
      });
    }
  }

  void _selectStartingLesson(int? targetLessonId) {
    if (_course == null || _course!.curriculum.isEmpty) return;

    // 1. If targetLessonId passed, find it
    if (targetLessonId != null && targetLessonId > 0) {
      for (var sIdx = 0; sIdx < _course!.curriculum.length; sIdx++) {
        final sec = _course!.curriculum[sIdx];
        for (var lIdx = 0; lIdx < sec.lessons.length; lIdx++) {
          if (sec.lessons[lIdx].id == targetLessonId) {
            _activeSection = sec;
            _activeSectionIndex = sIdx;
            _activeLesson = sec.lessons[lIdx];
            _activeLessonIndex = lIdx;
            return;
          }
        }
      }
    }

    // 2. Find first uncompleted lesson
    for (var sIdx = 0; sIdx < _course!.curriculum.length; sIdx++) {
      final sec = _course!.curriculum[sIdx];
      for (var lIdx = 0; lIdx < sec.lessons.length; lIdx++) {
        if (!_completedLessonIds.contains(sec.lessons[lIdx].id)) {
          _activeSection = sec;
          _activeSectionIndex = sIdx;
          _activeLesson = sec.lessons[lIdx];
          _activeLessonIndex = lIdx;
          return;
        }
      }
    }

    // 3. Fallback to very first lesson
    if (_course!.curriculum.isNotEmpty && _course!.curriculum.first.lessons.isNotEmpty) {
      _activeSection = _course!.curriculum.first;
      _activeSectionIndex = 0;
      _activeLesson = _course!.curriculum.first.lessons.first;
      _activeLessonIndex = 0;
    }
  }

  Future<void> _initLessonMedia(CourseLessonItem lesson) async {
    _disposeVideoController();

    final videoUrl = lesson.videoUrl != null && lesson.videoUrl!.trim().isNotEmpty
        ? ApiConfig.resolveMediaUrl(lesson.videoUrl!)
        : null;

    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() {
        _isVideoInitialized = false;
        _isVideoError = false;
      });
      return;
    }

    try {
      final uri = Uri.parse(videoUrl);
      final controller = VideoPlayerController.networkUrl(uri);
      _videoController = controller;

      await controller.initialize();
      controller.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isVideoError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
          _isVideoError = true;
        });
      }
    }
  }

  void _switchLesson(CourseCurriculumSection section, int sectionIdx, CourseLessonItem lesson, int lessonIdx) {
    if (_activeLesson?.id == lesson.id) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeSection = section;
      _activeSectionIndex = sectionIdx;
      _activeLesson = lesson;
      _activeLessonIndex = lessonIdx;
    });
    _initLessonMedia(lesson);
  }

  Future<void> _toggleLessonCompletion() async {
    if (_activeLesson == null || _course == null) return;
    final auth = context.read<AuthController>();
    final enrollment = context.read<EnrollmentController>();

    final lessonId = _activeLesson!.id;
    final isAlreadyDone = _completedLessonIds.contains(lessonId);

    setState(() => _isUpdatingProgress = true);

    if (isAlreadyDone) {
      _completedLessonIds.remove(lessonId);
    } else {
      _completedLessonIds.add(lessonId);
    }

    // Calculate updated percent
    int totalLessons = 0;
    for (final sec in _course!.curriculum) {
      totalLessons += sec.lessons.length;
    }
    if (totalLessons > 0) {
      _courseProgressPercent = ((_completedLessonIds.length / totalLessons) * 100.0).clamp(0.0, 100.0);
    }

    // Update local controller state
    enrollment.updateCourseProgressLocal(
      courseId: _course!.id,
      progressPercent: _courseProgressPercent,
      completedLessonsCount: _completedLessonIds.length,
      lastLessonId: lessonId,
      lastLessonTitle: _activeLesson!.title,
    );

    // Call backend
    try {
      await _progressService.updateProgress(
        courseId: _course!.id,
        lessonId: lessonId,
        status: isAlreadyDone ? 'in_progress' : 'completed',
        progressPercent: _courseProgressPercent,
        token: auth.currentToken,
      );
    } catch (_) {}

    if (mounted) {
      setState(() => _isUpdatingProgress = false);
      if (!isAlreadyDone) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lesson marked as completed! (+${(100 / (totalLessons > 0 ? totalLessons : 1)).round()}%)'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
        _goToNextLesson();
      }
    }
  }

  void _goToNextLesson() {
    if (_course == null || _course!.curriculum.isEmpty) return;

    final currSec = _course!.curriculum[_activeSectionIndex];
    if (_activeLessonIndex + 1 < currSec.lessons.length) {
      // Next lesson in same section
      final nextLesson = currSec.lessons[_activeLessonIndex + 1];
      _switchLesson(currSec, _activeSectionIndex, nextLesson, _activeLessonIndex + 1);
    } else if (_activeSectionIndex + 1 < _course!.curriculum.length) {
      // First lesson in next section
      final nextSec = _course!.curriculum[_activeSectionIndex + 1];
      if (nextSec.lessons.isNotEmpty) {
        _switchLesson(nextSec, _activeSectionIndex + 1, nextSec.lessons.first, 0);
      }
    }
  }

  void _goToPreviousLesson() {
    if (_course == null || _course!.curriculum.isEmpty) return;

    if (_activeLessonIndex > 0) {
      final currSec = _course!.curriculum[_activeSectionIndex];
      final prevLesson = currSec.lessons[_activeLessonIndex - 1];
      _switchLesson(currSec, _activeSectionIndex, prevLesson, _activeLessonIndex - 1);
    } else if (_activeSectionIndex > 0) {
      final prevSec = _course!.curriculum[_activeSectionIndex - 1];
      if (prevSec.lessons.isNotEmpty) {
        _switchLesson(prevSec, _activeSectionIndex - 1, prevSec.lessons.last, prevSec.lessons.length - 1);
      }
    }
  }

  bool get _hasNextLesson {
    if (_course == null || _course!.curriculum.isEmpty) return false;
    final currSec = _course!.curriculum[_activeSectionIndex];
    return _activeLessonIndex + 1 < currSec.lessons.length || _activeSectionIndex + 1 < _course!.curriculum.length;
  }

  bool get _hasPreviousLesson {
    return _activeLessonIndex > 0 || _activeSectionIndex > 0;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF081D3A),
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _errorMessage != null || _course == null
                ? _buildError()
                : _buildLearningContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: [
        _buildAppBar(),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage ?? 'Course content currently unavailable.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadCourseAndProgress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.navyDark,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF081D3A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.myCourses);
              }
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course?.title ?? 'Course Learning',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (_activeSection != null)
                  Text(
                    _activeSection!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppColors.gold,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withAlpha(80)),
            ),
            child: Text(
              '${_courseProgressPercent.toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningContent() {
    return Column(
      children: [
        _buildAppBar(),

        // ── 1. Video / Media Player Container ──────────────────────────────
        _buildMediaPlayer(),

        // ── 2. Scrollable Lesson Body & Curriculum ─────────────────────────
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson Title & Meta
                  _buildLessonHeader(),

                  const SizedBox(height: 16),

                  // Action Buttons (Previous, Mark Complete, Next)
                  _buildLessonActionButtons(),

                  const SizedBox(height: 20),

                  // Overall Course Progress Bar
                  _buildProgressCard(),

                  const SizedBox(height: 24),

                  // Full Course Curriculum
                  _buildCurriculumAccordion(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPlayer() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoInitialized && _videoController != null)
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: VideoPlayer(_videoController!),
              )
            else
              // Thumbnail Poster / Fallback
              Stack(
                fit: StackFit.expand,
                children: [
                  if (_course?.fullHeroBannerUrl != null || _course?.fullThumbnailUrl != null)
                    Image.network(
                      _course?.fullHeroBannerUrl ?? _course?.fullThumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderPoster(),
                    )
                  else
                    _buildPlaceholderPoster(),
                  Container(color: Colors.black.withAlpha(140)),
                ],
              ),

            // Video Controls Overlay
            if (_isVideoInitialized && _videoController != null && _showControls)
              _buildVideoControlsOverlay(),

            // If video error / no video URL provided
            if (!_isVideoInitialized)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 1.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_arrow_rounded, color: AppColors.gold, size: 32),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _activeLesson?.title ?? 'Lesson Content',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isVideoError
                          ? 'Media stream initializing / self-paced reading'
                          : 'Interactive Lesson · Follow along below',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF081D3A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 48),
      ),
    );
  }

  Widget _buildVideoControlsOverlay() {
    final c = _videoController!;
    final position = c.value.position;
    final duration = c.value.duration;

    return Container(
      color: Colors.black.withAlpha(80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top controls (Mute / Unmute)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                  c.setVolume(_isMuted ? 0.0 : 1.0);
                });
              },
            ),
          ),

          // Center Play / Pause
          IconButton(
            iconSize: 48,
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              color: AppColors.gold,
            ),
            onPressed: () {
              if (_isPlaying) {
                c.pause();
              } else {
                c.play();
              }
            },
          ),

          // Bottom Bar (Progress + Time)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Text(
                  _formatDuration(position),
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      trackHeight: 3,
                      activeTrackColor: AppColors.gold,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: AppColors.gold,
                    ),
                    child: Slider(
                      value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                      max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                      onChanged: (val) {
                        c.seekTo(Duration(milliseconds: val.toInt()));
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(duration),
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildLessonHeader() {
    final isDone = _activeLesson != null && _completedLessonIds.contains(_activeLesson!.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFE8F5E9) : const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDone ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                      size: 13,
                      color: isDone ? const Color(0xFF16A34A) : AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDone ? 'Completed' : 'Lesson ${_activeLessonIndex + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDone ? const Color(0xFF16A34A) : const Color(0xFF926200),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_activeLesson?.duration != null)
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      _activeLesson!.duration!,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _activeLesson?.title ?? 'Select a Lesson',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDark,
              height: 1.25,
            ),
          ),
          if (_course?.instructorName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Taught by ${_course!.instructorName}',
              style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonActionButtons() {
    final isDone = _activeLesson != null && _completedLessonIds.contains(_activeLesson!.id);

    return Row(
      children: [
        // Previous Button
        IconButton.filledTonal(
          onPressed: _hasPreviousLesson ? _goToPreviousLesson : null,
          icon: const Icon(Icons.skip_previous_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: AppColors.navyDark,
          ),
          tooltip: 'Previous Lesson',
        ),
        const SizedBox(width: 8),

        // Mark as Complete Button
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isUpdatingProgress ? null : _toggleLessonCompletion,
              icon: Icon(
                isDone ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                _isUpdatingProgress
                    ? 'Saving...'
                    : (isDone ? 'Completed' : 'Mark as Complete'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? const Color(0xFF10B981) : AppColors.navyDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                textStyle: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Next Button
        IconButton.filledTonal(
          onPressed: _hasNextLesson ? _goToNextLesson : null,
          icon: const Icon(Icons.skip_next_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: AppColors.navyDark,
          ),
          tooltip: 'Next Lesson',
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    int totalLessons = 0;
    if (_course != null) {
      for (final s in _course!.curriculum) {
        totalLessons += s.lessons.length;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Course Progress',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              Text(
                '${_completedLessonIds.length} of $totalLessons lessons (${_courseProgressPercent.toInt()}%)',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_courseProgressPercent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurriculumAccordion() {
    if (_course == null || _course!.curriculum.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.menu_book_rounded, color: Color(0xFF94A3B8), size: 36),
              const SizedBox(height: 8),
              Text(
                'Curriculum content is being prepared by our scholars.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Curriculum',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(_course!.curriculum.length, (sIdx) {
          final section = _course!.curriculum[sIdx];
          final isCurrentSection = _activeSectionIndex == sIdx;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrentSection ? AppColors.navyDark.withAlpha(60) : const Color(0xFFE2E8F0),
                width: isCurrentSection ? 1.5 : 1.0,
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: isCurrentSection || sIdx == 0,
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCurrentSection ? AppColors.navyDark : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${sIdx + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isCurrentSection ? AppColors.gold : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  section.title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                subtitle: Text(
                  '${section.lessons.length} Lessons',
                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                children: List.generate(section.lessons.length, (lIdx) {
                  final lesson = section.lessons[lIdx];
                  final isCurrentLesson = _activeLesson?.id == lesson.id;
                  final isDone = _completedLessonIds.contains(lesson.id);

                  return Container(
                    decoration: BoxDecoration(
                      color: isCurrentLesson ? const Color(0xFFFFF9E6) : Colors.transparent,
                      border: Border(top: BorderSide(color: const Color(0xFFF1F5F9))),
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: () => _switchLesson(section, sIdx, lesson, lIdx),
                      leading: Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : (isCurrentLesson ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded),
                        color: isDone
                            ? const Color(0xFF10B981)
                            : (isCurrentLesson ? AppColors.gold : const Color(0xFF94A3B8)),
                        size: 20,
                      ),
                      title: Text(
                        lesson.title,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: isCurrentLesson ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrentLesson ? AppColors.navyDark : const Color(0xFF334155),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (lesson.isPreview) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Preview',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (lesson.duration != null)
                            Text(
                              lesson.duration!,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        }),
      ],
    );
  }
}
