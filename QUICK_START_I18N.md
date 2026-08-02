# 🚀 Guide rapide - Système multilingue

## En 30 secondes

### Pour l'utilisateur final

1. Ouvrez l'application
2. Sur l'écran de connexion, cliquez sur l'icône 🌐 en haut à droite
3. Choisissez votre langue :
   - 🇫🇷 Français
   - 🇬🇧 English
   - 🇨🇳 中文
4. L'interface change instantanément !

### Pour le développeur

#### Utiliser les traductions dans un widget

```dart
import '../../../../core/i18n/app_localizations.dart';

// Dans votre méthode build()
final l10n = AppLocalizations.of(context);

// Utilisez les traductions
Text(l10n.authWelcome)
Text(l10n.commonSave)
Text(l10n.translate('custom.key'))
```

#### Ajouter le sélecteur de langue

```dart
import '../../../../core/widgets/language_selector.dart';

// Dans votre AppBar ou ailleurs
const LanguageSelector()
```

#### Ajouter une nouvelle traduction

1. **Éditez les 3 fichiers JSON** dans `assets/translations/`:
   - `fr.json` : "monTexte": "Mon texte en français"
   - `en.json` : "monTexte": "My text in English"
   - `zh.json` : "monTexte": "我的中文文本"

2. **Utilisez-la** :
   ```dart
   l10n.translate('monTexte')
   ```

C'est tout ! 🎉

---

## Clés de traduction disponibles

### App
- `l10n.appTitle` - "FleetManager"
- `l10n.appName` - Nom de l'application

### Auth
- `l10n.authWelcome` - Message de bienvenue
- `l10n.authEmail` - "Adresse email"
- `l10n.authPassword` - "Mot de passe"
- `l10n.authLogin` - "Se connecter"
- `l10n.authLogout` - "Déconnexion"
- `l10n.authForgotPassword` - "Mot de passe oublié ?"

### Common
- `l10n.commonSave` - "Enregistrer"
- `l10n.commonCancel` - "Annuler"
- `l10n.commonDelete` - "Supprimer"
- `l10n.commonEdit` - "Modifier"
- `l10n.commonLoading` - "Chargement..."
- `l10n.commonLanguage` - "Langue"

### Erreurs
```dart
l10n.translate('auth.errors.emailRequired')
l10n.translate('auth.errors.emailInvalid')
l10n.translate('auth.errors.passwordRequired')
```

---

## Exemples complets

### Exemple 1 : Formulaire de connexion
```dart
PremiumTextField(
  label: l10n.authEmail,
  hint: l10n.authEmailHint,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return l10n.translate('auth.errors.emailRequired');
    }
    return null;
  },
)
```

### Exemple 2 : Bouton avec traduction
```dart
ElevatedButton(
  onPressed: _save,
  child: Text(l10n.commonSave),
)
```

### Exemple 3 : Changer de langue
```dart
// Dans un ConsumerWidget
ref.read(localeProvider.notifier).setLocale(
  const Locale('en', 'US'),
);
```

---

## 📖 Documentation complète

Voir : [MULTILINGUAL_INTEGRATION.md](MULTILINGUAL_INTEGRATION.md)
