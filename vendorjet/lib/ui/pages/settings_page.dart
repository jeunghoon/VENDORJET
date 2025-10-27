import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';

// 설정 화면: 언어 변경(영어 기본, 한국어 선택 가능)
class SettingsPage extends StatelessWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback? onSignOut;

  const SettingsPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          t.language,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Locale>(
          initialValue: _normalized(currentLocale) ?? const Locale('en'),
          decoration: InputDecoration(
            labelText: t.selectLanguage,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: [
            DropdownMenuItem(value: const Locale('en'), child: Text(t.english)),
            DropdownMenuItem(value: const Locale('ko'), child: Text(t.korean)),
          ],
          onChanged: (loc) {
            if (loc != null) onLocaleChanged(loc);
          },
        ),
        const SizedBox(height: 24),
        if (onSignOut != null)
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
              label: Text(t.signOut),
            ),
          ),
      ],
    );
  }

  // 지역설정 비교 시 countryCode 등 무시하고 언어코드만 맞춤
  Locale? _normalized(Locale? locale) {
    if (locale == null) return null;
    return Locale(locale.languageCode);
  }
}
