import 'dart:math' as math;

import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({
    super.key,
    this.starCount = 90,
    this.meteorCount = 6,
  });

  final int starCount;
  final int meteorCount;

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random(42);
  List<_Star> _stars = [];
  List<_Meteor> _meteors = [];
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ensureParticles(Size size) {
    if (size == _size && _stars.isNotEmpty) {
      return;
    }
    _size = size;
    _stars = List.generate(widget.starCount, (_) {
      return _Star(
        offset: Offset(_random.nextDouble() * size.width,
            _random.nextDouble() * size.height),
        radius: _random.nextDouble() * 1.3 + 0.6,
        twinkleSpeed: _random.nextDouble() * 1.6 + 0.4,
        baseOpacity: _random.nextDouble() * 0.5 + 0.2,
        phase: _random.nextDouble(),
      );
    });
    _meteors = List.generate(widget.meteorCount, (_) {
      final start = Offset(
        _random.nextDouble() * size.width * 1.2 - size.width * 0.2,
        _random.nextDouble() * size.height * 0.6 - size.height * 0.2,
      );
      return _Meteor(
        start: start,
        angle: (20 + _random.nextDouble() * 18) * (math.pi / 180),
        length: _random.nextDouble() * 140 + 120,
        speed: _random.nextDouble() * 0.7 + 0.35,
        phase: _random.nextDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureParticles(size);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: size,
              painter: _ParticlePainter(
                progress: _controller.value,
                stars: _stars,
                meteors: _meteors,
              ),
            );
          },
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.stars,
    required this.meteors,
  });

  final double progress;
  final List<_Star> stars;
  final List<_Meteor> meteors;

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (final star in stars) {
      final twinkle = 0.5 + 0.5 * math.sin(
        (progress * 2 * math.pi * star.twinkleSpeed) + star.phase * 2 * math.pi,
      );
      starPaint.color = Colors.white.withOpacity(
        (star.baseOpacity + twinkle * 0.35).clamp(0.0, 1.0),
      );
      canvas.drawCircle(star.offset, star.radius, starPaint);
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final meteor in meteors) {
      final direction = Offset(math.cos(meteor.angle), math.sin(meteor.angle));
      final travel = size.longestSide * 1.4;
      final value = (progress * meteor.speed + meteor.phase) % 1.0;
      final head = meteor.start + direction * (travel * value);
      final tail = head - direction * meteor.length;

      glowPaint
        ..strokeWidth = 2.4
        ..color = const Color(0xFFFCE9B6).withOpacity(0.55);
      canvas.drawLine(tail, head, glowPaint);

      glowPaint
        ..strokeWidth = 6
        ..color = const Color(0xFFFFDFA2).withOpacity(0.25);
      canvas.drawLine(tail, head, glowPaint);

      final headPaint = Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(head, 3.6, headPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Star {
  _Star({
    required this.offset,
    required this.radius,
    required this.twinkleSpeed,
    required this.baseOpacity,
    required this.phase,
  });

  final Offset offset;
  final double radius;
  final double twinkleSpeed;
  final double baseOpacity;
  final double phase;
}

class _Meteor {
  _Meteor({
    required this.start,
    required this.angle,
    required this.length,
    required this.speed,
    required this.phase,
  });

  final Offset start;
  final double angle;
  final double length;
  final double speed;
  final double phase;
}
