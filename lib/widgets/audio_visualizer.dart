import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AudioVisualizer extends StatefulWidget {
  final double level;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.level,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = List.generate(15, (_) => 0.3);
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars);
    _controller.repeat();
  }

  void _updateBars() {
    if (!mounted) return;

    setState(() {
      for (int i = 0; i < _barHeights.length; i++) {
        // Create smooth wave-like animation based on audio level
        final baseHeight = widget.level * 0.8;
        final variation = _random.nextDouble() * 0.4 - 0.2;
        final waveOffset =
            math.sin((DateTime.now().millisecondsSinceEpoch / 200) + i * 0.5);

        _barHeights[i] =
            (baseHeight + variation + waveOffset * 0.15 * widget.level)
                .clamp(0.15, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accentViolet;

    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barHeights.length, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 6,
            height: 80 * _barHeights[index],
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  color,
                  color.withOpacity(0.6),
                ],
              ),
              boxShadow: widget.level > 0.3
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

/// A simpler waveform visualizer for playback
class WaveformVisualizer extends StatelessWidget {
  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const WaveformVisualizer({
    super.key,
    required this.amplitudes,
    this.progress = 0.0,
    this.activeColor = AppColors.accentPink,
    this.inactiveColor = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final progressIndex = (progress * amplitudes.length).floor();

    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(amplitudes.length, (index) {
          final isActive = index <= progressIndex;
          return Container(
            width: 4,
            height: 60 * amplitudes[index].clamp(0.1, 1.0),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isActive ? activeColor : inactiveColor.withOpacity(0.3),
            ),
          );
        }),
      ),
    );
  }
}
