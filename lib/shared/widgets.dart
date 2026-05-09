import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Glassmorphic card widget used throughout the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceCard.withValues(alpha: 0.8),
            AppColors.surface.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}

/// Gradient button used for primary CTAs.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double? width;
  final bool loading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.loading = false,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.loading;

    return Opacity(
      opacity: isDisabled ? 0.7 : 1,
      child: IgnorePointer(
        ignoring: isDisabled,
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onPressed();
          },
          onTapCancel: () => _controller.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: widget.loading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated floating particles background.
class ParticlesBackground extends StatefulWidget {
  final Widget child;

  const ParticlesBackground({super.key, required this.child});

  @override
  State<ParticlesBackground> createState() => _ParticlesBackgroundState();
}

class _ParticlesBackgroundState extends State<ParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient orbs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _OrbPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;

  _OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Primary orb - top right
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.8 + 30 * (progress * 2 * 3.14159).abs(),
            size.height * 0.2 + 20 * ((progress * 2 * 3.14159) + 1).abs(),
          ),
          radius: 200,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.8 + 30 * _sin(progress),
        size.height * 0.2 + 20 * _cos(progress),
      ),
      200,
      paint1,
    );

    // Accent orb - bottom left
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.1),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(
            size.width * 0.2 + 40 * _cos(progress * 0.7),
            size.height * 0.7 + 30 * _sin(progress * 0.7),
          ),
          radius: 180,
        ),
      );

    canvas.drawCircle(
      Offset(
        size.width * 0.2 + 40 * _cos(progress * 0.7),
        size.height * 0.7 + 30 * _sin(progress * 0.7),
      ),
      180,
      paint2,
    );
  }

  double _sin(double t) => (t * 2 * 3.14159).abs() % 1.0 * 2 - 1;
  double _cos(double t) => ((t + 0.25) * 2 * 3.14159).abs() % 1.0 * 2 - 1;

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
