import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// A 4-digit OTP entry with a "converge into a square, verify, reveal
/// success/error" animation. The actual verification call is delegated
/// to [onSubmit] — this widget only owns the visual choreography.
class AnimatedOtpVerifier extends StatefulWidget {
  final int length;
  final Future<bool> Function(String code) onSubmit;
  final VoidCallback onVerified;

  const AnimatedOtpVerifier({
    super.key,
    this.length = 4,
    required this.onSubmit,
    required this.onVerified,
  });

  @override
  State<AnimatedOtpVerifier> createState() => AnimatedOtpVerifierState();
}

enum _Stage { entry, converging, verifying, success, error }

class AnimatedOtpVerifierState extends State<AnimatedOtpVerifier> with TickerProviderStateMixin {
  late final List<TextEditingController> _ctrls =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(widget.length, (_) => FocusNode());

  _Stage stage = _Stage.entry;

  // One controller drives box-movement + square outline (0.0 - 1.0),
  // a second drives the spin/converge + brand reveal while we wait on
  // the real network call.
  late final AnimationController _arrangeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _spinCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _resultCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _arrangeCtrl.dispose();
    _spinCtrl.dispose();
    _resultCtrl.dispose();
    super.dispose();
  }

  void _onChanged(int i, String value) {
    final digit = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit != value) _ctrls[i].text = digit;
    if (digit.isEmpty) return;

    if (i < widget.length - 1) {
      _nodes[i + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      if (_ctrls.every((c) => c.text.isNotEmpty)) _startVerification();
    }
  }

  void _onBackspace(int i) {
    if (_ctrls[i].text.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
  }

  Future<void> _startVerification() async {
    setState(() => stage = _Stage.converging);
    await _arrangeCtrl.forward(from: 0);
    if (!mounted) return;

    setState(() => stage = _Stage.verifying);
    final code = _ctrls.map((c) => c.text).join();

    final spinFuture = _spinCtrl.forward(from: 0);
    final apiFuture = widget.onSubmit(code);
    final results = await Future.wait([apiFuture, spinFuture.then((_) => true)]);
    if (!mounted) return;

    final success = results[0] as bool;
    if (success) {
      setState(() => stage = _Stage.success);
      await _resultCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 550));
      if (mounted) widget.onVerified();
    } else {
      setState(() => stage = _Stage.error);
      await _resultCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1200));
      _reset();
    }
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      stage = _Stage.entry;
      for (final c in _ctrls) c.text = '';
    });
    _arrangeCtrl.reset();
    _spinCtrl.reset();
    _resultCtrl.reset();
    _nodes.first.requestFocus();
  }

  // 2x2 grid target positions (fractions of the stage box)
  static const List<Alignment> _grid = [
    Alignment(-0.32, -0.38),
    Alignment(0.32, -0.38),
    Alignment(0.32, 0.38),
    Alignment(-0.32, 0.38),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_arrangeCtrl, _spinCtrl]),
            builder: (context, _) {
              final arrange = Curves.easeInOutCubic.transform(_arrangeCtrl.value);
              final spin = Curves.easeInOutCubic.transform(_spinCtrl.value);
              final showBoxes = stage == _Stage.entry ||
                  stage == _Stage.converging ||
                  (stage == _Stage.verifying && spin < 0.75);

              return Opacity(
                opacity: showBoxes ? (1 - (spin * 1.3)).clamp(0.0, 1.0) : 0,
                child: Transform.scale(
                  scale: 1 - spin * 0.75,
                  child: Transform.rotate(
                    angle: spin * 3.2 * pi,
                    child: SizedBox(
                      width: 240,
                      height: 200,
                      child: Stack(
                        children: [
                          if (arrange > 0.05)
                            CustomPaint(
                              size: const Size(240, 200),
                              painter: _SquareOutlinePainter(
                                progress: ((arrange - 0.5) * 2).clamp(0.0, 1.0),
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          for (var i = 0; i < widget.length; i++)
                            _positionedBox(i, arrange),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Brand chip + "Verifying..." label
          if (stage == _Stage.verifying)
            AnimatedBuilder(
              animation: _spinCtrl,
              builder: (context, _) {
                final show = (Curves.easeIn.transform(_spinCtrl.value) - 0.55).clamp(0.0, 1.0) * (1 / 0.45);
                return Opacity(
                  opacity: show.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(color: AppColors.gradientCenter.withOpacity(0.4), blurRadius: 24),
                          ],
                        ),
                        child: const Text(
                          'SHAN ZONE',
                          style: TextStyle(
                            color: AppColors.gradientCenter,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        S.of('verifying'),
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, letterSpacing: 2),
                      ),
                    ],
                  ),
                );
              },
            ),

          // Success checkmark
          if (stage == _Stage.success)
            AnimatedBuilder(
              animation: _resultCtrl,
              builder: (context, _) {
                final t = Curves.elasticOut.transform(_resultCtrl.value.clamp(0.0, 1.0));
                return Opacity(
                  opacity: _resultCtrl.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + (t * 0.4).clamp(0.0, 0.4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: AppColors.success.withOpacity(0.45), blurRadius: 30),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          S.of('verifiedSuccess'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // Error mark
          if (stage == _Stage.error)
            AnimatedBuilder(
              animation: _resultCtrl,
              builder: (context, _) {
                return Opacity(
                  opacity: _resultCtrl.value.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFF6575), width: 2),
                        ),
                        child: const Icon(Icons.close_rounded, color: Color(0xFFFF6575), size: 28),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        S.of('invalidOtp'),
                        style: const TextStyle(color: Color(0xFFFF6575), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _positionedBox(int i, double arrange) {
    // Row start position vs 2x2 grid end position, lerped by `arrange`.
    final spacing = 70.0;
    final rowStartX = (i - (widget.length - 1) / 2) * spacing;
    const rowStartY = 0.0;

    final gridAlign = _grid[i];
    final endX = gridAlign.x * 120;
    final endY = gridAlign.y * 100;

    final x = rowStartX + (endX - rowStartX) * arrange;
    final y = rowStartY + (endY - rowStartY) * arrange;
    final filled = _ctrls[i].text.isNotEmpty;

    return Positioned(
      left: 120 + x - 28,
      top: 100 + y - 32,
      child: Container(
        width: 56,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(filled ? 0.22 : 0.14),
          border: Border.all(
            color: filled ? Colors.white.withOpacity(0.8) : Colors.white.withOpacity(0.3),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: stage == _Stage.entry
            ? TextField(
                controller: _ctrls[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                maxLength: 1,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: (v) => _onChanged(i, v),
                onSubmitted: (_) {},
                onEditingComplete: () {},
              )
            : Text(
                _ctrls[i].text,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _SquareOutlinePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _SquareOutlinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width * 0.62;
    final h = size.height * 0.72;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);

    final path = Path()..addRect(rect);
    final metrics = path.computeMetrics().first;
    final extract = metrics.extractPath(0, metrics.length * progress);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(covariant _SquareOutlinePainter oldDelegate) => oldDelegate.progress != progress;
}
