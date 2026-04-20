import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';

import '../services/ai_tutor_service.dart';
import '../services/model_service.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/model_loader_widget.dart';

class LanguagePracticeView extends StatefulWidget {
  const LanguagePracticeView({super.key});

  @override
  State<LanguagePracticeView> createState() => _LanguagePracticeViewState();
}

class _LanguagePracticeViewState extends State<LanguagePracticeView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ConversationMessage> _messages = [];
  bool _isGenerating = false;
  String _currentResponse = '';
  LLMStreamingResult? _streamingResult;
  String _selectedScenario = 'Greetings';

  static const List<Map<String, dynamic>> _scenarios = [
    {'label': 'Greetings', 'icon': Icons.waving_hand_rounded, 'color': AppColors.accentCyan},
    {'label': 'Travel', 'icon': Icons.flight_rounded, 'color': AppColors.accentViolet},
    {'label': 'Interview', 'icon': Icons.work_rounded, 'color': AppColors.accentOrange},
    {'label': 'Restaurant', 'icon': Icons.restaurant_rounded, 'color': AppColors.accentPink},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': AppColors.accentGreen},
    {'label': 'Daily Life', 'icon': Icons.home_rounded, 'color': AppColors.accentCyan},
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _streamingResult?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Language Practice'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _resetConversation,
              tooltip: 'New conversation',
            ),
        ],
      ),
      body: Consumer<ModelService>(
        builder: (context, modelService, child) {
          if (!modelService.isLLMLoaded) {
            return ModelLoaderWidget(
              title: 'LLM Model Required',
              subtitle: 'Download the AI model for conversation practice',
              icon: Icons.translate_rounded,
              accentColor: AppColors.accentPink,
              isDownloading: modelService.isLLMDownloading,
              isLoading: modelService.isLLMLoading,
              progress: modelService.llmDownloadProgress,
              onLoad: () => modelService.downloadAndLoadLLM(),
            );
          }

          return Column(
            children: [
              if (_messages.isEmpty) _buildScenarioSelector(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
              ),
              _buildInputArea(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScenarioSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a Scenario',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _scenarios.map((s) {
                final isSelected = _selectedScenario == s['label'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedScenario = s['label'] as String),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (s['color'] as Color).withOpacity(0.2)
                              : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? s['color'] as Color
                                : AppColors.textMuted.withOpacity(0.15),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(s['icon'] as IconData, color: s['color'] as Color, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              s['label'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? s['color'] as Color
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.translate_rounded,
                size: 48,
                color: AppColors.accentPink,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms),
            const SizedBox(height: 24),
            Text(
              'Practice Conversations',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation in the "$_selectedScenario" scenario.\nThe AI will provide feedback on your English.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _getStarterPrompts().map((p) {
                return ActionChip(
                  label: Text(p, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.surfaceCard,
                  side: BorderSide(color: AppColors.accentPink.withOpacity(0.3)),
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                  onPressed: () {
                    _controller.text = p;
                    _sendMessage();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  List<String> _getStarterPrompts() {
    switch (_selectedScenario) {
      case 'Greetings':
        return ['Hello, how are you today?', 'Good morning, nice to meet you!'];
      case 'Travel':
        return ['How do I get to the train station?', 'I would like to book a flight'];
      case 'Interview':
        return ['Tell me about yourself', 'What are your strengths?'];
      case 'Restaurant':
        return ['Can I see the menu please?', 'I would like to order pasta'];
      case 'Shopping':
        return ['How much does this cost?', 'Do you have this in a different size?'];
      default:
        return ["What's the weather like?", 'What are your hobbies?'];
    }
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isGenerating) {
          return _buildAIBubble(
            _currentResponse.isEmpty ? '...' : _currentResponse,
            isStreaming: true,
          ).animate().fadeIn(duration: 300.ms);
        }

        final msg = _messages[index];
        if (msg.isUser) {
          return _buildUserBubble(msg.text);
        }
        return _buildAIBubble(msg.text, feedback: msg.feedback);
      },
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentPink, Color(0xFFDB2777)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentPink.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble(String text, {bool isStreaming = false, String? feedback}) {
    // Separate feedback from the response if present
    String mainText = text;
    String? displayFeedback = feedback;

    if (displayFeedback == null && text.contains('FEEDBACK:')) {
      final parts = text.split('FEEDBACK:');
      mainText = parts[0].trim();
      displayFeedback = parts.length > 1 ? parts[1].trim() : null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentPink, AppColors.accentViolet],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.translate_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: SelectableText(
                          mainText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                        ),
                      ),
                      if (isStreaming)
                        Container(
                          width: 8,
                          height: 16,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentPink,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(duration: 500.ms)
                            .then()
                            .fadeOut(duration: 500.ms),
                    ],
                  ),
                ),
                if (displayFeedback != null && displayFeedback.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accentGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            color: AppColors.accentGreen, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            displayFeedback,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accentGreen,
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
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: AppColors.primaryMid,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isGenerating,
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 12),
            _isGenerating
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.stop_rounded),
                      color: AppColors.error,
                      onPressed: _stopGeneration,
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentPink, Color(0xFFDB2777)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentPink.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      onPressed: _sendMessage,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isGenerating) return;

    setState(() {
      _messages.add(_ConversationMessage(text: text, isUser: true));
      _controller.clear();
      _isGenerating = true;
      _currentResponse = '';
    });

    _scrollToBottom();

    // Build conversation history for context
    final historyBuffer = StringBuffer();
    for (final msg in _messages.where((m) => !m.isUser || _messages.indexOf(m) < _messages.length - 1)) {
      historyBuffer.writeln(msg.isUser ? 'User: ${msg.text}' : 'AI: ${msg.text}');
    }

    try {
      _streamingResult = await AiTutorService.languageConversation(
        scenario: _selectedScenario,
        userMessage: text,
        conversationHistory: historyBuffer.isNotEmpty ? historyBuffer.toString() : null,
      );

      await for (final token in _streamingResult!.stream) {
        if (!mounted) return;
        setState(() {
          _currentResponse += token;
        });
        _scrollToBottom();
      }

      if (mounted) {
        // Parse feedback from response
        String mainText = _currentResponse;
        String? feedback;
        if (_currentResponse.contains('FEEDBACK:')) {
          final parts = _currentResponse.split('FEEDBACK:');
          mainText = parts[0].trim();
          feedback = parts.length > 1 ? parts[1].trim() : null;
        }

        setState(() {
          _messages.add(_ConversationMessage(
            text: mainText,
            isUser: false,
            feedback: feedback,
          ));
          _isGenerating = false;
          _currentResponse = '';
        });

        // Track conversation
        context.read<ProgressService>().recordConversation();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ConversationMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
          ));
          _isGenerating = false;
          _currentResponse = '';
        });
      }
    }
  }

  void _stopGeneration() {
    _streamingResult?.cancel();
    setState(() {
      if (_currentResponse.isNotEmpty) {
        _messages.add(_ConversationMessage(
          text: _currentResponse,
          isUser: false,
        ));
      }
      _isGenerating = false;
      _currentResponse = '';
    });
  }

  void _resetConversation() {
    setState(() {
      _messages.clear();
      _currentResponse = '';
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _ConversationMessage {
  final String text;
  final bool isUser;
  final String? feedback;

  const _ConversationMessage({
    required this.text,
    required this.isUser,
    this.feedback,
  });
}
