import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:read_pdf_text/read_pdf_text.dart';

/// Data model for a processed document
class DocumentData {
  final String id;
  final String title;
  final List<String> chunks;
  final DateTime uploadDate;
  final int pageCount;
  final int totalWords;

  const DocumentData({
    required this.id,
    required this.title,
    required this.chunks,
    required this.uploadDate,
    required this.pageCount,
    required this.totalWords,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'chunks': chunks,
        'uploadDate': uploadDate.toIso8601String(),
        'pageCount': pageCount,
        'totalWords': totalWords,
      };

  factory DocumentData.fromJson(Map<String, dynamic> json) => DocumentData(
        id: json['id'] as String,
        title: json['title'] as String,
        chunks: (json['chunks'] as List).cast<String>(),
        uploadDate: DateTime.parse(json['uploadDate'] as String),
        pageCount: json['pageCount'] as int,
        totalWords: json['totalWords'] as int,
      );
}

/// Service for PDF upload, text extraction, chunking, storage, and retrieval
class DocumentService extends ChangeNotifier {
  List<DocumentData> _documents = [];
  DocumentData? _activeDocument;
  bool _isProcessing = false;
  String _processingStatus = '';

  List<DocumentData> get documents => _documents;
  DocumentData? get activeDocument => _activeDocument;
  bool get isProcessing => _isProcessing;
  String get processingStatus => _processingStatus;

  /// Initialize — load saved documents from disk
  Future<void> init() async {
    await _loadDocumentsFromDisk();
    notifyListeners();
  }

  /// Pick a PDF and process it
  Future<DocumentData?> pickAndProcessPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.path == null) return null;

      _isProcessing = true;
      _processingStatus = 'Extracting text from PDF...';
      notifyListeners();

      // Extract text
      final text = await _extractText(file.path!);

      if (text.trim().isEmpty) {
        _isProcessing = false;
        _processingStatus = '';
        notifyListeners();
        return null;
      }

      _processingStatus = 'Chunking text...';
      notifyListeners();

      // Chunk the text
      final chunks = _chunkText(text);

      // Count pages
      final pageCount = await _getPageCount(file.path!);

      // Create document
      final doc = DocumentData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: file.name.replaceAll('.pdf', ''),
        chunks: chunks,
        uploadDate: DateTime.now(),
        pageCount: pageCount,
        totalWords: text.split(RegExp(r'\s+')).length,
      );

      _processingStatus = 'Saving document...';
      notifyListeners();

      // Save to disk
      _documents.insert(0, doc);
      await _saveDocumentsToDisk();

      _isProcessing = false;
      _processingStatus = '';
      _activeDocument = doc;
      notifyListeners();

      return doc;
    } catch (e) {
      debugPrint('PDF processing error: $e');
      _isProcessing = false;
      _processingStatus = '';
      notifyListeners();
      return null;
    }
  }

  /// Set the active document for AI interactions
  void setActiveDocument(DocumentData doc) {
    _activeDocument = doc;
    notifyListeners();
  }

  /// Delete a document
  Future<void> deleteDocument(String id) async {
    _documents.removeWhere((d) => d.id == id);
    if (_activeDocument?.id == id) {
      _activeDocument = null;
    }
    await _saveDocumentsToDisk();
    notifyListeners();
  }

  /// Clear all documents and history
  Future<void> clearAllDocuments() async {
    _documents.clear();
    _activeDocument = null;
    await _saveDocumentsToDisk();
    notifyListeners();
  }

  /// Find the most relevant chunk for a query using keyword overlap
  String findRelevantChunk(String query, {DocumentData? document}) {
    final doc = document ?? _activeDocument;
    if (doc == null || doc.chunks.isEmpty) return '';

    final queryWords = _tokenize(query.toLowerCase());
    if (queryWords.isEmpty) return doc.chunks.first;

    double bestScore = -1;
    String bestChunk = doc.chunks.first;

    for (final chunk in doc.chunks) {
      final chunkWords = _tokenize(chunk.toLowerCase());
      if (chunkWords.isEmpty) continue;

      // Score by keyword overlap (Jaccard-like)
      int matchCount = 0;
      for (final qw in queryWords) {
        if (qw.length < 3) continue; // Skip very short words
        for (final cw in chunkWords) {
          if (cw.contains(qw) || qw.contains(cw)) {
            matchCount++;
            break;
          }
        }
      }

      final score = matchCount / max(1, queryWords.length);
      if (score > bestScore) {
        bestScore = score;
        bestChunk = chunk;
      }
    }

    return bestChunk;
  }

  /// Get a random chunk (useful for quiz generation)
  String getRandomChunk({DocumentData? document}) {
    final doc = document ?? _activeDocument;
    if (doc == null || doc.chunks.isEmpty) return '';
    final rng = Random();
    return doc.chunks[rng.nextInt(doc.chunks.length)];
  }

  // ── Private helpers ──

  Future<String> _extractText(String filePath) async {
    try {
      final pages = await ReadPdfText.getPDFtextPaginated(filePath);
      return pages.join('\n\n');
    } catch (e) {
      debugPrint('Text extraction error: $e');
      return '';
    }
  }

  Future<int> _getPageCount(String filePath) async {
    try {
      final pages = await ReadPdfText.getPDFtextPaginated(filePath);
      return pages.length;
    } catch (_) {
      return 0;
    }
  }

  List<String> _chunkText(String text,
      {int chunkSize = 400, int overlap = 50}) {
    final words = text.split(RegExp(r'\s+'));
    if (words.length <= chunkSize) return [text.trim()];

    final chunks = <String>[];
    int start = 0;

    while (start < words.length) {
      final end = min(start + chunkSize, words.length);
      final chunk = words.sublist(start, end).join(' ').trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }
      start += chunkSize - overlap;
    }

    return chunks;
  }

  Set<String> _tokenize(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();
  }

  Future<Directory> _getStorageDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final docsDir = Directory('${appDir.path}/thinkmate_docs');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  Future<void> _saveDocumentsToDisk() async {
    try {
      final dir = await _getStorageDir();
      final file = File('${dir.path}/documents.json');
      final json = _documents.map((d) => d.toJson()).toList();
      await file.writeAsString(jsonEncode(json));
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  Future<void> _loadDocumentsFromDisk() async {
    try {
      final dir = await _getStorageDir();
      final file = File('${dir.path}/documents.json');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = jsonDecode(raw) as List;
        _documents = list
            .map((j) => DocumentData.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Load error: $e');
    }
  }
}
