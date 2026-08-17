import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/auth_controller.dart';
import '../../data/models/kids_models.dart';
import '../../data/services/kids_api_service.dart';

/// Zabira Academy — Interactive Kids Islamic Game Page
///
/// Dynamic game engine supporting all 8 backend game modes:
/// 1. Memory Match (Card flipping & pairing)
/// 2. Dua Match (Left-Right situation to dua connector)
/// 3. True or False (Fast-paced Islamic facts)
/// 4. Multiple Choice & Islamic Knowledge Round (Quiz challenges)
/// 5. Word Puzzle (Letter selection & vocabulary builder)
/// 6. Sort It Right (Halal vs Haram categorization)
/// 7. Prophet Timeline (Chronological order sequencing)
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
  final KidsApiService _api = KidsApiService();

  KidsGameItem? _game;
  bool _isLoading = true;
  String? _errorMessage;
  String? _attemptToken;
  DateTime? _startTime;

  // Game state
  bool _isGameOver = false;
  int _score = 0;
  int _maxScore = 100;
  int _timeTakenSeconds = 0;

  // 1. Memory Match State
  List<_MemoryCard> _memoryCards = [];
  int? _firstSelectedCard;
  int? _secondSelectedCard;
  bool _isMemoryChecking = false;
  int _memoryMoves = 0;

  // 2. Dua Match State
  List<Map<String, String>> _matchingPairs = [];
  String? _selectedLeft;
  String? _selectedRight;
  final Set<String> _matchedLefts = {};

  // 3. Quiz & True/False State
  List<Map<String, dynamic>> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool? _selectedTrueFalse;
  bool _hasAnsweredCurrent = false;

  // 4. Word Puzzle State
  List<Map<String, String>> _wordList = [];
  int _currentWordIndex = 0;
  List<String> _revealedLetters = [];
  final Set<String> _guessedLetters = {};

  // 5. Sort It Right State
  List<Map<String, dynamic>> _sortGroups = [];
  List<Map<String, dynamic>> _sortItems = [];
  int _currentSortItemIndex = 0;
  final Map<String, List<String>> _sortedBuckets = {};

  // 6. Prophet Timeline State
  List<String> _timelineTiles = [];
  int? _selectedTimelineTile;

  @override
  void initState() {
    super.initState();
    _loadGameAndStartSession();
  }

  Future<void> _loadGameAndStartSession() async {
    setState(() => _isLoading = true);

    KidsGameItem? item = widget.game;
    if (item == null || item.gameConfig == null) {
      item = await _api.getGameDetails(gameId: widget.gameId, slug: widget.game?.slug);
    }
    _game = item ?? widget.game;

    if (_game == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Game details could not be loaded from API.';
      });
      return;
    }

    if (_game!.gameConfig == null || _game!.gameConfig!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Game configuration is missing for this game.';
      });
      return;
    }

    if (!mounted) return;
    final token = context.read<AuthController>().currentToken;
    final playSession = await _api.startPlayGame(gameId: widget.gameId, token: token);
    _attemptToken = playSession['attempt_token']?.toString();
    if (_attemptToken == null || _attemptToken!.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to start game session. Missing attempt token from API.';
      });
      return;
    }
    _startTime = DateTime.now();

    _setupGameEngine();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupGameEngine() {
    final config = _game?.gameConfig;
    final type = _game?.gameType.toLowerCase() ?? 'memory';
    _maxScore = _game?.pointsReward ?? 100;
    _score = 0;
    _isGameOver = false;

    if (type == 'memory') {
      final pairs = (config?['pairs'] as List?)?.whereType<Map>().toList() ?? [
        {'a': 'Salah', 'b': 'Prayer'},
        {'a': 'Zakat', 'b': 'Charity'},
        {'a': 'Sawm', 'b': 'Fasting'},
        {'a': 'Hajj', 'b': 'Pilgrimage'},
        {'a': 'Masjid', 'b': 'Mosque'},
        {'a': 'Quran', 'b': 'Holy Book'},
      ];

      final cards = <_MemoryCard>[];
      for (int i = 0; i < pairs.length; i++) {
        final p = pairs[i];
        cards.add(_MemoryCard(pairId: i, text: p['a'].toString(), isKey: true));
        cards.add(_MemoryCard(pairId: i, text: p['b'].toString(), isKey: false));
      }
      cards.shuffle();
      _memoryCards = cards;
      _firstSelectedCard = null;
      _secondSelectedCard = null;
      _isMemoryChecking = false;
      _memoryMoves = 0;
    } else if (type == 'matching') {
      final pairs = (config?['pairs'] as List?)?.whereType<Map>().map((m) {
        return {'left': m['left'].toString(), 'right': m['right'].toString()};
      }).toList() ?? [
        {'left': 'Before eating', 'right': 'Bismillah'},
        {'left': 'After eating', 'right': 'Alhamdulillah'},
        {'left': 'Before sleeping', 'right': 'Bismika Allahumma amutu wa ahya'},
        {'left': 'Entering masjid', 'right': 'Allahumma iftah li abwaba rahmatik'},
      ];
      _matchingPairs = pairs;
      _selectedLeft = null;
      _selectedRight = null;
      _matchedLefts.clear();
    } else if (type == 'true_false') {
      final questions = (config?['questions'] as List?)?.whereType<Map>().map((m) {
        return {'prompt': m['prompt'].toString(), 'answer': m['answer'] == true};
      }).toList() ?? [
        {'prompt': 'Muslims pray five times every day.', 'answer': true},
        {'prompt': 'Ramadan is the month of fasting.', 'answer': true},
        {'prompt': 'The Quran has 114 surahs.', 'answer': true},
        {'prompt': 'Zakat is optional for everyone.', 'answer': false},
        {'prompt': 'The Kaaba is in Makkah.', 'answer': true},
      ];
      _quizQuestions = questions;
      _currentQuestionIndex = 0;
      _selectedTrueFalse = null;
      _hasAnsweredCurrent = false;
    } else if (type == 'multiple_choice' || type == 'islamic_knowledge') {
      final questions = (config?['questions'] as List?)?.whereType<Map>().map((m) {
        final rawOpts = m['options'] as List? ?? ['A', 'B', 'C', 'D'];
        return {
          'prompt': m['prompt'].toString(),
          'options': rawOpts.map((o) => o.toString()).toList(),
          'correct': int.tryParse(m['correct']?.toString() ?? '0') ?? 0,
        };
      }).toList() ?? [
        {
          'prompt': 'Which prophet built the Ark?',
          'options': ['Prophet Nuh ﷺ', 'Prophet Musa ﷺ', 'Prophet Yusuf ﷺ', 'Prophet Ibrahim ﷺ'],
          'correct': 0,
        },
        {
          'prompt': 'How many pillars of Islam are there?',
          'options': ['3', '4', '5', '6'],
          'correct': 2,
        },
      ];
      _quizQuestions = questions;
      _currentQuestionIndex = 0;
      _selectedAnswerIndex = null;
      _hasAnsweredCurrent = false;
    } else if (type == 'word') {
      final words = (config?['words'] as List?)?.whereType<Map>().map((m) {
        return {'word': m['word'].toString().toUpperCase(), 'hint': m['hint'].toString()};
      }).toList() ?? [
        {'word': 'SALAH', 'hint': 'The five daily prayers'},
        {'word': 'IMAN', 'hint': 'Faith in Allah'},
        {'word': 'WUDU', 'hint': 'Washing before prayer'},
        {'word': 'DUA', 'hint': 'A supplication to Allah'},
      ];
      _wordList = words;
      _currentWordIndex = 0;
      _initCurrentWord();
    } else if (type == 'drag_drop') {
      final groups = (config?['groups'] as List?)?.whereType<Map>().map((m) => {
        'id': m['id'].toString(),
        'label': m['label'].toString(),
      }).toList() ?? [
        {'id': 'halal', 'label': 'Halal'},
        {'id': 'haram', 'label': 'Haram'},
      ];
      final items = (config?['items'] as List?)?.whereType<Map>().map((m) => {
        'label': m['label'].toString(),
        'group': m['group'].toString(),
      }).toList() ?? [
        {'label': 'Apple', 'group': 'halal'},
        {'label': 'Water', 'group': 'halal'},
        {'label': 'Pork', 'group': 'haram'},
        {'label': 'Dates', 'group': 'halal'},
        {'label': 'Alcohol', 'group': 'haram'},
      ];
      _sortGroups = groups;
      _sortItems = items;
      _currentSortItemIndex = 0;
      _sortedBuckets.clear();
      for (final g in _sortGroups) {
        _sortedBuckets[g['id']] = [];
      }
    } else if (type == 'puzzle') {
      final tiles = (config?['tiles'] as List?)?.map((t) => t.toString()).toList() ?? [
        'Prophet Nuh ﷺ',
        'Prophet Ibrahim ﷺ',
        'Prophet Musa ﷺ',
        'Prophet Isa ﷺ',
        'Prophet Muhammad ﷺ',
      ];
      final shuffled = List<String>.from(tiles)..shuffle();
      _timelineTiles = shuffled;
      _selectedTimelineTile = null;
    }
  }

  void _initCurrentWord() {
    if (_currentWordIndex >= _wordList.length) return;
    final word = _wordList[_currentWordIndex]['word']!;
    _revealedLetters = List.filled(word.length, '_');
    _guessedLetters.clear();
  }

  Future<void> _completeGame(int finalScore) async {
    HapticFeedback.heavyImpact();
    final elapsed = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    setState(() {
      _isGameOver = true;
      _score = finalScore;
      _timeTakenSeconds = elapsed > 0 ? elapsed : 15;
    });

    if (!mounted) return;
    final token = context.read<AuthController>().currentToken;
    if (_attemptToken != null) {
      await _api.submitGameResult(
        attemptToken: _attemptToken!,
        score: finalScore,
        maxScore: _maxScore,
        timeTakenSeconds: _timeTakenSeconds,
        token: token,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Handlers for Specific Game Engines
  // ───────────────────────────────────────────────────────────────────────────

  // Memory Match Tap
  void _onMemoryCardTap(int index) {
    if (_isMemoryChecking || _memoryCards[index].isMatched || _memoryCards[index].isFlipped) return;
    HapticFeedback.selectionClick();

    setState(() {
      _memoryCards[index].isFlipped = true;
    });

    if (_firstSelectedCard == null) {
      _firstSelectedCard = index;
    } else {
      _secondSelectedCard = index;
      _memoryMoves++;
      _isMemoryChecking = true;

      final first = _memoryCards[_firstSelectedCard!];
      final second = _memoryCards[_secondSelectedCard!];

      if (first.pairId == second.pairId && first != second) {
        setState(() {
          first.isMatched = true;
          second.isMatched = true;
          _firstSelectedCard = null;
          _secondSelectedCard = null;
          _isMemoryChecking = false;
        });

        if (_memoryCards.every((c) => c.isMatched)) {
          _completeGame(_maxScore);
        }
      } else {
        Timer(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              first.isFlipped = false;
              second.isFlipped = false;
              _firstSelectedCard = null;
              _secondSelectedCard = null;
              _isMemoryChecking = false;
            });
          }
        });
      }
    }
  }

  // Dua Match Tap
  void _onDuaLeftTap(String left) {
    if (_matchedLefts.contains(left)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLeft = left;
    });
    _checkDuaPair();
  }

  void _onDuaRightTap(String right) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRight = right;
    });
    _checkDuaPair();
  }

  void _checkDuaPair() {
    if (_selectedLeft == null || _selectedRight == null) return;

    final match = _matchingPairs.firstWhere(
      (p) => p['left'] == _selectedLeft && p['right'] == _selectedRight,
      orElse: () => {},
    );

    if (match.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _matchedLefts.add(_selectedLeft!);
        _selectedLeft = null;
        _selectedRight = null;
      });

      if (_matchedLefts.length == _matchingPairs.length) {
        _completeGame(_maxScore);
      }
    } else {
      HapticFeedback.vibrate();
      Timer(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _selectedLeft = null;
            _selectedRight = null;
          });
        }
      });
    }
  }

  // True / False Answer
  void _onTrueFalseAnswer(bool value) {
    if (_hasAnsweredCurrent) return;
    HapticFeedback.lightImpact();

    final correct = _quizQuestions[_currentQuestionIndex]['answer'] == value;
    setState(() {
      _selectedTrueFalse = value;
      _hasAnsweredCurrent = true;
      if (correct) {
        _score += (_maxScore / _quizQuestions.length).round();
      }
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (_currentQuestionIndex + 1 < _quizQuestions.length) {
        setState(() {
          _currentQuestionIndex++;
          _selectedTrueFalse = null;
          _hasAnsweredCurrent = false;
        });
      } else {
        _completeGame(_score.clamp(0, _maxScore));
      }
    });
  }

  // Multiple Choice Answer
  void _onMultipleChoiceAnswer(int index) {
    if (_hasAnsweredCurrent) return;
    HapticFeedback.lightImpact();

    final correct = _quizQuestions[_currentQuestionIndex]['correct'] == index;
    setState(() {
      _selectedAnswerIndex = index;
      _hasAnsweredCurrent = true;
      if (correct) {
        _score += (_maxScore / _quizQuestions.length).round();
      }
    });

    Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_currentQuestionIndex + 1 < _quizQuestions.length) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = null;
          _hasAnsweredCurrent = false;
        });
      } else {
        _completeGame(_score.clamp(0, _maxScore));
      }
    });
  }

  // Word Puzzle Letter Guess
  void _onLetterGuess(String letter) {
    if (_guessedLetters.contains(letter)) return;
    HapticFeedback.selectionClick();

    final word = _wordList[_currentWordIndex]['word']!;
    setState(() {
      _guessedLetters.add(letter);
      for (int i = 0; i < word.length; i++) {
        if (word[i] == letter) {
          _revealedLetters[i] = letter;
        }
      }
    });

    // Check if word completed
    if (!_revealedLetters.contains('_')) {
      HapticFeedback.mediumImpact();
      _score += (_maxScore / _wordList.length).round();

      Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        if (_currentWordIndex + 1 < _wordList.length) {
          setState(() {
            _currentWordIndex++;
            _initCurrentWord();
          });
        } else {
          _completeGame(_score.clamp(0, _maxScore));
        }
      });
    }
  }

  // Sort It Right (Categorization)
  void _onSortGroupSelected(String groupId) {
    if (_currentSortItemIndex >= _sortItems.length) return;
    HapticFeedback.selectionClick();

    final currentItem = _sortItems[_currentSortItemIndex];
    final isCorrect = currentItem['group'] == groupId;

    setState(() {
      _sortedBuckets[groupId]?.add(currentItem['label']);
      if (isCorrect) {
        _score += (_maxScore / _sortItems.length).round();
      }
      _currentSortItemIndex++;
    });

    if (_currentSortItemIndex >= _sortItems.length) {
      _completeGame(_score.clamp(0, _maxScore));
    }
  }

  // Prophet Timeline (Swap Tiles)
  void _onTimelineTileTap(int index) {
    HapticFeedback.selectionClick();
    if (_selectedTimelineTile == null) {
      setState(() => _selectedTimelineTile = index);
    } else {
      final firstIdx = _selectedTimelineTile!;
      setState(() {
        final temp = _timelineTiles[firstIdx];
        _timelineTiles[firstIdx] = _timelineTiles[index];
        _timelineTiles[index] = temp;
        _selectedTimelineTile = null;
      });
    }
  }

  void _verifyTimelineOrder() {
    final original = (_game?.gameConfig?['tiles'] as List?)?.map((t) => t.toString()).toList() ?? [
      'Prophet Nuh ﷺ',
      'Prophet Ibrahim ﷺ',
      'Prophet Musa ﷺ',
      'Prophet Isa ﷺ',
      'Prophet Muhammad ﷺ',
    ];

    bool allCorrect = true;
    for (int i = 0; i < original.length; i++) {
      if (i >= _timelineTiles.length || _timelineTiles[i] != original[i]) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      _completeGame(_maxScore);
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order is not quite right yet. Try rearranging the tiles!'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _game?.title ?? 'Kids Islamic Game';
    final iconEmoji = _game?.icon ?? '🎮';
    final type = _game?.gameType.toLowerCase() ?? 'memory';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.navyDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(iconEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFB91C1C)),
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    children: [
                      // Header Stats Bar
                      _buildHeaderStatsBar(type),
                      const SizedBox(height: 16),

                      // Game Engine Body
                      Expanded(
                        child: _buildCurrentEngine(type),
                      ),
                    ],
                  ),
                ),

                // Victory / Game Over Overlay
                if (_isGameOver) _buildGameOverDialog(),
              ],
            ),
    );
  }

  Widget _buildHeaderStatsBar(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 6),
              Text(
                'XP: $_score / $_maxScore',
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navyDark),
              ),
              if (type == 'memory') ...[
                const SizedBox(width: 12),
                Text(
                  'Moves: $_memoryMoves',
                  style: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _game?.difficulty.toUpperCase() ?? 'EASY',
              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentEngine(String type) {
    switch (type) {
      case 'memory':
        return _buildMemoryEngine();
      case 'matching':
        return _buildMatchingEngine();
      case 'true_false':
        return _buildTrueFalseEngine();
      case 'multiple_choice':
      case 'islamic_knowledge':
        return _buildMultipleChoiceEngine();
      case 'word':
        return _buildWordEngine();
      case 'drag_drop':
        return _buildDragDropEngine();
      case 'puzzle':
        return _buildTimelineEngine();
      default:
        return _buildMemoryEngine();
    }
  }

  // ── 1. Memory Match Engine ──────────────────────────────────────────────────
  Widget _buildMemoryEngine() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: _memoryCards.length,
      itemBuilder: (context, index) {
        final card = _memoryCards[index];
        final isRevealed = card.isFlipped || card.isMatched;

        return GestureDetector(
          onTap: () => _onMemoryCardTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isRevealed
                  ? (card.isMatched ? const Color(0xFF10B981) : AppColors.navyDark)
                  : Colors.white,
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
                isRevealed ? card.text : '🌟',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: isRevealed ? 13.5 : 24,
                  fontWeight: FontWeight.w800,
                  color: isRevealed ? Colors.white : AppColors.navyDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── 2. Dua Match Engine ────────────────────────────────────────────────────
  Widget _buildMatchingEngine() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column (Situations)
        Expanded(
          child: ListView.builder(
            itemCount: _matchingPairs.length,
            itemBuilder: (context, index) {
              final item = _matchingPairs[index]['left']!;
              final isMatched = _matchedLefts.contains(item);
              final isSelected = _selectedLeft == item;

              return GestureDetector(
                onTap: isMatched ? null : () => _onDuaLeftTap(item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMatched
                        ? const Color(0xFF10B981)
                        : (isSelected ? AppColors.navyDark : Colors.white),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMatched || isSelected ? Colors.white : AppColors.navyDark,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // Right column (Duas)
        Expanded(
          child: ListView.builder(
            itemCount: _matchingPairs.length,
            itemBuilder: (context, index) {
              final right = _matchingPairs[index]['right']!;
              final isSelected = _selectedRight == right;

              return GestureDetector(
                onTap: () => _onDuaRightTap(right),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.gold : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.navyDark : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    right,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.navyDark : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 3. True or False Engine ────────────────────────────────────────────────
  Widget _buildTrueFalseEngine() {
    if (_currentQuestionIndex >= _quizQuestions.length) return const SizedBox.shrink();
    final q = _quizQuestions[_currentQuestionIndex];
    final answer = q['answer'] == true;

    Color trueBg = const Color(0xFF10B981);
    Color falseBg = const Color(0xFFEF4444);

    if (_hasAnsweredCurrent) {
      if (_selectedTrueFalse == true) {
        trueBg = answer ? const Color(0xFF10B981) : const Color(0xFFB91C1C);
      }
      if (_selectedTrueFalse == false) {
        falseBg = !answer ? const Color(0xFF10B981) : const Color(0xFFB91C1C);
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_quizQuestions.length}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Text(
                q['prompt'].toString(),
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.navyDark, height: 1.35),
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _hasAnsweredCurrent ? null : () => _onTrueFalseAnswer(true),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text('TRUE', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: trueBg,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _hasAnsweredCurrent ? null : () => _onTrueFalseAnswer(false),
                  icon: const Icon(Icons.cancel_rounded, size: 20),
                  label: Text('FALSE', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: falseBg,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── 4. Multiple Choice Engine ──────────────────────────────────────────────
  Widget _buildMultipleChoiceEngine() {
    if (_currentQuestionIndex >= _quizQuestions.length) return const SizedBox.shrink();
    final q = _quizQuestions[_currentQuestionIndex];
    final options = (q['options'] as List).cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_quizQuestions.length}',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              Text(
                q['prompt'].toString(),
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navyDark, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = _selectedAnswerIndex == index;
              final isCorrect = q['correct'] == index;

              Color bg = Colors.white;
              Color border = const Color(0xFFE2E8F0);
              Color textColor = AppColors.navyDark;

              if (_hasAnsweredCurrent) {
                if (isCorrect) {
                  bg = const Color(0xFF10B981);
                  border = const Color(0xFF10B981);
                  textColor = Colors.white;
                } else if (isSelected) {
                  bg = const Color(0xFFEF4444);
                  border = const Color(0xFFEF4444);
                  textColor = Colors.white;
                }
              }

              return GestureDetector(
                onTap: _hasAnsweredCurrent ? null : () => _onMultipleChoiceAnswer(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _hasAnsweredCurrent && (isCorrect || isSelected)
                              ? Colors.white.withAlpha(40)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: _hasAnsweredCurrent && (isCorrect || isSelected)
                                  ? Colors.white
                                  : AppColors.navyDark,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 5. Word Puzzle Engine ──────────────────────────────────────────────────
  Widget _buildWordEngine() {
    if (_currentWordIndex >= _wordList.length) return const SizedBox.shrink();
    final item = _wordList[_currentWordIndex];
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text('Word ${_currentWordIndex + 1} of ${_wordList.length}', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 6),
              Text(
                '💡 Hint: ${item['hint']}',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _revealedLetters.map((l) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 36,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.navyDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        l,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.gold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: letters.length,
            itemBuilder: (context, index) {
              final letter = letters[index];
              final isUsed = _guessedLetters.contains(letter);

              return ElevatedButton(
                onPressed: isUsed ? null : () => _onLetterGuess(letter),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navyDark,
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(letter, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800)),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── 6. Sort It Right Engine ────────────────────────────────────────────────
  Widget _buildDragDropEngine() {
    if (_currentSortItemIndex >= _sortItems.length) return const SizedBox.shrink();
    final currentItem = _sortItems[_currentSortItemIndex];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text('Item ${_currentSortItemIndex + 1} of ${_sortItems.length}', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.navyDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  currentItem['label'],
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold),
                ),
              ),
              const SizedBox(height: 8),
              Text('Which category does this belong to?', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B))),
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: _sortGroups.map((g) {
            final isHalal = g['id'] == 'halal';
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _onSortGroupSelected(g['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHalal ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      g['label'].toString().toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── 7. Prophet Timeline Engine ─────────────────────────────────────────────
  Widget _buildTimelineEngine() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap any two names to swap them into the correct historical order:',
          style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _timelineTiles.length,
            itemBuilder: (context, index) {
              final tile = _timelineTiles[index];
              final isSelected = _selectedTimelineTile == index;

              return GestureDetector(
                onTap: () => _onTimelineTileTap(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.navyDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.gold : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withAlpha(30) : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: isSelected ? Colors.white : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        tile,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.navyDark,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.swap_vert_rounded,
                        color: isSelected ? AppColors.gold : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _verifyTimelineOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navyDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Submit Order', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Victory Dialog Overlay
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildGameOverDialog() {
    return Container(
      color: Colors.black.withAlpha(150),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'MashaAllah! Great Job!',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.navyDark),
              ),
              const SizedBox(height: 8),
              Text(
                'You earned +$_score XP in $_timeTakenSeconds seconds!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _setupGameEngine();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Play Again'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Kids Portal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemoryCard {
  _MemoryCard({
    required this.pairId,
    required this.text,
    required this.isKey,
  });

  final int pairId;
  final String text;
  final bool isKey;
  bool isFlipped = false;
  bool isMatched = false;
}
