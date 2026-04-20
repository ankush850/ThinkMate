import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../services/model_service.dart';
import '../theme/app_theme.dart';
import 'home_view.dart';
import 'model_setup_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  String _statusMessage = 'Initializing ThinkMate...';

  @override
  void initState() {
    super.initState();
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    // Small delay to show the splash screen
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final modelService = context.read<ModelService>();

    setState(() {
      _statusMessage = 'Checking AI models...';
    });

    final allDownloaded = await modelService.areAllModelsDownloaded();

    if (!mounted) return;

    if (!allDownloaded) {
      // Missing models, go to setup flow
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ModelSetupView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      // Models exist, load them
      setState(() {
        _statusMessage = 'Loading models into memory...';
      });

      try {
        await modelService.loadAllModels();
        if (!mounted) return;

        // Proceed to Home
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeView(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Error loading models: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.accentViolet],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentCyan.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 64,
                color: Colors.white,
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              'ThinkMate',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              color: AppColors.accentCyan,
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
