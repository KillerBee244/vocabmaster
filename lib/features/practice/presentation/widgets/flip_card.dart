// lib/features/practice/presentation/widgets/flip_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlipCard extends StatefulWidget {
  /// Văn bản mặt trước và sau – giữ nguyên cách dùng cũ
  final String front;
  final String back;

  /// Tùy chọn giao diện
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double elevation;

  /// Animation
  final Duration duration;         // Thời gian lật
  final Curve curve;               // Đường cong
  final bool hapticOnFlip;         // Rung nhẹ khi lật

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.textStyle,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.elevation = 8,
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeInOutCubic,
    this.hapticOnFlip = true,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim; // 0 → 1
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _c, curve: widget.curve);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (widget.hapticOnFlip) HapticFeedback.selectionClick();
    if (_isFront) {
      await _c.forward();
    } else {
      await _c.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget _face(String text,
        {bool isBack = false}) {
      // Card nền + đổ bóng nhẹ giống Quizlet
      final card = Material(
        color: cs.surface,
        elevation: widget.elevation,
        shadowColor: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          padding: widget.padding,
          alignment: Alignment.center,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: widget.textStyle ??
                  const TextStyle(fontSize: 20, height: 1.35),
            ),
          ),
        ),
      );

      // Khi là mặt sau, xoay thêm π để text không bị ngược
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)        // perspective nhẹ (cảm giác 3D)
          ..rotateY(isBack ? math.pi : 0),
        child: card,
      );
    }

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          // Góc xoay: 0 → π
          final angle = _anim.value * math.pi;

          // Mặt nào đang hiển thị?
          final showFront = angle <= math.pi / 2;

          return Stack(
            alignment: Alignment.center,
            children: [
              // BACK
              // Đặt dưới, chỉ hiện khi vượt 90°
              IgnorePointer(ignoring: showFront, child: Opacity(
                opacity: showFront ? 0 : 1,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  child: _face(widget.back, isBack: true),
                ),
              )),
              // FRONT
              IgnorePointer(ignoring: !showFront, child: Opacity(
                opacity: showFront ? 1 : 0,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(angle),
                  child: _face(widget.front),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}
