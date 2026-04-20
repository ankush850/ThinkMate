import 'package:flutter/foundation.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

/// Service for managing AI models
class ModelService extends ChangeNotifier {
  // Model IDs - using officially supported models from RunanywhereAI/sherpa-onnx
  static const String llmModelId = 'Llama-3.2-1B-Instruct-Q4-v1';
  static const String sttModelId = 'sherpa-onnx-whisper-tiny.en';
  static const String ttsModelId = 'vits-piper-en_US-lessac-medium';

  // Download state
  bool _isLLMDownloading = false;
  bool _isSTTDownloading = false;
  bool _isTTSDownloading = false;

  double _llmDownloadProgress = 0.0;
  double _sttDownloadProgress = 0.0;
  double _ttsDownloadProgress = 0.0;

  // Load state
  bool _isLLMLoading = false;
  bool _isSTTLoading = false;
  bool _isTTSLoading = false;

  // Getters
  bool get isLLMDownloading => _isLLMDownloading;
  bool get isSTTDownloading => _isSTTDownloading;
  bool get isTTSDownloading => _isTTSDownloading;

  double get llmDownloadProgress => _llmDownloadProgress;
  double get sttDownloadProgress => _sttDownloadProgress;
  double get ttsDownloadProgress => _ttsDownloadProgress;

  bool get isLLMLoading => _isLLMLoading;
  bool get isSTTLoading => _isSTTLoading;
  bool get isTTSLoading => _isTTSLoading;

  bool get isLLMLoaded => RunAnywhere.isModelLoaded;
  bool get isSTTLoaded => RunAnywhere.isSTTModelLoaded;
  bool get isTTSLoaded => RunAnywhere.isTTSVoiceLoaded;

  bool get isVoiceAgentReady => RunAnywhere.isVoiceAgentReady;

  /// Register default models with the SDK
  /// Using officially supported models from RunanywhereAI/sherpa-onnx for compatibility
  static void registerDefaultModels() {
    // LLM Model - Llama 3.2 1B Instruct (Stable Q4_K_M)
    LlamaCpp.addModel(
      id: llmModelId,
      name: 'Llama 3.2 1B Instruct',
      url:
          'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      memoryRequirement: 800000000, // ~800MB
    );

    // STT Model - Whisper Tiny English (fast transcription)
    // Using tar.gz format from RunanywhereAI for fast native extraction
    Onnx.addModel(
      id: sttModelId,
      name: 'Sherpa Whisper Tiny (ONNX)',
      url:
          'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/sherpa-onnx-whisper-tiny.en.tar.gz',
      modality: ModelCategory.speechRecognition,
    );

    // TTS Model - Piper TTS (US English - Medium quality)
    // Using officially supported Piper model for reliable TTS
    Onnx.addModel(
      id: ttsModelId,
      name: 'Piper TTS (US English - Medium)',
      url:
          'https://github.com/RunanywhereAI/sherpa-onnx/releases/download/runanywhere-models-v1/vits-piper-en_US-lessac-medium.tar.gz',
      modality: ModelCategory.speechSynthesis,
    );
  }

  /// Check if a model is downloaded
  Future<bool> isModelDownloaded(String modelId) async {
    final models = await RunAnywhere.availableModels();
    final model = models.where((m) => m.id == modelId).firstOrNull;
    return model?.localPath != null;
  }

  /// Download and load LLM model
  Future<void> downloadAndLoadLLM() async {
    if (_isLLMDownloading || _isLLMLoading) return;

    final isDownloaded = await isModelDownloaded(llmModelId);

    if (!isDownloaded) {
      _isLLMDownloading = true;
      _llmDownloadProgress = 0.0;
      notifyListeners();

      try {
        await for (final progress in RunAnywhere.downloadModel(llmModelId)) {
          _llmDownloadProgress = progress.percentage;
          notifyListeners();

          if (progress.state.isCompleted || progress.state.isFailed) {
            break;
          }
        }
      } catch (e) {
        print('LLM download error: $e');
      }

      _isLLMDownloading = false;
      notifyListeners();
    }

    // Load the model
    _isLLMLoading = true;
    notifyListeners();

    try {
      await RunAnywhere.loadModel(llmModelId);
    } catch (e) {
      print('LLM load error: $e');
    }

    _isLLMLoading = false;
    notifyListeners();
  }

  /// Download and load STT model
  Future<void> downloadAndLoadSTT() async {
    if (_isSTTDownloading || _isSTTLoading) return;

    final isDownloaded = await isModelDownloaded(sttModelId);

    if (!isDownloaded) {
      _isSTTDownloading = true;
      _sttDownloadProgress = 0.0;
      notifyListeners();

      try {
        await for (final progress in RunAnywhere.downloadModel(sttModelId)) {
          _sttDownloadProgress = progress.percentage;
          notifyListeners();

          if (progress.state.isCompleted || progress.state.isFailed) {
            break;
          }
        }
      } catch (e) {
        print('STT download error: $e');
      }

      _isSTTDownloading = false;
      notifyListeners();
    }

    // Load the model
    _isSTTLoading = true;
    notifyListeners();

    try {
      await RunAnywhere.loadSTTModel(sttModelId);
    } catch (e) {
      print('STT load error: $e');
    }

    _isSTTLoading = false;
    notifyListeners();
  }

  /// Download and load TTS model
  Future<void> downloadAndLoadTTS() async {
    if (_isTTSDownloading || _isTTSLoading) return;

    final isDownloaded = await isModelDownloaded(ttsModelId);

    if (!isDownloaded) {
      _isTTSDownloading = true;
      _ttsDownloadProgress = 0.0;
      notifyListeners();

      try {
        await for (final progress in RunAnywhere.downloadModel(ttsModelId)) {
          _ttsDownloadProgress = progress.percentage;
          notifyListeners();

          if (progress.state.isCompleted || progress.state.isFailed) {
            break;
          }
        }
      } catch (e) {
        print('TTS download error: $e');
      }

      _isTTSDownloading = false;
      notifyListeners();
    }

    // Load the model
    _isTTSLoading = true;
    notifyListeners();

    try {
      await RunAnywhere.loadTTSVoice(ttsModelId);
    } catch (e) {
      print('TTS load error: $e');
    }

    _isTTSLoading = false;
    notifyListeners();
  }

  /// Download and load all models for voice agent
  Future<void> downloadAndLoadAllModels() async {
    await Future.wait([
      downloadAndLoadLLM(),
      downloadAndLoadSTT(),
      downloadAndLoadTTS(),
    ]);
  }

  /// Check if all required models are downloaded
  Future<bool> areAllModelsDownloaded() async {
    final results = await Future.wait([
      isModelDownloaded(llmModelId),
      isModelDownloaded(sttModelId),
      isModelDownloaded(ttsModelId),
    ]);
    return results.every((isDownloaded) => isDownloaded);
  }

  /// Load all models into memory (assuming they are already downloaded)
  Future<void> loadAllModels() async {
    bool loadFailed = false;

    if (!isLLMLoaded) {
      _isLLMLoading = true;
      notifyListeners();
      try {
        await RunAnywhere.loadModel(llmModelId);
      } catch (e) {
        print('LLM load error: $e');
        loadFailed = true;
      }
      _isLLMLoading = false;
      notifyListeners();
    }

    if (!isSTTLoaded) {
      _isSTTLoading = true;
      notifyListeners();
      try {
        await RunAnywhere.loadSTTModel(sttModelId);
      } catch (e) {
        print('STT load error: $e');
        loadFailed = true;
      }
      _isSTTLoading = false;
      notifyListeners();
    }

    if (!isTTSLoaded) {
      _isTTSLoading = true;
      notifyListeners();
      try {
        await RunAnywhere.loadTTSVoice(ttsModelId);
      } catch (e) {
        print('TTS load error: $e');
        loadFailed = true;
      }
      _isTTSLoading = false;
      notifyListeners();
    }

    if (loadFailed) {
      throw Exception('Failed to load one or more models. Please check logs.');
    }
  }

  /// Unload all models
  Future<void> unloadAllModels() async {
    await RunAnywhere.unloadModel();
    await RunAnywhere.unloadSTTModel();
    await RunAnywhere.unloadTTSVoice();
    notifyListeners();
  }
}

extension DownloadProgressStateExt on DownloadProgressState {
  bool get isCompleted => this == DownloadProgressState.completed;
  bool get isFailed => this == DownloadProgressState.failed;
  bool get isCancelled => this == DownloadProgressState.cancelled;
}
