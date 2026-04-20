import 'dart:convert';
import 'package:runanywhere/runanywhere.dart';

/// AI Tutor service that wraps RunAnywhere LLM with educational prompts
class AiTutorService {
  // ── System Prompts ──

  static const _quizSystemPrompt =
      '''You are a quiz generator for students. Generate exactly one multiple-choice question.

RULES:
- Output ONLY valid JSON, nothing else before or after.
- Do not use markdown blocks (e.g. ```json). Just output the raw JSON object.
- The JSON object must have exactly these keys: "question", "options" (an object with keys "A", "B", "C", "D"), "correctAnswer" (must be "A", "B", "C", or "D"), and "explanation".

FORMAT:
{
  "question": "question text here",
  "options": {
    "A": "option A",
    "B": "option B",
    "C": "option C",
    "D": "option D"
  },
  "correctAnswer": "A",
  "explanation": "brief explanation"
}''';

  static const _quizFromDocPrompt =
      '''You are a quiz generator. Generate exactly one multiple-choice question based ONLY on the provided study material.

RULES:
- The question MUST be answerable from the provided content.
- Output ONLY valid JSON, nothing else before or after.
- Do not use markdown blocks (e.g. ```json). Just output the raw JSON object.
- The JSON object must have exactly these keys: "question", "options" (an object with keys "A", "B", "C", "D"), "correctAnswer" (must be "A", "B", "C", or "D"), and "explanation".

FORMAT:
{
  "question": "question text here",
  "options": {
    "A": "option A",
    "B": "option B",
    "C": "option C",
    "D": "option D"
  },
  "correctAnswer": "A",
  "explanation": "brief explanation referencing material"
}''';

  static const _simplifierSystemPrompt =
      '''You are ThinkMate, a friendly AI tutor that simplifies complex topics for students.

RULES:
- Break down the concept into simple, easy-to-understand steps
- Use analogies and everyday examples
- Keep language simple and engaging
- Use numbered steps when explaining processes
- End with a brief summary''';

  static const _simplifierFromDocPrompt =
      '''You are ThinkMate, a friendly AI tutor. Explain the concept using ONLY the provided study material as your knowledge source.

RULES:
- Use ONLY information from the provided material
- Break down the concept into simple steps
- Use examples from the material when possible
- Keep language simple and engaging''';

  static const _languagePracticePrompt =
      '''You are a language conversation partner for English practice.

RULES:
- Respond naturally to continue the conversation
- After your response, add a line starting with "FEEDBACK:" 
- In feedback, note any grammar or fluency improvements the user could make
- Keep responses conversational and encouraging
- If the user's message has errors, gently correct them in the feedback''';

  static const _conversationFromDocPrompt =
      '''You are ThinkMate, a friendly AI study tutor. Answer the student's question using ONLY the provided study material.

RULES:
- Use ONLY information from the provided material to answer
- Be conversational and encouraging
- If the answer is not in the material, say so honestly
- Give clear, concise explanations
- Use examples from the material when possible''';

  // ── General Methods (no document context) ──

  /// Generate a quiz question for the given subject and difficulty
  static Future<LLMStreamingResult> generateQuizQuestion({
    required String subject,
    required String difficulty,
    String? previousContext,
  }) async {
    final prompt = '''$_quizSystemPrompt

Subject: $subject
Difficulty: $difficulty
${previousContext != null ? 'Avoid repeating: $previousContext' : ''}

Generate a $difficulty $subject question now:''';

    return await RunAnywhere.generateStream(
      prompt,
      options: const LLMGenerationOptions(
        maxTokens: 300,
        temperature: 0.8,
      ),
    );
  }

  /// Simplify a complex concept
  static Future<LLMStreamingResult> simplifyConcept(String topic) async {
    final prompt = '''$_simplifierSystemPrompt

The student asks: "$topic"

Provide a clear, step-by-step explanation:''';

    return await RunAnywhere.generateStream(
      prompt,
      options: const LLMGenerationOptions(
        maxTokens: 512,
        temperature: 0.7,
      ),
    );
  }

  /// Generate a conversation response for language practice
  static Future<LLMStreamingResult> languageConversation({
    required String scenario,
    required String userMessage,
    String? conversationHistory,
  }) async {
    final prompt = '''$_languagePracticePrompt

Scenario: $scenario
${conversationHistory != null ? 'Previous conversation:\n$conversationHistory\n' : ''}
User: $userMessage

Respond naturally and provide feedback:''';

    return await RunAnywhere.generateStream(
      prompt,
      options: const LLMGenerationOptions(
        maxTokens: 300,
        temperature: 0.8,
      ),
    );
  }

  // ── Document-Context Methods ──

  /// Generate a quiz question from document content
  static Future<LLMStreamingResult> generateQuizFromDocument({
    required String documentChunk,
    required String difficulty,
    String? previousContext,
  }) async {
    final prompt = '''$_quizFromDocPrompt

STUDY MATERIAL:
"""
$documentChunk
"""

Difficulty: $difficulty
${previousContext != null ? 'Avoid repeating: $previousContext' : ''}

Generate a $difficulty question based on this material:''';

    return await RunAnywhere.generateStream(
      prompt,
      options: const LLMGenerationOptions(
        maxTokens: 300,
        temperature: 0.7,
      ),
    );
  }

  /// Simplify a concept using document context
  static Future<LLMStreamingResult> simplifyFromDocument({
    required String topic,
    required String documentChunk,
  }) async {
    final prompt = '''$_simplifierFromDocPrompt

STUDY MATERIAL:
"""
$documentChunk
"""

The student asks: "$topic"

Explain this using the study material:''';

    return await RunAnywhere.generateStream(
      prompt,
      options: const LLMGenerationOptions(
        maxTokens: 512,
        temperature: 0.7,
      ),
    );
  }

  /// Conversation grounded in document content
  static Future<LLMStreamingResult> conversationFromDocument({
    required String userMessage,
    required String documentChunk,
    String? conversationHistory,
  }) async {
    final prompt = '''$_conversationFromDocPrompt

STUDY MATERIAL:
"""
$documentChunk
"""

${conversationHistory != null ? 'Previous conversation:\n$conversationHistory\n' : ''}
Student: $userMessage

Answer based on the study material:''';

    return await RunAnywhere.generateStream(
      prompt,
      options: const LLMGenerationOptions(
        maxTokens: 400,
        temperature: 0.7,
      ),
    );
  }

  // ── Parsing ──

  /// Parse a quiz question from LLM output
  static QuizQuestion? parseQuizQuestion(String raw) {
    try {
      // Find the first { and last } to extract the JSON block, ignoring any conversational padding
      final startIdx = raw.indexOf('{');
      final endIdx = raw.lastIndexOf('}');
      if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
        return null; // Not valid JSON
      }

      final jsonString = raw.substring(startIdx, endIdx + 1);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final question = data['question']?.toString() ?? '';
      final optionsRaw = data['options'] as Map<String, dynamic>? ?? {};
      final options =
          optionsRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
      var correctAnswer = data['correctAnswer']?.toString().toUpperCase() ?? '';
      var explanation = data['explanation']?.toString() ?? '';

      // Validate required fields
      if (question.isEmpty || options.length < 2 || correctAnswer.isEmpty) {
        return null;
      }

      // Ensure correctAnswer matches an available option
      if (!options.containsKey(correctAnswer)) {
        correctAnswer = options.keys.first;
      }

      return QuizQuestion(
        question: question,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation.isEmpty
            ? 'The correct answer is $correctAnswer.'
            : explanation,
      );
    } catch (_) {
      return null;
    }
  }
}

class QuizQuestion {
  final String question;
  final Map<String, String> options;
  final String correctAnswer;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}
