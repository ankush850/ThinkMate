import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';

import '../services/ai_tutor_service.dart';
import '../services/document_service.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';
import '../widgets/model_loader_widget.dart';

class ConceptSimplifierView extends StatefulWidget {
  final DocumentData? document;

  const ConceptSimplifierView({super.key, this.document});

  @override
  State<ConceptSimplifierView> createState() => _ConceptSimplifierViewState();
}

class _ConceptSimplifierViewState extends State<ConceptSimplifierView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_SimplifierMessage> _messages = [];
  bool _isGenerating = false;
  String _currentResponse = '';
  LLMStreamingResult? _streamingResult;

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
        title: const Text('Concept Simplifier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => setState(() => _messages.clear()),
              tooltip: 'Clear',
            ),
        ],
      ),
      body: Consumer<ModelService>(
        builder: (context, modelService, child) {
          if (!modelService.isLLMLoaded) {
            return ModelLoaderWidget(
              title: 'LLM Model Required',
              subtitle: 'Download the AI model to simplify complex concepts',
              icon: Icons.lightbulb_rounded,
              accentColor: AppColors.accentViolet,
              isDownloading: modelService.isLLMDownloading,
              isLoading: modelService.isLLMLoading,
              progress: modelService.llmDownloadProgress,
              onLoad: () => modelService.downloadAndLoadLLM(),
            );
          }

          return Column(
            children: [
              if (widget.document != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, size: 14, color: AppColors.accentCyan),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'From: ${widget.document!.title}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.accentCyan,
                                fontSize: 11,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentViolet.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_rounded,
                size: 48,
                color: AppColors.accentViolet,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 2000.ms),
            const SizedBox(height: 24),
            Text(
              'Simplify Any Concept',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a complex topic and get a clear,\nstep-by-step breakdown from AI.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: widget.document != null
                  ? [
                      _buildSuggestionChip('Summarize the main topics'),
                      _buildSuggestionChip('Explain the key concepts'),
                      _buildSuggestionChip('What are the main takeaways?'),
                    ]
                  : [
                      _buildSuggestionChip('Explain quantum computing'),
                      _buildSuggestionChip('How does photosynthesis work?'),
                      _buildSuggestionChip('What is machine learning?'),
                      _buildSuggestionChip('Explain the theory of relativity'),
                    ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.surfaceCard,
      side: BorderSide(color: AppColors.accentViolet.withOpacity(0.3)),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
          ),
      onPressed: () {
        _controller.text = text;
        _sendMessage();
      },
    );
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
        return _buildAIBubble(msg.text);
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
                  colors: [AppColors.accentViolet, Color(0xFF7C3AED)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentViolet.withOpacity(0.3),
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
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIBubble(String text, {bool isStreaming = false}) {
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
                colors: [AppColors.accentViolet, AppColors.accentPink],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
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
                border: Border.all(
                  color: AppColors.textMuted.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: SelectableText(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                    ),
                  ),
                  if (isStreaming)
                    Container(
                      width: 8,
                      height: 16,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentViolet,
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
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  hintText: 'Ask about any concept...',
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
                        colors: [AppColors.accentViolet, AppColors.accentPink],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentViolet.withOpacity(0.3),
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
      _messages.add(_SimplifierMessage(text: text, isUser: true));
      _controller.clear();
      _isGenerating = true;
      _currentResponse = '';
    });

    _scrollToBottom();

    try {
      if (widget.document != null) {
        // Document-based simplification
        final docService = context.read<DocumentService>();
        final chunk = docService.findRelevantChunk(text, document: widget.document);
        _streamingResult = await AiTutorService.simplifyFromDocument(
          topic: text,
          documentChunk: chunk,
        );
      } else {
        _streamingResult = await AiTutorService.simplifyConcept(text);
      }

      await for (final token in _streamingResult!.stream) {
        if (!mounted) return;
        setState(() {
          _currentResponse += token;
        });
        _scrollToBottom();
      }

      if (mounted) {
        setState(() {
          _messages.add(_SimplifierMessage(
            text: _currentResponse,
            isUser: false,
          ));
          _isGenerating = false;
          _currentResponse = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_SimplifierMessage(
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
        _messages.add(_SimplifierMessage(
          text: _currentResponse,
          isUser: false,
        ));
      }
      _isGenerating = false;
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

class _SimplifierMessage {
  final String text;
  final bool isUser;

  const _SimplifierMessage({required this.text, required this.isUser});
}
