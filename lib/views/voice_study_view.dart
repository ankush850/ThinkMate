import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/ai_tutor_service.dart';
import '../services/document_service.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';
import '../widgets/model_loader_widget.dart';

class VoiceStudyView extends StatefulWidget {
  final DocumentData document;

  const VoiceStudyView({super.key, required this.document});

  @override
  State<VoiceStudyView> createState() => _VoiceStudyViewState();
}

class _VoiceStudyViewState extends State<VoiceStudyView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isGenerating = false;
  bool _isSpeaking = false;
  bool _useTextInput = false;
  bool _isContinuousMode = true; // Added continuous mode tracking
  String _currentResponse = '';
  LLMStreamingResult? _streamingResult;
  String? _recordingPath;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    _streamingResult?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: Text(
          widget.document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _useTextInput ? Icons.mic_rounded : Icons.keyboard_rounded,
              color: AppColors.accentPink,
            ),
            onPressed: () => setState(() {
              _useTextInput = !_useTextInput;
              // If we switch to voice, it should be continuous by default
              _isContinuousMode = !_useTextInput;
            }),
            tooltip: _useTextInput ? 'Switch to voice' : 'Switch to text',
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() => _messages.clear()),
              tooltip: 'New conversation',
            ),
        ],
      ),
      body: Consumer<ModelService>(
        builder: (context, modelService, child) {
          // Check which models are needed
          if (!modelService.isLLMLoaded) {
            return ModelLoaderWidget(
              title: 'LLM Model Required',
              subtitle: 'Download the AI model for interactive study',
              icon: Icons.mic_rounded,
              accentColor: AppColors.accentPink,
              isDownloading: modelService.isLLMDownloading,
              isLoading: modelService.isLLMLoading,
              progress: modelService.llmDownloadProgress,
              onLoad: () => modelService.downloadAndLoadLLM(),
            );
          }

          return Column(
            children: [
              // Document context badge
              _buildDocumentBadge(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(),
              ),
              if (_useTextInput)
                _buildTextInputArea()
              else
                _buildVoiceInputArea(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentBadge() {
    return Container(
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
          const Icon(Icons.picture_as_pdf_rounded,
              size: 14, color: AppColors.accentCyan),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Studying: ${widget.document.title}',
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentPink.withOpacity(0.15),
                    AppColors.accentViolet.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                size: 48,
                color: AppColors.accentPink,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 2000.ms,
                ),
            const SizedBox(height: 24),
            Text(
              'Study by Talking',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              _useTextInput
                  ? 'Type a question about your study material\nand the AI will explain it to you.'
                  : 'Tap the mic to ask a question about\nyour study material. The AI will answer\nand keep listening for your next question.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Summarize the main topics'),
                _buildSuggestionChip('Explain the key concepts'),
                _buildSuggestionChip('What is the most important point?'),
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
      side: BorderSide(color: AppColors.accentPink.withOpacity(0.3)),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary,
          ),
      onPressed: () {
        if (_useTextInput) {
          _textController.text = text;
          _sendTextMessage();
        } else {
          _processQuery(text);
        }
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
            child: const Icon(Icons.person_rounded,
                color: AppColors.textSecondary, size: 18),
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
                colors: [AppColors.accentPink, AppColors.accentViolet],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.psychology_rounded,
                color: Colors.white, size: 18),
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
                border: Border.all(color: AppColors.textMuted.withOpacity(0.1)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: AppColors.textMuted.withOpacity(0.1)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isTranscribing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Transcribing...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.accentCyan,
                      ),
                ),
              ),
            if (_isSpeaking)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.volume_up_rounded,
                        color: AppColors.accentPink, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'AI is speaking...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accentPink,
                          ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cancel recording button
                if (_isRecording)
                  Container(
                    margin: const EdgeInsets.only(right: 24),
                    child: GestureDetector(
                      onTap: () => _stopRecording(cancelled: true),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),

                // Stop speaking/generating button
                if (_isSpeaking || _isGenerating)
                  Container(
                    margin: const EdgeInsets.only(right: 24),
                    child: GestureDetector(
                      onTap: () {
                        if (_isSpeaking) _stopSpeaking();
                        if (_isGenerating) _stopGeneration();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.stop_rounded,
                            color: AppColors.error),
                      ),
                    ),
                  ),

                // Main mic button
                GestureDetector(
                  onTap: _isGenerating || _isTranscribing
                      ? null
                      : (_isRecording ? _stopRecording : _startRecording),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _isRecording ? 80 : 72,
                    height: _isRecording ? 80 : 72,
                    decoration: BoxDecoration(
                      gradient: _isRecording
                          ? const LinearGradient(
                              colors: [AppColors.error, Color(0xFFDC2626)],
                            )
                          : (_isGenerating || _isTranscribing
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    AppColors.accentPink,
                                    Color(0xFFDB2777)
                                  ],
                                )),
                      color: _isGenerating || _isTranscribing
                          ? AppColors.surfaceElevated
                          : null,
                      shape: BoxShape.circle,
                      boxShadow: _isRecording
                          ? [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.5),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.accentPink.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop_rounded
                          : (_isGenerating
                              ? Icons.hourglass_top_rounded
                              : Icons.mic_rounded),
                      color: _isGenerating || _isTranscribing
                          ? AppColors.textMuted
                          : Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording
                  ? 'Recording... Tap to process or \u2715 to cancel'
                  : (_isGenerating ? 'AI is thinking...' : 'Tap to speak'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputArea() {
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
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Ask about your study material...',
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
                onSubmitted: (_) => _sendTextMessage(),
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
                      onPressed: _sendTextMessage,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  // ── Voice Logic ──

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return;

      final tempDir = await getTemporaryDirectory();
      _recordingPath =
          '${tempDir.path}/voice_study_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Recording error: $e');
    }
  }

  Future<void> _stopRecording({bool cancelled = false}) async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        if (!cancelled) _isTranscribing = true;
      });

      if (path != null && !cancelled) {
        // Transcribe using RunAnywhere STT
        final modelService = context.read<ModelService>();
        if (!modelService.isSTTLoaded) {
          await modelService.downloadAndLoadSTT();
        }

        if (modelService.isSTTLoaded) {
          // Read WAV file as bytes
          final audioBytes = await File(path).readAsBytes();
          final transcribed = await RunAnywhere.transcribe(audioBytes);
          if (transcribed.isNotEmpty && mounted) {
            setState(() => _isTranscribing = false);
            _processQuery(transcribed);
          } else {
            setState(() => _isTranscribing = false);
            // If empty transcription and continuous mode is on, just stop.
          }
        } else {
          setState(() => _isTranscribing = false);
        }

        // Clean up recording file
        try {
          await File(path).delete();
        } catch (_) {}
      } else {
        setState(() => _isTranscribing = false);
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
      setState(() {
        _isRecording = false;
        _isTranscribing = false;
      });
    }
  }

  // ── Shared Logic ──

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;
    _textController.clear();
    _processQuery(text);
  }

  Future<void> _processQuery(String query) async {
    setState(() {
      _messages.add(_ChatMessage(text: query, isUser: true));
      _isGenerating = true;
      _currentResponse = '';
    });
    _scrollToBottom();

    try {
      // Retrieve relevant document chunk
      final docService = context.read<DocumentService>();
      final chunk =
          docService.findRelevantChunk(query, document: widget.document);

      // Build conversation history
      final historyBuffer = StringBuffer();
      final recent = _messages.length > 6
          ? _messages.sublist(_messages.length - 6)
          : _messages;
      for (final msg
          in recent.where((m) => _messages.indexOf(m) < _messages.length - 1)) {
        historyBuffer
            .writeln(msg.isUser ? 'Student: ${msg.text}' : 'AI: ${msg.text}');
      }

      // Generate response
      _streamingResult = await AiTutorService.conversationFromDocument(
        userMessage: query,
        documentChunk: chunk,
        conversationHistory:
            historyBuffer.isNotEmpty ? historyBuffer.toString() : null,
      );

      await for (final token in _streamingResult!.stream) {
        if (!mounted) return;
        setState(() {
          _currentResponse += token;
        });
        _scrollToBottom();
      }

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: _currentResponse, isUser: false));
          _isGenerating = false;
        });

        // Speak the response using TTS
        _speakResponse(_currentResponse);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
          ));
          _isGenerating = false;
          _currentResponse = '';
        });
      }
    }
  }

  Future<void> _speakResponse(String text) async {
    try {
      final modelService = context.read<ModelService>();
      if (!modelService.isTTSLoaded) {
        await modelService.downloadAndLoadTTS();
      }

      if (modelService.isTTSLoaded) {
        setState(() => _isSpeaking = true);

        // Clean text for TTS
        final cleanText = text
            .replaceAll(RegExp(r'\*+'), '')
            .replaceAll(RegExp(r'#{1,6}\s'), '')
            .replaceAll(RegExp(r'\n{2,}'), '. ');

        final result = await RunAnywhere.synthesize(cleanText);

        if (result.samples.isNotEmpty && mounted) {
          // Convert Float32 PCM samples to 16-bit WAV and write to temp file
          final wavBytes = _float32ToWav(result.samples, result.sampleRate);
          final tempDir = await getTemporaryDirectory();
          final wavFile = File(
              '${tempDir.path}/tts_output_${DateTime.now().millisecondsSinceEpoch}.wav');
          await wavFile.writeAsBytes(wavBytes);

          await _audioPlayer.play(DeviceFileSource(wavFile.path));
          _audioPlayer.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() => _isSpeaking = false);
              if (_isContinuousMode && !_useTextInput) {
                // Automatically start listening again
                _startRecording();
              }
            }
            // Clean up temp WAV file
            wavFile.delete().catchError((_) => wavFile);
          });
        } else {
          if (mounted) setState(() => _isSpeaking = false);
        }
      }
    } catch (e) {
      debugPrint('TTS error: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  /// Convert Float32 PCM samples to WAV file bytes
  Uint8List _float32ToWav(Float32List samples, int sampleRate) {
    final numSamples = samples.length;
    final byteRate = sampleRate * 2; // 16-bit mono
    final dataSize = numSamples * 2;
    final fileSize = 36 + dataSize;

    final buffer = ByteData(44 + dataSize);
    int offset = 0;

    // RIFF header
    buffer.setUint8(offset++, 0x52); // R
    buffer.setUint8(offset++, 0x49); // I
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint8(offset++, 0x46); // F
    buffer.setUint32(offset, fileSize, Endian.little);
    offset += 4;
    buffer.setUint8(offset++, 0x57); // W
    buffer.setUint8(offset++, 0x41); // A
    buffer.setUint8(offset++, 0x56); // V
    buffer.setUint8(offset++, 0x45); // E

    // fmt subchunk
    buffer.setUint8(offset++, 0x66); // f
    buffer.setUint8(offset++, 0x6D); // m
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x20); // space
    buffer.setUint32(offset, 16, Endian.little);
    offset += 4; // subchunk size
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2; // PCM format
    buffer.setUint16(offset, 1, Endian.little);
    offset += 2; // mono
    buffer.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    buffer.setUint32(offset, byteRate, Endian.little);
    offset += 4;
    buffer.setUint16(offset, 2, Endian.little);
    offset += 2; // block align
    buffer.setUint16(offset, 16, Endian.little);
    offset += 2; // bits per sample

    // data subchunk
    buffer.setUint8(offset++, 0x64); // d
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint8(offset++, 0x74); // t
    buffer.setUint8(offset++, 0x61); // a
    buffer.setUint32(offset, dataSize, Endian.little);
    offset += 4;

    // Write samples as 16-bit PCM
    for (int i = 0; i < numSamples; i++) {
      final sample = (samples[i] * 32767).clamp(-32768, 32767).toInt();
      buffer.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void _stopSpeaking() {
    _audioPlayer.stop();
    setState(() => _isSpeaking = false);
    // Explicitly stopping kills continuous mode for this turn
  }

  void _stopGeneration() {
    _streamingResult?.cancel();
    setState(() {
      if (_currentResponse.isNotEmpty) {
        _messages.add(_ChatMessage(text: _currentResponse, isUser: false));
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

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}
