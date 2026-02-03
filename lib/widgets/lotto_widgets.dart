import 'dart:ui';

import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
              ),
        ),
      ],
    );
  }
}

class NumberBall extends StatefulWidget {
  const NumberBall({
    super.key,
    required this.number,
    required this.isBonus,
    this.animate = true,
    this.delay = Duration.zero,
  });

  final int number;
  final bool isBonus;
  final bool animate;
  final Duration delay;

  @override
  State<NumberBall> createState() => _NumberBallState();
}

class _NumberBallState extends State<NumberBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rotation;
  late final Animation<double> _lift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _rotation = Tween<double>(begin: -0.9, end: 0).animate(curve);
    _lift = Tween<double>(begin: -12, end: 0).animate(curve);

    if (widget.animate) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1;
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
    final baseColor = widget.isBonus ? scheme.secondary : scheme.primary;
    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _lift.value),
            child: Transform.rotate(
              angle: _rotation.value,
              child: child,
            ),
          );
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: baseColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: baseColor.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.number.toString(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.tintColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tintColor ?? scheme.surface).withOpacity(0.55),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: scheme.primary.withOpacity(0.25)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (tintColor ?? scheme.surface).withOpacity(0.75),
                scheme.surface.withOpacity(0.35),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.18),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
