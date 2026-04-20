import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service for persisting learning progress
class StorageService {
  static const String _quizHistoryKey = 'quiz_history';
  static const String _streakKey = 'current_streak';
  static const String _lastStudyDateKey = 'last_study_date';
  static const String _totalQuizzesKey = 'total_quizzes';
  static const String _totalCorrectKey = 'total_correct';
  static const String _totalQuestionsKey = 'total_questions';
  static const String _subjectStatsKey = 'subject_stats';
  static const String _conversationCountKey = 'conversation_count';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Streak Management ──

  int get currentStreak => _prefs.getInt(_streakKey) ?? 0;

  String? get lastStudyDate => _prefs.getString(_lastStudyDateKey);

  Future<void> updateStreak() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = lastStudyDate;

    if (lastDate == today) return; // Already studied today

    if (lastDate != null) {
      final last = DateTime.parse(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      if (diff == 1) {
        // Consecutive day
        await _prefs.setInt(_streakKey, currentStreak + 1);
      } else if (diff > 1) {
        // Streak broken
        await _prefs.setInt(_streakKey, 1);
      }
    } else {
      await _prefs.setInt(_streakKey, 1);
    }

    await _prefs.setString(_lastStudyDateKey, today);
  }

  // ── Quiz Stats ──

  int get totalQuizzes => _prefs.getInt(_totalQuizzesKey) ?? 0;
  int get totalCorrect => _prefs.getInt(_totalCorrectKey) ?? 0;
  int get totalQuestions => _prefs.getInt(_totalQuestionsKey) ?? 0;

  double get accuracy =>
      totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0;

  Future<void> saveQuizResult({
    required String subject,
    required int correct,
    required int total,
    required String difficulty,
  }) async {
    // Update totals
    await _prefs.setInt(_totalQuizzesKey, totalQuizzes + 1);
    await _prefs.setInt(_totalCorrectKey, totalCorrect + correct);
    await _prefs.setInt(_totalQuestionsKey, totalQuestions + total);

    // Update subject stats
    final stats = getSubjectStats();
    final subjectData = stats[subject] ?? {'correct': 0, 'total': 0, 'quizzes': 0};
    subjectData['correct'] = (subjectData['correct'] as int) + correct;
    subjectData['total'] = (subjectData['total'] as int) + total;
    subjectData['quizzes'] = (subjectData['quizzes'] as int) + 1;
    stats[subject] = subjectData;
    await _prefs.setString(_subjectStatsKey, jsonEncode(stats));

    // Save to history
    final history = getQuizHistory();
    history.insert(0, {
      'subject': subject,
      'correct': correct,
      'total': total,
      'difficulty': difficulty,
      'date': DateTime.now().toIso8601String(),
    });
    // Keep only last 50 entries
    if (history.length > 50) history.removeLast();
    await _prefs.setString(_quizHistoryKey, jsonEncode(history));

    // Update streak
    await updateStreak();
  }

  List<Map<String, dynamic>> getQuizHistory() {
    final raw = _prefs.getString(_quizHistoryKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> getSubjectStats() {
    final raw = _prefs.getString(_subjectStatsKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  // ── Language Practice ──

  int get conversationCount => _prefs.getInt(_conversationCountKey) ?? 0;

  Future<void> incrementConversationCount() async {
    await _prefs.setInt(_conversationCountKey, conversationCount + 1);
    await updateStreak();
  }
}
