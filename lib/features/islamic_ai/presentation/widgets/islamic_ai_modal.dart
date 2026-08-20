import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/islamic_ai_controller.dart';

/// Islamic AI Voice Assistant Modal
///
/// Features:
/// - Dark navy & Islamic gold color palette (#092540, #DC8C1A, #0A1628)
/// - Backdrop blur glassmorphic container
/// - Spoken ElevenLabs greeting on open
/// - Direct mic tap-to-send (no auto-silence cutoff)
/// - Automatic playback of answers with animated glowing visualizers
class IslamicAiModal extends StatefulWidget {
  const IslamicAiModal({super.key});

  /// Displays the Islamic AI Modal as a dialog with smooth scale and fade animations.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Islamic AI Assistant',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) => const IslamicAiModal(),
      transitionBuilder: (context, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<IslamicAiModal> createState() => _IslamicAiModalState();
}

class _IslamicAiModalState extends State<IslamicAiModal>
    with SingleTickerProviderStateMixin {
  late final IslamicAiController _aiController;
  late final AnimationController _pulseAnimController;
  late final Animation<double> _pulseScale;
  late final Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _aiController = IslamicAiController();

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    _glowOpacity = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    // Auto-fetch greeting and start spoken assistant flow on presentation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      final name = auth.isAuthenticated ? auth.user?.displayName : null;
      _aiController.startGreetingAndFlow(name);
    });
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  String _buildGreeting(BuildContext context) {
    final auth = context.read<AuthController>();
    final user = auth.user;
    final name = user?.displayName.trim();

    if (auth.isAuthenticated && name != null && name.isNotEmpty) {
      final firstName = name.split(' ').first;
      return 'Assalamu Alaikum $firstName,\nAap Islam ke related kya puchna chahoge?';
    }

    return 'Assalamu Alaikum,\nAap Islam ke related kya puchna chahoge?';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final fallbackGreeting = _buildGreeting(context);

    return ChangeNotifierProvider<IslamicAiController>.value(
      value: _aiController,
      child: Consumer<IslamicAiController>(
        builder: (context, controller, _) {
          final displayGreeting = controller.greetingText ?? fallbackGreeting;

          return Center(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: mediaQuery.padding.top + 24,
              ),
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC8C1A).withValues(alpha: 0.18),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0D253E),
                          Color(0xFF091B2F),
                          Color(0xFF061424),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFDC8C1A).withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Top Bar with Title and Close Button ───────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFDC8C1A).withValues(alpha: 0.18),
                                      border: Border.all(
                                        color: const Color(0xFFDC8C1A).withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      color: Color(0xFFDC8C1A),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Islamic AI Assistant',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 20,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // ── Spoken Greeting Text ──────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: controller.isGreeting
                                    ? const Color(0xFFDC8C1A).withValues(alpha: 0.4)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              displayGreeting,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFE2E8F0),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // ── Central Dynamic Visualizer / AI Orb ───────────
                          _buildAIVisualizer(controller),
                          const SizedBox(height: 16),

                          // ── Status Indicator ──────────────────────────────
                          _buildStatusIndicator(controller),
                          const SizedBox(height: 18),

                          // ── Transcription & Answer Content (Scrollable) ───
                          if (controller.transcription != null ||
                              controller.answer != null ||
                              controller.errorMessage != null)
                            Flexible(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (controller.transcription != null &&
                                        controller.transcription!.isNotEmpty) ...[
                                      Text(
                                        'You asked:',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFDC8C1A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '"${controller.transcription}"',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (controller.answer != null &&
                                        controller.answer!.isNotEmpty) ...[
                                      Text(
                                        'Zabira Islamic AI:',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFDC8C1A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF092540).withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFDC8C1A).withValues(alpha: 0.25),
                                          ),
                                        ),
                                        child: Text(
                                          controller.answer!,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (controller.hasError) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.redAccent.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                controller.errorMessage ?? 'An error occurred.',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFFFFB4B4),
                                                  fontSize: 12.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // ── Quick Controls (Replay / Ask Again) ───────────
                          _buildQuickControls(controller),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIVisualizer(IslamicAiController controller) {
    if (controller.isGreeting) {
      return AnimatedBuilder(
        animation: _pulseAnimController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86 * _pulseScale.value,
                height: 86 * _pulseScale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDC8C1A).withValues(alpha: 0.2 * _glowOpacity.value),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.startListening();
                },
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFDC8C1A),
                        Color(0xFFB5700E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFDC8C1A),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (controller.isListening) {
      return AnimatedBuilder(
        animation: _pulseAnimController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer golden glowing aura
              Container(
                width: 92 * _pulseScale.value,
                height: 92 * _pulseScale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFDC8C1A).withValues(alpha: 0.22 * _glowOpacity.value),
                ),
              ),
              // Inner glowing ring
              Container(
                width: 76 * _pulseScale.value,
                height: 76 * _pulseScale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDC8C1A).withValues(alpha: 0.7 * _glowOpacity.value),
                    width: 2.2,
                  ),
                ),
              ),
              // Center microphone button — acts as STOP + SEND
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  controller.stopListeningAndSend();
                },
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFDC8C1A),
                        Color(0xFFB5700E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFDC8C1A),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else if (controller.isProcessing) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC8C1A)),
              backgroundColor: const Color(0xFFDC8C1A).withValues(alpha: 0.2),
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF092540),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome,
                color: Color(0xFFDC8C1A),
                size: 24,
              ),
            ),
          ),
        ],
      );
    } else if (controller.isSpeaking) {
      return AnimatedBuilder(
        animation: _pulseAnimController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 88 * _pulseScale.value,
                height: 88 * _pulseScale.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.22 * _glowOpacity.value),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.stopPlayback();
                },
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF10B981),
                        Color(0xFF059669),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Idle or error state
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          controller.startListening();
        },
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF092540),
            border: Border.all(
              color: const Color(0xFFDC8C1A),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC8C1A).withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.mic_none_rounded,
              color: Color(0xFFDC8C1A),
              size: 28,
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStatusIndicator(IslamicAiController controller) {
    String text;
    Color color;

    switch (controller.state) {
      case IslamicAiState.greeting:
        text = '🔊 Greeting... (Tap to skip)';
        color = const Color(0xFFFDE68A);
        break;
      case IslamicAiState.listening:
        text = '🎙️ Listening... (Tap mic when done)';
        color = const Color(0xFFDC8C1A);
        break;
      case IslamicAiState.processing:
        text = '✨ Thinking & consulting knowledge...';
        color = const Color(0xFF93C5FD);
        break;
      case IslamicAiState.speaking:
        text = '🔊 AI Speaking... (Tap to stop)';
        color = const Color(0xFF34D399);
        break;
      case IslamicAiState.error:
        text = '⚠️ Tap microphone to try again';
        color = const Color(0xFFFCA5A5);
        break;
      case IslamicAiState.idle:
        text = 'Tap microphone to ask a question';
        color = Colors.white70;
        break;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildQuickControls(IslamicAiController controller) {
    if (controller.isIdle && controller.answer != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                controller.replayAnswerAudio();
              },
              icon: const Icon(Icons.replay_rounded, size: 16),
              label: const Text('Replay Voice'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC8C1A),
                side: const BorderSide(color: Color(0xFFDC8C1A), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                controller.startListening();
              },
              icon: const Icon(Icons.mic_rounded, size: 16),
              label: const Text('Ask Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC8C1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
