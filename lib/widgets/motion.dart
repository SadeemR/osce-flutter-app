import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// Fades a widget in while it rises into place. Use [delay] to stagger lists.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final bool animate;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.offset = 14,
    this.animate = true,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AppMotion.enter);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _c.value = 1;
    } else if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _t.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Shrinks its child slightly while pressed, so taps feel physical.
/// Uses a Listener, so the child's own onTap still works.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;

  const Pressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled && v) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A progress bar that fills from 0 to [value] (0–1) after [delay].
class AnimatedBar extends StatefulWidget {
  final double value;
  final Color color;
  final Duration delay;
  final double height;

  const AnimatedBar({
    super.key,
    required this.value,
    required this.color,
    this.delay = Duration.zero,
    this.height = 6,
  });

  @override
  State<AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<AnimatedBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _t =
      CurvedAnimation(parent: _c, curve: AppMotion.enter);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.height),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            const Positioned.fill(
                child: ColoredBox(color: AppColors.surfaceRaised)),
            AnimatedBuilder(
              animation: _t,
              builder: (_, __) => FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor:
                    _reduceMotion(context) ? target : target * _t.value,
                child: ColoredBox(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gently pulses (scale + opacity) forever. Good for "live" dots and loaders.
class Pulse extends StatefulWidget {
  final Widget child;
  final Duration period;

  const Pulse({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Opacity(
          opacity: 0.55 + 0.45 * t,
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
