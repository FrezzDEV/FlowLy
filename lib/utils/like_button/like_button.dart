import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/like_button_cubit.dart';

class LikeButton extends StatefulWidget {
  final String name;
  final String fullname;
  final String username;
  final String track;
  final bool isIcon;
  final String cover;
  final String id;

  const LikeButton({
    super.key,
    required this.name,
    required this.fullname,
    required this.username,
    required this.track,
    required this.isIcon,
    required this.cover,
    required this.id,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particles = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void dispose() {
    _particles.dispose();
    super.dispose();
  }

  void _toggleLike(BuildContext context) {
    final cubit = BlocProvider.of<LikeButtonCubit>(context);
    final wasLiked = cubit.state.isLiked;
    cubit.like(
      track: widget.track,
      fullname: widget.fullname,
      cover: widget.cover,
      id: widget.id,
      name: widget.name,
      username: widget.username,
    );
    if (!wasLiked) {
      _particles.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LikeButtonCubit()..init(widget.name),
      child: BlocBuilder<LikeButtonCubit, LikeButtonState>(
        builder: (context, state) {
          final icon = Icon(
            state.isLiked ? CupertinoIcons.heart_solid : CupertinoIcons.heart,
            color: state.isLiked ? Colors.white : Colors.grey,
            size: widget.isIcon ? 24 : 30,
          );

          if (widget.isIcon) {
            return ListTile(
              minLeadingWidth: 30,
              contentPadding: const EdgeInsets.symmetric(horizontal: 30),
              onTap: () => _toggleLike(context),
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  if (state.isLiked)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _particles,
                          builder: (_, __) => CustomPaint(
                            painter: _ParticlePainter(_particles.value),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                state.isLiked ? 'liked' : 'like',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 20, color: Colors.white),
              ),
            );
          }

          return InkWell(
            onTap: () => _toggleLike(context),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                icon,
                if (state.isLiked)
                  IgnorePointer(
                    child: SizedBox(
                      width: 62,
                      height: 62,
                      child: AnimatedBuilder(
                        animation: _particles,
                        builder: (_, __) => CustomPaint(
                          painter: _ParticlePainter(_particles.value),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..color = Colors.white;
    const count = 10;

    for (var i = 0; i < count; i++) {
      final angle = (math.pi * 2 * i / count) - math.pi / 2;
      final distance = 7 + progress * 22;
      final opacity = (1 - progress) * 0.9;
      paint.color = Colors.white.withValues(alpha: opacity);
      final radius = 1.2 + (1 - progress) * 1.2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(point, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
