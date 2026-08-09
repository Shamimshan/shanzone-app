import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../services/session_service.dart';

/// A small pill button ("EN" / "हिं") shown top-right on every screen.
/// Tapping toggles the whole app's language instantly (via AppLocale,
/// a ValueNotifier every screen listens to) and remembers the choice.
class LanguageToggleButton extends StatelessWidget {
  final Color foreground;
  final Color background;

  const LanguageToggleButton({
    super.key,
    this.foreground = Colors.white,
    this.background = const Color(0x33FFFFFF),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLocale.current,
      builder: (context, lang, _) {
        final isHindi = lang == AppLang.hi;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            AppLocale.toggle();
            SessionService.saveLang(AppLocale.current.value);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: foreground.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  isHindi ? 'हिं' : 'EN',
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
