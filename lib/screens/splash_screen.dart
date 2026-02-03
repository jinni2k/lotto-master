import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../widgets/animated_lotto_ball.dart';
import '../widgets/lotto_widgets.dart';
import '../widgets/particle_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF09080B),
                  Color(0xFF141015),
                  Color(0xFF0C0B10),
                ],
              ),
            ),
          ),
          const Positioned.fill(
            child: ParticleBackground(),
          ),
          Positioned(
            top: -120,
            left: -80,
            child: _GlowOrb(
              size: 280,
              colors: [Color(0xFF7A5A14), Color(0x00D8B24C)],
            ),
          ),
          Positioned(
            bottom: -160,
            right: -80,
            child: _GlowOrb(
              size: 320,
              colors: [Color(0xFF3F2A0D), Color(0x00D8B24C)],
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeInDown(
                      duration: const Duration(milliseconds: 900),
                      child: Shimmer.fromColors(
                        baseColor: scheme.primary.withOpacity(0.85),
                        highlightColor: Colors.white.withOpacity(0.9),
                        child: Text(
                          'LOTTO MASTER',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                letterSpacing: 4,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                                shadows: [
                                  Shadow(
                                    color: scheme.primary.withOpacity(0.5),
                                    blurRadius: 16,
                                  ),
                                ],
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeIn(
                      duration: const Duration(milliseconds: 1200),
                      child: GlassCard(
                        borderRadius: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        tintColor: const Color(0xFF141219),
                        child: Column(
                          children: [
                            const AnimatedLottoBall(
                              size: 150,
                              number: 7,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Fortune. Precision. Luxury.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.85),
                                    letterSpacing: 1.2,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Premium analytics for every draw',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.6),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeInUp(
                      duration: const Duration(milliseconds: 1200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: scheme.primary.withOpacity(0.45),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withOpacity(0.2),
                              scheme.secondary.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withOpacity(0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          'Entering the vault',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                letterSpacing: 1.1,
                                color: scheme.onSurface.withOpacity(0.8),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
