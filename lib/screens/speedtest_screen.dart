import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../widgets/language_toggle_button.dart';

/// IMPORTANT: Change this to your live website's speed-test page URL
/// (the same shanzone.html speed test you already built & tested).
/// e.g. 'https://shanzone.in/#speedtest' or wherever it's hosted.
const String kSpeedTestUrl = 'https://REPLACE-WITH-YOUR-WEBSITE-URL/#speedtest';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  late final WebViewController _controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => loading = true),
          onPageFinished: (_) => setState(() => loading = false),
        ),
      )
      ..loadRequest(Uri.parse(kSpeedTestUrl));
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
          body: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (loading)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.gradientCenter),
                ),
            ],
          ),
        );
      },
    );
  }
}
