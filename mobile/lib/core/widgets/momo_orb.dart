import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

enum MomoMotion { idle, hop, swim, cuddle, excited }

enum MomoExpression {
  softSmile,
  happy,
  curious,
  sleepy,
  cheer,
  sad,
  worried,
  firedUp,
}

class MomoOrb extends StatefulWidget {
  const MomoOrb({
    super.key,
    this.size = 140,
    this.glowColor = AppColors.lavender,
    this.interactive = true,
    this.animate = true,
    this.motion = MomoMotion.idle,
    this.expression = MomoExpression.softSmile,
    this.onTap,
  });

  final double size;
  final Color glowColor;
  final bool interactive;
  final bool animate;
  final MomoMotion motion;
  final MomoExpression expression;
  final VoidCallback? onTap;

  @override
  State<MomoOrb> createState() => _MomoOrbState();
}

class _MomoOrbState extends State<MomoOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  final math.Random _random = math.Random();
  Timer? _blinkTimer;
  bool _blink = false;
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.animate) {
      _floatController.repeat();
      _scheduleBlink();
    } else {
      _floatController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  void _scheduleBlink() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer(Duration(seconds: 4 + _random.nextInt(4)), () async {
      if (!mounted) {
        return;
      }
      setState(() => _blink = true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (!mounted) {
        return;
      }
      setState(() => _blink = false);
      _scheduleBlink();
    });
  }

  Future<void> _handleTap() async {
    if (!widget.interactive) {
      return;
    }
    widget.onTap?.call();
    setState(() => _pulse = true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (mounted) {
      setState(() => _pulse = false);
    }
  }

  _MotionProfile _motionProfile(double wave, double sway) {
    switch (widget.motion) {
      case MomoMotion.hop:
        final double hop = math.max(0, math.sin(_floatController.value * math.pi * 2));
        return _MotionProfile(
          offsetX: sway * 4,
          offsetY: (wave * 3) - (hop * 12),
          rotation: sway * 0.05,
          scale: 1.01 + (hop * 0.03),
          glowBoost: 0.08,
        );
      case MomoMotion.swim:
        return _MotionProfile(
          offsetX: wave * 10,
          offsetY: sway * 4,
          rotation: wave * 0.08,
          scale: 1.0,
          glowBoost: 0.05,
        );
      case MomoMotion.cuddle:
        return _MotionProfile(
          offsetX: wave * 3,
          offsetY: wave * 5,
          rotation: wave * 0.03,
          scale: 1.015,
          glowBoost: 0.04,
        );
      case MomoMotion.excited:
        return _MotionProfile(
          offsetX: sway * 6,
          offsetY: (wave * 7) - 3,
          rotation: sway * 0.08,
          scale: 1.02,
          glowBoost: 0.12,
        );
      case MomoMotion.idle:
        return _MotionProfile(
          offsetX: 0,
          offsetY: wave * 6,
          rotation: wave * 0.02,
          scale: 1,
          glowBoost: 0,
        );
    }
  }

  _FaceProfile _faceProfile() {
    switch (widget.expression) {
      case MomoExpression.happy:
        return const _FaceProfile(
          browLeftAngle: -0.16,
          browRightAngle: 0.16,
          eyeOpenFactor: 1.06,
          pupilShiftX: 0,
          pupilShiftY: -0.02,
          mouthStyle: _MouthStyle.grin,
          mouthWidthFactor: 0.2,
          mouthHeightFactor: 0.11,
          emoteIcon: Icons.favorite_rounded,
          emoteColor: AppColors.peachGlow,
          blushBoost: 0.08,
        );
      case MomoExpression.curious:
        return const _FaceProfile(
          browLeftAngle: -0.24,
          browRightAngle: 0.06,
          eyeOpenFactor: 1.02,
          pupilShiftX: 0.08,
          pupilShiftY: -0.03,
          mouthStyle: _MouthStyle.smile,
          mouthWidthFactor: 0.17,
          mouthHeightFactor: 0.09,
          emoteIcon: Icons.auto_awesome_rounded,
          emoteColor: AppColors.sun,
        );
      case MomoExpression.sleepy:
        return const _FaceProfile(
          browLeftAngle: -0.08,
          browRightAngle: 0.08,
          eyeOpenFactor: 0.72,
          pupilShiftX: 0,
          pupilShiftY: 0.02,
          mouthStyle: _MouthStyle.smile,
          mouthWidthFactor: 0.14,
          mouthHeightFactor: 0.06,
          emoteIcon: Icons.nightlight_round_rounded,
          emoteColor: AppColors.mistBlue,
        );
      case MomoExpression.cheer:
        return const _FaceProfile(
          browLeftAngle: -0.1,
          browRightAngle: 0.1,
          eyeOpenFactor: 1.08,
          pupilShiftX: 0,
          pupilShiftY: -0.04,
          mouthStyle: _MouthStyle.openSmile,
          mouthWidthFactor: 0.2,
          mouthHeightFactor: 0.14,
          emoteIcon: Icons.stars_rounded,
          emoteColor: AppColors.sun,
          blushBoost: 0.04,
        );
      case MomoExpression.sad:
        return const _FaceProfile(
          browLeftAngle: -0.18,
          browRightAngle: 0.18,
          eyeOpenFactor: 0.84,
          pupilShiftX: 0,
          pupilShiftY: 0.08,
          mouthStyle: _MouthStyle.frown,
          mouthWidthFactor: 0.16,
          mouthHeightFactor: 0.08,
          emoteIcon: Icons.water_drop_rounded,
          emoteColor: AppColors.mistBlue,
          blushBoost: 0.02,
        );
      case MomoExpression.worried:
        return const _FaceProfile(
          browLeftAngle: -0.22,
          browRightAngle: 0.22,
          eyeOpenFactor: 0.92,
          pupilShiftX: 0.03,
          pupilShiftY: 0.04,
          mouthStyle: _MouthStyle.frown,
          mouthWidthFactor: 0.15,
          mouthHeightFactor: 0.07,
          emoteIcon: Icons.favorite_border_rounded,
          emoteColor: AppColors.peachGlow,
        );
      case MomoExpression.firedUp:
        return const _FaceProfile(
          browLeftAngle: -0.3,
          browRightAngle: 0.3,
          eyeOpenFactor: 1.02,
          pupilShiftX: 0,
          pupilShiftY: -0.02,
          mouthStyle: _MouthStyle.openSmile,
          mouthWidthFactor: 0.18,
          mouthHeightFactor: 0.12,
          emoteIcon: Icons.local_fire_department_rounded,
          emoteColor: AppColors.peachGlow,
          blushBoost: 0.06,
        );
      case MomoExpression.softSmile:
        return const _FaceProfile(
          browLeftAngle: -0.08,
          browRightAngle: 0.08,
          eyeOpenFactor: 1,
          pupilShiftX: 0,
          pupilShiftY: 0,
          mouthStyle: _MouthStyle.smile,
          mouthWidthFactor: 0.16,
          mouthHeightFactor: 0.08,
          emoteIcon: Icons.favorite_border_rounded,
          emoteColor: AppColors.lavender,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.interactive ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (BuildContext context, Widget? child) {
          final double wave = widget.animate
              ? math.sin(_floatController.value * math.pi * 2)
              : 0;
          final double sway = widget.animate
              ? math.sin((_floatController.value * math.pi * 4) + 0.6)
              : 0;
          final _MotionProfile motion = _motionProfile(wave, sway);
          final _FaceProfile face = _faceProfile();
          final double scale = (_pulse ? 1.04 : 1) * motion.scale;
          final double bodyGlow = (_pulse ? 0.12 : 0) + motion.glowBoost;

          return Transform.translate(
            offset: Offset(motion.offsetX, motion.offsetY),
            child: Transform.rotate(
              angle: motion.rotation,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 260),
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    ...List<Widget>.generate(5, (int index) {
                      final double angle =
                          (_floatController.value * math.pi * 2) + (index * 1.2);
                      final double orbit = widget.size * (0.42 + (index * 0.018));
                      final double dotSize = widget.size * (0.055 - (index * 0.006));
                      final double left =
                          (widget.size / 2) + math.cos(angle) * orbit + (widget.size * 0.18);
                      final double top = (widget.size / 2) +
                          math.sin(angle) * orbit * 0.54 +
                          (widget.size * 0.12);
                      return Positioned(
                        left: left,
                        top: top,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: widget.glowColor.withValues(alpha: 0.24 - (index * 0.025)),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: widget.size + (_pulse ? 34 : 16),
                      height: widget.size + (_pulse ? 34 : 16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            widget.glowColor.withValues(alpha: 0.22 + bodyGlow),
                            widget.glowColor.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    if (face.emoteIcon != null)
                      Positioned(
                        top: -widget.size * 0.02,
                        right: widget.size * 0.1,
                        child: _EmoteBadge(
                          icon: face.emoteIcon!,
                          color: face.emoteColor,
                          size: widget.size * 0.2,
                        ),
                      ),
                    Positioned(
                      bottom: -widget.size * 0.08,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List<Widget>.generate(3, (int index) {
                          final double width = widget.size * (0.14 + (index * 0.024));
                          return Transform.translate(
                            offset: Offset((index - 1) * sway * 0.8, wave.abs() * 2),
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.02),
                              width: width,
                              height: widget.size * 0.22,
                              decoration: BoxDecoration(
                                color: widget.glowColor.withValues(alpha: 0.34),
                                borderRadius: BorderRadius.circular(widget.size),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Container(
                      width: widget.size,
                      height: widget.size * 1.02,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.size),
                        gradient: RadialGradient(
                          center: const Alignment(-0.08, -0.34),
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.99),
                            AppColors.softCream,
                            widget.glowColor.withValues(alpha: 0.76),
                          ],
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: widget.glowColor.withValues(alpha: 0.28 + bodyGlow),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: widget.size * 0.1,
                      left: widget.size * 0.18,
                      child: Transform.rotate(
                        angle: -0.34,
                        child: Container(
                          width: widget.size * 0.24,
                          height: widget.size * 0.12,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(widget.size),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: widget.size * 0.16,
                      right: widget.size * 0.18,
                      child: Container(
                        width: widget.size * 0.07,
                        height: widget.size * 0.07,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: widget.size * 0.31,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _Brow(size: widget.size * 0.12, angle: face.browLeftAngle),
                          SizedBox(width: widget.size * 0.15),
                          _Brow(size: widget.size * 0.12, angle: face.browRightAngle),
                        ],
                      ),
                    ),
                    Positioned(
                      top: widget.size * 0.39,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _Eye(
                            size: widget.size * 0.2,
                            blink: _blink,
                            openFactor: face.eyeOpenFactor,
                            pupilShiftX: face.pupilShiftX,
                            pupilShiftY: face.pupilShiftY,
                          ),
                          SizedBox(width: widget.size * 0.09),
                          _Eye(
                            size: widget.size * 0.2,
                            blink: _blink,
                            openFactor: face.eyeOpenFactor,
                            pupilShiftX: face.pupilShiftX,
                            pupilShiftY: face.pupilShiftY,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: widget.size * 0.59,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _Blush(
                            size: widget.size * 0.13,
                            glowColor: widget.glowColor,
                            alphaBoost: face.blushBoost,
                          ),
                          SizedBox(width: widget.size * 0.28),
                          _Blush(
                            size: widget.size * 0.13,
                            glowColor: widget.glowColor,
                            alphaBoost: face.blushBoost,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: widget.size * 0.64,
                      child: _Mouth(
                        width: widget.size * face.mouthWidthFactor,
                        height: widget.size * face.mouthHeightFactor,
                        style: face.mouthStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MotionProfile {
  const _MotionProfile({
    required this.offsetX,
    required this.offsetY,
    required this.rotation,
    required this.scale,
    required this.glowBoost,
  });

  final double offsetX;
  final double offsetY;
  final double rotation;
  final double scale;
  final double glowBoost;
}

class _FaceProfile {
  const _FaceProfile({
    required this.browLeftAngle,
    required this.browRightAngle,
    required this.eyeOpenFactor,
    required this.pupilShiftX,
    required this.pupilShiftY,
    required this.mouthStyle,
    required this.mouthWidthFactor,
    required this.mouthHeightFactor,
    required this.emoteIcon,
    required this.emoteColor,
    this.blushBoost = 0,
  });

  final double browLeftAngle;
  final double browRightAngle;
  final double eyeOpenFactor;
  final double pupilShiftX;
  final double pupilShiftY;
  final _MouthStyle mouthStyle;
  final double mouthWidthFactor;
  final double mouthHeightFactor;
  final IconData? emoteIcon;
  final Color emoteColor;
  final double blushBoost;
}

class _Brow extends StatelessWidget {
  const _Brow({
    required this.size,
    required this.angle,
  });

  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size * 0.18,
        decoration: BoxDecoration(
          color: AppColors.subInk.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

class _Blush extends StatelessWidget {
  const _Blush({
    required this.size,
    required this.glowColor,
    required this.alphaBoost,
  });

  final double size;
  final Color glowColor;
  final double alphaBoost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.58,
      decoration: BoxDecoration(
        color: glowColor.withValues(alpha: 0.22 + alphaBoost),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({
    required this.size,
    required this.blink,
    required this.openFactor,
    required this.pupilShiftX,
    required this.pupilShiftY,
  });

  final double size;
  final bool blink;
  final double openFactor;
  final double pupilShiftX;
  final double pupilShiftY;

  @override
  Widget build(BuildContext context) {
    final double eyeHeight = blink ? size * 0.16 : size * 1.12 * openFactor;
    final double pupilLeft = size * (0.18 + (pupilShiftX * 0.18));
    final double pupilTop = size * (0.18 + (pupilShiftY * 0.18));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: size,
      height: eyeHeight,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(size),
      ),
      child: blink
          ? null
          : Stack(
              children: <Widget>[
                Positioned(
                  left: pupilLeft,
                  top: pupilTop,
                  child: Container(
                    width: size * 0.28,
                    height: size * 0.28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: size * 0.14,
                  bottom: size * 0.18,
                  child: Container(
                    width: size * 0.1,
                    height: size * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

enum _MouthStyle { smile, grin, openSmile, frown }

class _Mouth extends StatelessWidget {
  const _Mouth({
    required this.width,
    required this.height,
    required this.style,
  });

  final double width;
  final double height;
  final _MouthStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MouthPainter(style),
    );
  }
}

class _MouthPainter extends CustomPainter {
  const _MouthPainter(this.style);

  final _MouthStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint stroke = Paint()
      ..color = AppColors.subInk.withValues(alpha: 0.72)
      ..strokeWidth = size.height * 0.22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path smilePath = style == _MouthStyle.frown
        ? (Path()
          ..moveTo(size.width * 0.18, size.height * 0.7)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height * 0.18,
            size.width * 0.82,
            size.height * 0.7,
          ))
        : (Path()
          ..moveTo(size.width * 0.14, size.height * 0.34)
          ..quadraticBezierTo(
            size.width * 0.5,
            size.height * (style == _MouthStyle.grin ? 1.2 : 1.02),
            size.width * 0.86,
            size.height * 0.34,
          ));

    if (style == _MouthStyle.openSmile) {
      final Paint fill = Paint()
        ..color = AppColors.subInk.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height * 0.56),
            width: size.width * 0.58,
            height: size.height * 0.64,
          ),
          Radius.circular(size.height),
        ),
        fill,
      );
    }

    canvas.drawPath(smilePath, stroke);
  }

  @override
  bool shouldRepaint(covariant _MouthPainter oldDelegate) => oldDelegate.style != style;
}

class _EmoteBadge extends StatelessWidget {
  const _EmoteBadge({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}
