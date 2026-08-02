import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../i18n/app_localizations.dart';
import '../i18n/locale_provider.dart';

/// Widget de sélection de langue sous forme de dropdown
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: l10n.commonLanguage,
      onSelected: (Locale locale) {
        ref.read(localeProvider.notifier).setLocale(locale);
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<Locale>(
            value: const Locale('fr', 'FR'),
            child: Row(
              children: [
                const Text('🇫🇷', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(l10n.translate('languages.fr')),
                if (currentLocale.languageCode == 'fr')
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 18),
                  ),
              ],
            ),
          ),
          PopupMenuItem<Locale>(
            value: const Locale('en', 'US'),
            child: Row(
              children: [
                const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(l10n.translate('languages.en')),
                if (currentLocale.languageCode == 'en')
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 18),
                  ),
              ],
            ),
          ),
          PopupMenuItem<Locale>(
            value: const Locale('zh', 'CN'),
            child: Row(
              children: [
                const Text('🇨🇳', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(l10n.translate('languages.zh')),
                if (currentLocale.languageCode == 'zh')
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check, size: 18),
                  ),
              ],
            ),
          ),
        ];
      },
    );
  }
}

/// Widget de sélection de langue avec style personnalisé (complet)
class LanguageSelectorFull extends ConsumerWidget {
  const LanguageSelectorFull({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 8),
          DropdownButton<Locale>(
            value: currentLocale,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1E1E2C),
            icon: const Icon(Icons.arrow_drop_down),
            onChanged: (Locale? locale) {
              if (locale != null) {
                ref.read(localeProvider.notifier).setLocale(locale);
              }
            },
            items: [
              DropdownMenuItem(
                value: const Locale('fr', 'FR'),
                child: Row(
                  children: [
                    const Text('🇫🇷', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.translate('languages.fr')),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: const Locale('en', 'US'),
                child: Row(
                  children: [
                    const Text('🇬🇧', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.translate('languages.en')),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: const Locale('zh', 'CN'),
                child: Row(
                  children: [
                    const Text('🇨🇳', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(l10n.translate('languages.zh')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
