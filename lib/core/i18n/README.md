# Système d'internationalisation (i18n)

Ce dossier contient le système complet de gestion multilingue de l'application LSC.

## Langues supportées

- 🇫🇷 **Français** (fr) - Langue par défaut
- 🇬🇧 **Anglais** (en)
- 🇨🇳 **Chinois** (zh)

## Structure des fichiers

```
lib/core/i18n/
├── app_localizations.dart    # Classe principale de gestion des traductions
├── locale_provider.dart       # Provider Riverpod pour changer la langue
└── i18n.dart                  # Export des fonctionnalités

assets/translations/
├── fr.json                    # Traductions françaises
├── en.json                    # Traductions anglaises
└── zh.json                    # Traductions chinoises
```

## Utilisation

### 1. Accéder aux traductions dans un widget

```dart
import 'package:flutter/material.dart';
import '../../core/i18n/app_localizations.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Text(l10n.authWelcome); // Utilise la traduction
  }
}
```

### 2. Utiliser la méthode translate() pour les clés dynamiques

```dart
final l10n = AppLocalizations.of(context);

// Accès par notation à points
String errorMessage = l10n.translate('auth.errors.emailRequired');
String buttonText = l10n.tr('common.save'); // Version courte
```

### 3. Changer la langue de l'application

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/locale_provider.dart';

class LanguageSwitcher extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        // Changer vers l'anglais
        ref.read(localeProvider.notifier).setLocale(
          const Locale('en', 'US'),
        );
      },
      child: Text('Switch to English'),
    );
  }
}
```

### 4. Utiliser le widget de sélection de langue

```dart
import '../../core/widgets/language_selector.dart';

// Widget simple (icône avec menu)
const LanguageSelector()

// Widget complet (avec dropdown)
const LanguageSelectorFull()
```

## Ajouter de nouvelles traductions

### 1. Ajouter une nouvelle clé dans les fichiers JSON

**assets/translations/fr.json**
```json
{
  "myFeature": {
    "title": "Mon titre",
    "description": "Ma description"
  }
}
```

**assets/translations/en.json**
```json
{
  "myFeature": {
    "title": "My title",
    "description": "My description"
  }
}
```

**assets/translations/zh.json**
```json
{
  "myFeature": {
    "title": "我的标题",
    "description": "我的描述"
  }
}
```

### 2. (Optionnel) Ajouter des accesseurs dans AppLocalizations

Dans `lib/core/i18n/app_localizations.dart`, vous pouvez ajouter des getters pour un accès plus facile:

```dart
// Dans la classe AppLocalizations
String get myFeatureTitle => translate('myFeature.title');
String get myFeatureDescription => translate('myFeature.description');
```

## Ajouter une nouvelle langue

### 1. Créer le fichier de traduction

Créez `assets/translations/CODE_LANGUE.json` avec toutes les traductions.

### 2. Mettre à jour AppLocalizations

Dans `lib/core/i18n/app_localizations.dart`:

```dart
static const List<Locale> supportedLocales = [
  Locale('fr', 'FR'),
  Locale('en', 'US'),
  Locale('zh', 'CN'),
  Locale('es', 'ES'), // Nouvelle langue
];
```

### 3. Mettre à jour LocaleNotifier

Dans `lib/core/i18n/locale_provider.dart`:

```dart
Locale _getLocaleFromCode(String code) {
  switch (code) {
    case 'fr':
      return const Locale('fr', 'FR');
    case 'en':
      return const Locale('en', 'US');
    case 'zh':
      return const Locale('zh', 'CN');
    case 'es':
      return const Locale('es', 'ES'); // Ajouter ici
    default:
      return const Locale('fr', 'FR');
  }
}
```

### 4. Mettre à jour le widget de sélection

Ajoutez l'option dans `lib/core/widgets/language_selector.dart`.

## Bonnes pratiques

1. **Organisation des clés**: Utilisez une structure hiérarchique cohérente
   - `feature.component.text`
   - Exemple: `auth.login.title`, `dashboard.stats.title`

2. **Nommage**: Utilisez camelCase pour les clés
   - ✅ `emailRequired`
   - ❌ `email_required`

3. **Contexte**: Groupez les traductions par fonctionnalité
   - `auth.*` pour tout ce qui concerne l'authentification
   - `common.*` pour les textes réutilisables

4. **Cohérence**: Assurez-vous que toutes les langues ont les mêmes clés

5. **Fallback**: Si une traduction n'existe pas, la clé sera affichée (utile pour le debug)

## Persistance

La langue sélectionnée est automatiquement sauvegardée dans SharedPreferences et restaurée au redémarrage de l'application.

## Tests

Pour tester une langue spécifique sans changer les paramètres:

```dart
// Dans les tests
testWidgets('Test en français', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale('fr', 'FR'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        // ...
      ],
      home: MyWidget(),
    ),
  );

  // Vos tests...
});
```
