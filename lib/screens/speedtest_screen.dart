import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/language_toggle_button.dart';

// Ye poora test app ke andar hi (native Dart code se) chalta hai —
// koi website load nahi hoti. Cloudflare ke free, public speed-test
// endpoints use kiye hain (yahi endpoints kai popular speed-test apps
// use karte hain — koi apna server chahiye nahi).
const String _downloadUrl = 'https://speed.cloudflare.com/__down?bytes=100000000';
const String _uploadUrl = 'https://speed.cloudflare.com/__up';
const int _warmupMs = 700;   // shuru ke chhote burst ko ignore karte hain (zyada accurate result)
const int _measureMs = 4000; // itni der actual measurement hoti hai (download/upload, alag-alag)

enum _Phase { idle, ping, download, upload, done }

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});
  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  _Phase phase = _Phase.idle;
  double downloadMbps = 0;
  double uploadMbps = 0;
  int pingMs = 0;
  double gaugeMbps = 0; // test chalte waqt live sui/needle value
  bool testing = false;

  Future<void> _start() async {
    setState(() {
      testing = true;
      phase = _Phase.ping;
      downloadMbps = 0;
      uploadMbps = 0;
      pingMs = 0;
      gaugeMbps = 0;
    });

    await _measurePing();
    if (!mounted) return;

    setState(() => phase = _Phase.download);
    final d = await _measureThroughput(isUpload: false);
    if (!mounted) return;
    setState(() {
      downloadMbps = d;
      gaugeMbps = 0;
      phase = _Phase.upload;
    });

    final u = await _measureThroughput(isUpload: true);
    if (!mounted) return;
    setState(() {
      uploadMbps = u;
      gaugeMbps = 0;
      phase = _Phase.done;
      testing = false;
    });
  }

  Future<void> _measurePing() async {
    final samples = <int>[];
    for (var i = 0; i < 3; i++) {
      final sw = Stopwatch()..start();
      try {
        await http
            .get(Uri.parse('https://speed.cloudflare.com/__down?bytes=1000'))
            .timeout(const Duration(seconds: 5));
        sw.stop();
        samples.add(sw.elapsedMilliseconds);
      } catch (_) {
        // ek sample fail ho jaaye toh bhi test aage badhta rahega
      }
    }
    if (samples.isNotEmpty && mounted) {
      samples.sort();
      setState(() => pingMs = samples[samples.length ~/ 2]); // median value
    }
  }

  Future<double> _measureThroughput({required bool isUpload}) async {
    final client = http.Client();
    final overallStart = DateTime.now();
    final warmupEnd = overallStart.add(const Duration(milliseconds: _warmupMs));
    final testEnd = warmupEnd.add(const Duration(milliseconds: _measureMs));

    int measuredBytes = 0;
    DateTime? measureStart;
    double finalMbps = 0;
    DateTime lastUiUpdate = DateTime.now();

    void onChunk(int len) {
      final now = DateTime.now();
      if (now.isBefore(warmupEnd)) return;
      measureStart ??= now;
      measuredBytes += len;
      final elapsedSec = now.difference(measureStart!).inMilliseconds / 1000;
      if (elapsedSec > 0.05) {
        finalMbps = ((measuredBytes * 8) / 1e6) / elapsedSec;
        // Live gauge sirf har ~120ms me update hoti hai — bahut zyada
        // baar setState() call karne se needle jhatke khaayegi.
        if (now.difference(lastUiUpdate).inMilliseconds > 120 && mounted) {
          lastUiUpdate = now;
          setState(() => gaugeMbps = finalMbps);
        }
      }
    }

    try {
      if (!isUpload) {
        final req = http.Request('GET', Uri.parse(_downloadUrl));
        final streamed = await client.send(req);
        await for (final chunk in streamed.stream) {
          onChunk(chunk.length);
          if (DateTime.now().isAfter(testEnd)) break;
        }
      } else {
        final rnd = Random();
        const chunkSize = 2000000; // 2 MB per upload chunk
        while (DateTime.now().isBefore(testEnd)) {
          final bytes = Uint8List.fromList(List<int>.generate(chunkSize, (_) => rnd.nextInt(256)));
          await client
              .post(Uri.parse(_uploadUrl), body: bytes)
              .timeout(const Duration(seconds: 10));
          onChunk(bytes.length);
        }
      }
    } catch (_) {
      // Network hiccup ho jaaye toh bhi jo tak measure hua wahi final result maan lete hain
    } finally {
      client.close();
    }

    return finalMbps;
  }

  String get _phaseLabel {
    switch (phase) {
      case _Phase.idle:
        return S.of('speedTestIdle');
      case _Phase.ping:
        return S.of('speedTestPinging');
      case _Phase.download:
        return S.of('speedTestDownloading');
      case _Phase.upload:
        return S.of('speedTestUploading');
      case _Phase.done:
        return S.of('speedTestComplete');
    }
  }

  double get _currentGaugeValue {
    if (phase == _Phase.download || phase == _Phase.upload) return gaugeMbps;
    if (phase == _Phase.done) return phase == _Phase.done ? uploadMbps : 0;
    return 0;
  }

  Color get _gaugeColor {
    if (phase == _Phase.upload) return const Color(0xFFFFA31A);
    return AppColors.gradientCenter;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight,
          appBar: AppBar(
            backgroundColor: AppColors.gradientCenter,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              S.of('speedTestTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 14),
                child: Center(
                  child: LanguageToggleButton(
                    foreground: Colors.white,
                    background: Color(0x33FFFFFF),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
              child: Column(
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        value: _currentGaugeValue,
                        maxValue: max(100, (_currentGaugeValue * 1.3).ceilToDouble()),
                        color: _gaugeColor,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentGaugeValue.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Text('Mbps', style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(_phaseLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultCard(
                          icon: Icons.download_rounded,
                          label: S.of('download'),
                          value: downloadMbps,
                          color: AppColors.gradientCenter,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultCard(
                          icon: Icons.upload_rounded,
                          label: S.of('upload'),
                          value: uploadMbps,
                          color: const Color(0xFFFFA31A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultCard(
                          icon: Icons.podcasts_rounded,
                          label: S.of('ping'),
                          value: pingMs.toDouble(),
                          unit: 'ms',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: testing ? null : _start,
                      icon: testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.bolt_rounded),
                      label: Text(
                        testing ? S.of('speedTestRunning') : S.of('speedTestStart'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientCenter,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final String unit;
  final Color color;
  const _ResultCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.unit = 'Mbps',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value == 0 ? '--' : value.toStringAsFixed(unit == 'ms' ? 0 : 1),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          Text(unit, style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;
  _GaugePainter({required this.value, required this.maxValue, required this.color});

  static const double _startAngle = 150 * pi / 180;
  static const double _sweepAngle = 240 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 14;

    final bgPaint = Paint()
      ..color = const Color(0xFFE9E3F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), _startAngle, _sweepAngle, false, bgPaint);

    final progress = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    if (progress > 0) {
      final fgPaint = Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: [color.withOpacity(0.45), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), _startAngle, _sweepAngle * progress, false, fgPaint);
    }

    final needleAngle = _startAngle + _sweepAngle * progress;
    final needleEnd = Offset(
      center.dx + (radius - 22) * cos(needleAngle),
      center.dy + (radius - 22) * sin(needleAngle),
    );
    final needlePaint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.maxValue != maxValue || oldDelegate.color != color;
}
