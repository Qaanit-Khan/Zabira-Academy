import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../controllers/kids_controller.dart';
import '../../data/models/kids_models.dart';

/// Zabira Academy — Interactive Kids Islamic Game (Memory Match & Duas)
class KidsGamePage extends StatefulWidget {
  const KidsGamePage({
    super.key,
    required this.gameId,
    this.game,
  });

  final int gameId;
  final KidsGameItem? game;

  @override
  State<KidsGamePage> createState() => _KidsGamePageState();
}

class _KidsGamePageState extends State<KidsGamePage> {
  late List<_CardItem> _cards;
  int? _firstSelectedIndex;
  int? _secondSelectedIndex;
  bool _isChecking = false;
  int _moves = 0;
  int _matchedPairs = 0;
  bool _isGameOver = false;

  final List<String> _gameIcons = ['📖', '🤲', '🕌', '🌙', '⭐', '🕊️'];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    final list = <_CardItem>[];
    for (int i = 0; i < _gameIcons.length; i++) {
      list.add(_CardItem(id: i, emoji: _gameIcons[i]));
      list.add(_CardItem(id: i, emoji: _gameIcons[i]));
    }
    list.shuffle();
    _cards = list;
    _moves = 0;
    _matchedPairs = 0;
    _firstSelectedIndex = null;
    _secondSelectedIndex = null;
    _isChecking = false;
    _isGameOver = false;

    final token = context.read<AuthController>().currentToken;
    context.read<KidsController>().startPlayGame(widget.gameId, token: token);
  }

  void _onCardTapped(int index) {
    if (_isChecking || _cards[index].isFlipped || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFlipped = true;
    });

    if (_firstSelectedIndex == null) {
      _firstSelectedIndex = index;
    } else {
      _secondSelectedIndex = index;
      _moves++;
      _isChecking = true;

      final first = _cards[_firstSelectedIndex!];
      final second = _cards[_secondSelectedIndex!];

      if (first.id == second.id) {
        // Matched!
        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _matchedPairs++;
          _firstSelectedIndex = null;
          _secondSelectedIndex = null;
          _isChecking = false;
        });

        if (_matchedPairs == _gameIcons.length) {
          setState(() => _isGameOver = true);
          final token = context.read<AuthController>().currentToken;
          context.read<KidsController>().submitGameScore('attempt_${widget.gameId}', 100, token: token);
        }
      } else {
        // Not matched — flip back after short delay
        Timer(const Duration(milliseconds: 750), () {
          if (mounted) {
            setState(() {
              first.isFlipped = false;
              second.isFlipped = false;
              _firstSelectedIndex = null;
              _secondSelectedIndex = null;
              _isChecking = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.game?.title ?? 'Memory Match — Islamic Discovery';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Column(
          children: [
            // Score & Moves Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Moves: $_moves', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
                  Text('Matched: $_matchedPairs / ${_gameIcons.length}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Game Board
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  final card = _cards[index];
                  final isRevealed = card.isFlipped || card.isMatched;

                  return GestureDetector(
                    onTap: () => _onCardTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: isRevealed ? (card.isMatched ? const Color(0xFF10B981) : AppColors.navyDark) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRevealed ? Colors.transparent : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isRevealed ? card.emoji : '🌟',
                          style: TextStyle(fontSize: isRevealed ? 36 : 28),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isGameOver) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Column(
                  children: [
                    Text('🎉 Excellent! You matched all pairs in $_moves moves!', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navyDark)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _initGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navyDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Play Again'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CardItem {
  _CardItem({
    required this.id,
    required this.emoji,
  });

  final int id;
  final String emoji;
  bool isFlipped = false;
  bool isMatched = false;
}
