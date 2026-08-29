import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/language_toggle_button.dart';

// ─── Constants ────────────────────────────────────────────────
const String _downloadUrl =
    'https://speed.cloudflare.com/__down?bytes=100000000';
const String _uploadUrl = 'https://speed.cloudflare.com/__up';
const int _warmupMs = 700;   // ignore initial burst
const int _measureMs = 4000; // actual measurement duration

enum _Phase { idle, ping, download, upload, done }

// ─── Main Screen ──────────────────────────────────────────────
class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen>
    with SingleTickerProviderStateMixin {
  _Phase phase = _Phase.idle;
  double downloadMbps = 0;
  double uploadMbps = 0;
  int pingMs = 0;
  double gaugeMbps = 0; // live needle value
  bool testing = false;

  // For glossy button shimmer
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // ─── Test Flow ──────────────────────────────────────────────
  Future<void> _start() async {
    if (testing) return;
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

  // ─── Ping ────────────────────────────────────────────────────
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
      } catch (_) {}
    }
    if (samples.isNotEmpty && mounted) {
      samples.sort();
      setState(() => pingMs = samples[samples.length ~/ 2]);
    }
  }

  // ─── Throughput (Download / Upload) ─────────────────────────
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
        const chunkSize = 2000000; // 2 MB per chunk
        while (DateTime.now().isBefore(testEnd)) {
          final bytes = Uint8List.fromList(
              List<int>.generate(chunkSize, (_) => rnd.nextInt(256)));
          await client
              .post(Uri.parse(_uploadUrl), body: bytes)
              .timeout(const Duration(seconds: 10));
          onChunk(bytes.length);
        }
      }
    } catch (_) {
      // ignore network hiccups
    } finally {
      client.close();
    }

    return finalMbps;
  }

  // ─── UI Helpers ──────────────────────────────────────────────
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
    if (phase == _Phase.done) return uploadMbps;
    return 0;
  }

  // ─── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: AppColors.surfaceLight, // light purple (theme)
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SHAN ZONE',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: AppColors.textDark,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 6),
                // WiFi Icon (SVG) – using AppColors.textDark for stroke
                SvgPicture.string(
                  '''
                  <svg viewBox="0 0 24 24" fill="none" stroke="${AppColors.textDark.toHex()}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M5 12.55a10.94 10.94 0 0 1 14.08 0" />
                    <path d="M1.42 9a16 16 0 0 1 21.16 0" />
                    <path d="M8.53 16.11a6 6 0 0 1 6.94 0" />
                    <circle cx="12" cy="20" r="1.5" fill="${AppColors.textDark.toHex()}" stroke="none" />
                  </svg>
                  ''',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ],
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
                  // ─── Gauge ──────────────────────────────────
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        value: _currentGaugeValue,
                        maxValue: 1000, // fixed scale 0–1000
                        color: phase == _Phase.upload
                            ? AppColors.warning
                            : AppColors.gradientCenter,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentGaugeValue.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Mbps',
                              style: GoogleFonts.poppins(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _phaseLabel,
                              style: GoogleFonts.poppins(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Result Cards ──────────────────────────
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
                          color: AppColors.warning,
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

                  // ─── Glossy START Button ────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: AppColors.brandGradient, // uses app gradient
                            boxShadow: [
                              if (!testing)
                                BoxShadow(
                                  color: AppColors.gradientCenter
                                      .withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: testing ? null : _start,
                            icon: testing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.bolt_rounded),
                            label: Text(
                              testing
                                  ? S.of('speedTestRunning')
                                  : S.of('speedTestStart'),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Powered by SHAN ZONE Core Network',
                    style: GoogleFonts.poppins(
                      color: AppColors.textMuted.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

// ─── Result Card Widget ────────────────────────────────────────
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
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value == 0 ? '--' : value.toStringAsFixed(unit == 'ms' ? 0 : 1),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gauge Custom Painter (with scale markings) ──────────────
class _GaugePainter extends CustomPainter {
  final double value;
  final double maxValue;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  static const double _startAngle = 150 * pi / 180;
  static const double _sweepAngle = 240 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 18;

    // ── Background arc ──
    final bgPaint = Paint()
      ..color = AppColors.glassFillLight.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      bgPaint,
    );

    // ── Scale markings (0, 100, 200, … 1000) ──
    final textStyle = GoogleFonts.poppins(
      color: AppColors.textDark,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final textPainter = TextPainter(
      text: const TextSpan(text: ''),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int v = 0; v <= 1000; v += 100) {
      final fraction = v / 1000;
      final angle = _startAngle + _sweepAngle * fraction;

      // Tick line
      final innerR = radius - 4;
      final outerR = radius + 10;
      final x1 = center.dx + innerR * cos(angle);
      final y1 = center.dy + innerR * sin(angle);
      final x2 = center.dx + outerR * cos(angle);
      final y2 = center.dy + outerR * sin(angle);
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = AppColors.textDark
          ..strokeWidth = 1.5,
      );

      // Number
      final label = v.toString();
      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();
      final textR = radius + 24;
      final tx = center.dx + textR * cos(angle);
      final ty = center.dy + textR * sin(angle);
      textPainter.paint(
        canvas,
        Offset(tx - textPainter.width / 2, ty - textPainter.height / 2),
      );
    }

    // ── Minor ticks every 50 ──
    for (int v = 50; v < 1000; v += 50) {
      if (v % 100 == 0) continue;
      final fraction = v / 1000;
      final angle = _startAngle + _sweepAngle * fraction;
      final innerR = radius - 2;
      final outerR = radius + 6;
      final x1 = center.dx + innerR * cos(angle);
      final y1 = center.dy + innerR * sin(angle);
      final x2 = center.dx + outerR * cos(angle);
      final y2 = center.dy + outerR * sin(angle);
      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        Paint()
          ..color = AppColors.textDark
          ..strokeWidth = 1,
      );
    }

    // ── Glowing progress arc ──
    final progress = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    if (progress > 0) {
      final fgPaint = Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: [color.withOpacity(0.4), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        _sweepAngle * progress,
        false,
        fgPaint,
      );
      // second pass for sharper edge
      final fgPaintSharp = Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: [color.withOpacity(0.6), color],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        _sweepAngle * progress,
        false,
        fgPaintSharp,
      );
    }

    // ── Needle ──
    final needleAngle = _startAngle + _sweepAngle * progress;
    final needleEnd = Offset(
      center.dx + (radius - 22) * cos(needleAngle),
      center.dy + (radius - 22) * sin(needleAngle),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = AppColors.textDark
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // sharp needle
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = AppColors.textDark
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ── Center cap ──
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.color != color;
}

// ─── Helper extension to convert Color to hex string ─────────
extension ColorToHex on Color {
  String toHex() {
    return '#${(value & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').substring(0, 6)}';
  }
}
