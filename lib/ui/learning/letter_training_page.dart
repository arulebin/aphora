import 'package:aphora/data/learning/letter_training_data.dart';
import 'package:aphora/logic/speech_service.dart';
import 'package:flutter/material.dart';

/// Targeted drill triggered when the patient mispronounces one or
/// more letters in a phrase. For each mispronounced letter we run two
/// simple prompts: say the letter, then say a word containing it.
class LetterTrainingPage extends StatefulWidget {
  /// The grapheme clusters that were mispronounced. Order is preserved
  /// so we drill the first miss first.
  final List<String> letters;

  /// Speech locale (e.g. `ta-IN`, `en-US`) for both TTS playback
  /// and STT recognition during the drill.
  final String language;

  const LetterTrainingPage({
    super.key,
    required this.letters,
    this.language = 'ta-IN',
  });

  @override
  State<LetterTrainingPage> createState() => _LetterTrainingPageState();
}

class _LetterTrainingPageState extends State<LetterTrainingPage> {
  late final SpeechService _speech;
  late final List<_DrillItem> _items;

  int _index = 0;
  bool _isListening = false;
  bool _evaluating = false;
  PronunciationAnalysis? _lastResult;

  @override
  void initState() {
    super.initState();
    _speech = SpeechService();
    _items = [
      for (final letter in widget.letters)
        for (final drill in drillsForLetter(letter))
          _DrillItem(letter: letter, drill: drill),
    ];
  }

  @override
  void dispose() {
    _speech.dispose();
    super.dispose();
  }

  Future<void> _hear() async {
    if (_items.isEmpty) return;
    final item = _items[_index];
    await _speech.speakText(item.drill.prompt, language: widget.language);
  }

  Future<void> _record() async {
    if (_isListening || _evaluating || _items.isEmpty) return;
    final item = _items[_index];

    setState(() {
      _isListening = true;
      _lastResult = null;
    });

    try {
      final spoken = await _speech.startListening(
        language: widget.language,
        maxDuration: 6,
      );
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _evaluating = true;
      });

      final result = TextEvaluator.analyze(item.drill.prompt, spoken);

      if (!mounted) return;
      setState(() {
        _evaluating = false;
        _lastResult = result;
      });

      // Auto-advance on a clean pronunciation; otherwise let the
      // patient try again or move on manually.
      if (result.isCorrect) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _next();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _evaluating = false;
      });
    }
  }

  void _next() {
    if (_index < _items.length - 1) {
      setState(() {
        _index++;
        _lastResult = null;
      });
    } else {
      Navigator.of(context).pop(true);
    }
  }

  void _skip() {
    if (_index < _items.length - 1) {
      _next();
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      // Nothing to drill (caller should have checked) — pop immediately.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Navigator.of(context).maybePop(false),
      );
      return const Scaffold();
    }

    final item = _items[_index];
    final progress = (_index + 1) / _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        title: Text('Practice "${item.letter}"'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drill ${_index + 1} of ${_items.length}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    item.drill.hint,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.drill.prompt,
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  IconButton(
                    onPressed: _evaluating ? null : _hear,
                    icon: const Icon(
                      Icons.volume_up,
                      size: 36,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                  const Text(
                    'Tap to hear',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_lastResult != null) _buildResultBanner(_lastResult!),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isListening || _evaluating ? null : _record,
              icon: Icon(_isListening ? Icons.graphic_eq : Icons.mic),
              label: Text(
                _isListening
                    ? 'Listening…'
                    : _evaluating
                        ? 'Checking…'
                        : 'Record',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isListening
                    ? Colors.redAccent
                    : const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isListening || _evaluating ? null : _skip,
              child: Text(
                _index < _items.length - 1 ? 'Skip' : 'Finish',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBanner(PronunciationAnalysis r) {
    final ok = r.isCorrect;
    final color = ok ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.refresh, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ok ? 'Nice — clear pronunciation!' : 'Try again',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (r.actualNormalized.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'You said: "${r.actualNormalized}"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${r.similarity.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrillItem {
  final String letter;
  final LetterDrill drill;
  const _DrillItem({required this.letter, required this.drill});
}
