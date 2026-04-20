import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runanywhere/runanywhere.dart';
import 'package:runanywhere_llamacpp/runanywhere_llamacpp.dart';
import 'package:runanywhere_onnx/runanywhere_onnx.dart';

import 'services/model_service.dart';
import 'services/progress_service.dart';
import 'services/document_service.dart';
import 'theme/app_theme.dart';
import 'views/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the RunAnywhere SDK
  await RunAnywhere.initialize();

  // Register backends
  await LlamaCpp.register();
  await Onnx.register();

  // Register models
  ModelService.registerDefaultModels();

  // Initialize services
  final progressService = ProgressService();
  await progressService.init();

  final documentService = DocumentService();
  await documentService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModelService()),
        ChangeNotifierProvider.value(value: progressService),
        ChangeNotifierProvider.value(value: documentService),
      ],
      child: const ThinkMateApp(),
    ),
  );
}

class ThinkMateApp extends StatelessWidget {
  const ThinkMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThinkMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashView(),
    );
  }
}
