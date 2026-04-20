import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Reactive progress tracking service
class ProgressService extends ChangeNotifier {
  final StorageService _storage = StorageService();
  bool _initialized = false;

  bool get isInitialized => _initialized;

  // Quick getters
  int get currentStreak => _storage.currentStreak;
  int get totalQuizzes => _storage.totalQuizzes;
  int get totalCorrect => _storage.totalCorrect;
  int get totalQuestions => _storage.totalQuestions;
  double get accuracy => _storage.accuracy;
  int get conversationCount => _storage.conversationCount;

  List<Map<String, dynamic>> get quizHistory => _storage.getQuizHistory();
  Map<String, dynamic> get subjectStats => _storage.getSubjectStats();

  Future<void> init() async {
    await _storage.init();
    _initialized = true;
    notifyListeners();
  }

  Future<void> recordQuizResult({
    required String subject,
    required int correct,
    required int total,
    required String difficulty,
  }) async {
    await _storage.saveQuizResult(
      subject: subject,
      correct: correct,
      total: total,
      difficulty: difficulty,
    );
    notifyListeners();
  }

  Future<void> recordConversation() async {
    await _storage.incrementConversationCount();
    notifyListeners();
  }
}
