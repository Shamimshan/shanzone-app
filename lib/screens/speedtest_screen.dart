import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/language_toggle_button.dart';

/// Live website's speed test section — same tested code the website uses.
const String kSpeedTestUrl = 'https://www.shanwifi.com/#speedtest';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  late final WebViewController _controller;
  bool loading = true;
  bool hadError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            loading = true;
            hadError = false;
          }),
          onPageFinished: (_) => setState(() => loading = false),
          onWebResourceError: (error) => setState(() {
            loading = false;
            hadError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(kSpeedTestUrl));
  }

  void _reload() {
    setState(() {
      loading = true;
      hadError = false;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, _, __) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.gradientCenter,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              S.of('speedTestTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            actions: [
              IconButton(
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Reload',
              ),
              const Padding(
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
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (loading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.gradientCenter),
                ),
              if (hadError && !loading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          S.of('speedTestLoadError'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(S.of('retry')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gradientCenter,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
