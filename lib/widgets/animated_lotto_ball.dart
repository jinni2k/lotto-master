import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedLottoBall extends StatefulWidget {
  const AnimatedLottoBall({
    super.key,
    this.size = 140,
    this.number,
    this.glowColor,
    this.animate = true,
  });

  final double size;
  final int? number;
  final Color? glowColor;
  final bool animate;

  @override
  State<AnimatedLottoBall> createState() => _AnimatedLottoBallState();
}

class _AnimatedLottoBallState extends State<AnimatedLottoBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _tilt;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rotation = Tween<double>(begin: 0, end: 2 * math.pi)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    _tilt = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _pulse = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glow = widget.glowColor ?? scheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(_rotation.value)
          ..rotateX(_tilt.value);
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: Transform.scale(
            scale: _pulse.value,
            child: child,
          ),
        );
      },
      child: _LottoBallFace(
        size: widget.size,
        number: widget.number,
        glowColor: glow,
      ),
    );
  }
}

class _LottoBallFace extends StatelessWidget {
  const _LottoBallFace({
    required this.size,
    required this.number,
    required this.glowColor,
  });

  final double size;
  final int? number;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.2, -0.3),
          radius: 0.9,
          colors: [
            scheme.secondary.withOpacity(0.95),
            scheme.primary.withOpacity(0.95),
            const Color(0xFF2A210F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.45),
            blurRadius: 28,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: glowColor.withOpacity(0.15),
            blurRadius: 50,
            spreadRadius: 16,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.5, -0.6),
                  radius: 0.7,
                  colors: [
                    Colors.white.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.16,
            left: size * 0.18,
            child: Container(
              width: size * 0.24,
              height: size * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.3),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          if (number != null)
            Center(
              child: Container(
                width: size * 0.46,
                height: size * 0.46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onPrimary.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  number.toString(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
