# CLAUDE.md

## Projet
Application Flutter de gestion de flotte de camions pour le transport de bauxite (Guinée).
Stack : Flutter + Riverpod + Firebase (Firestore, Auth, Storage)

## Structure du projet
```
lib/
├── core/
│   ├── constants/          # Constantes globales
│   │   └── app_constants.dart
│   ├── i18n/               # Internationalisation
│   │   ├── app_localizations.dart
│   │   └── locale_provider.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/              # Helpers, extensions, validators
│   └── widgets/            # Widgets réutilisables globaux
├── features/
│   ├── auth/               # Authentification, rôles, permissions
│   │   ├── data/repositories/
│   │   ├── data/services/
│   │   ├── domain/models/  # ⚠️ role.dart, permission.dart, user_model.dart
│   │   └── presentation/   # providers/, screens/, widgets/
│   ├── chauffeur/          # Écran chauffeur
│   │   └── presentation/screens/
│   ├── dashboard/          # Dashboard principal + routing
│   │   └── presentation/screens/
│   ├── fleet/              # Gestion des flottes
│   │   ├── data/repositories/
│   │   ├── domain/models/
│   │   └── presentation/   # providers/, screens/, widgets/
│   ├── fleet_supervisor/   # Superviseur flotte
│   │   └── presentation/screens/
│   ├── fuel/               # Ravitaillement carburant (pompiste)
│   │   ├── data/repositories/
│   │   ├── domain/models/
│   │   └── presentation/   # providers/, screens/, widgets/
│   ├── inspection/         # Inspection véhicules
│   │   ├── data/repositories/
│   │   ├── domain/models/
│   │   └── presentation/providers/
│   ├── shifts/             # Vacations/affectations chauffeurs
│   │   ├── data/repositories/
│   │   ├── domain/models/
│   │   └── presentation/providers/
│   ├── trucks/             # Gestion des camions
│   │   ├── data/repositories/
│   │   ├── domain/models/
│   │   └── presentation/   # providers/, screens/, widgets/
│   ├── users/              # Gestion des utilisateurs
│   │   ├── data/repositories/
│   │   └── presentation/   # providers/, screens/, widgets/
│   └── settings/           # Paramètres app
├── services/
│   └── auth_service.dart
├── main.dart
└── firebase_options.dart
```

## Conventions du projet
- **Modèles** : `*_model.dart` dans `domain/models/` avec `fromJson()`, `toJson()`, `copyWith()`
- **Repositories** : dans `data/repositories/` avec Firestore
- **Providers** : Riverpod dans `presentation/providers/`
- **Écrans** : dans `presentation/screens/`
- **Widgets** : dans `presentation/widgets/`
- **Nommage** : snake_case pour fichiers, PascalCase pour classes

## Fichiers clés à connaître
- `lib/features/auth/domain/models/role.dart` → Enum UserRole + permissions par défaut
- `lib/features/auth/domain/models/permission.dart` → Enum Permission
- `lib/features/dashboard/dashboard_screen.dart` → Routing par rôle
- `lib/core/i18n/` → Traductions (FR/EN/ZH)

---

## ✅ TERMINÉ : Feature Flottes

Feature complétée (F.1 à F.13). Entité Fleet en Firestore, CRUD, providers, écrans liste/détail, intégration dashboard et superviseur flotte.

---

## ✅ TERMINÉ : Améliorations & Nouvelles Features

### T.1 — UI : Réduire la taille du bouton flottes (écran superviseur)
- [x] T.1.1 Réduire la taille du bouton dans FleetSupervisorScreen

### T.2 — Dashboard : Dynamiser les données (tonnages)
- [x] T.2.1 Identifier les providers/données statiques du dashboard
- [x] T.2.2 Connecter les tonnages aux données Firestore en temps réel
- [x] T.2.3 Vérifier la mise à jour automatique des KPIs

### T.3 — Dashboard : Détails interactifs + Export XML
- [x] T.3.1 Rendre chaque carte/donnée du dashboard cliquable
- [x] T.3.2 Créer un écran/dialog de détail pour chaque KPI (liste des entrées)
- [x] T.3.3 Implémenter l'export XML des données détaillées
- [x] T.3.4 Ajouter les traductions FR/EN/ZH

### T.4 — Système de management (Manager/Managés)
- [x] T.4.1 Ajouter `managerId` (String?) et `managerName` (String?) au UserModel
- [x] T.4.2 Mettre à jour UserManagementRepository (assigner un manager, lister les managés)
- [x] T.4.3 Créer les providers (managedUsersProvider, managerProvider)
- [x] T.4.4 Ajouter un onglet "Salariés" dans l'écran du responsable (liste des managés + nom du manager)
- [x] T.4.5 Permettre l'assignation manager lors de la création/édition utilisateur
- [x] T.4.6 Ajouter les traductions FR/EN/ZH

### T.5 — Écran Chauffeur : Affectations & Activités
- [x] T.5.1 Développer l'écran chauffeur avec onglets (Affectations | Activités)
- [x] T.5.2 Afficher les shifts/affectations du chauffeur connecté
- [x] T.5.3 Afficher l'historique des activités (trajets, pesées, etc.)
- [x] T.5.4 Ajouter les traductions FR/EN/ZH

### T.6 — Inspection : Limiter aux véhicules de sa flotte
- [x] T.6.1 Filtrer les véhicules disponibles à l'inspection par fleetId du superviseur connecté
- [x] T.6.2 Mettre à jour les providers d'inspection

### T.7 — Demande carburant : Recherche de véhicules
- [x] T.7.1 Ajouter un champ de recherche/autocomplete dans le formulaire de demande carburant
- [x] T.7.2 Filtrer les véhicules par immatriculation ou numéro

### T.8 — Rapport carburant superviseur (par véhicules + période)
- [x] T.8.1 Créer un écran de rapport carburant pour le superviseur
- [x] T.8.2 Permettre la sélection multiple de véhicules (checkbox)
- [x] T.8.3 Ajouter un filtre par plage de dates
- [x] T.8.4 Afficher le rapport consultable (tableau récapitulatif)
- [x] T.8.5 Permettre la génération/export du rapport (consultable par la direction)
- [x] T.8.6 Ajouter les traductions FR/EN/ZH

### T.9 — Pompiste : Ajout numéro de reçu lors du litrage
- [x] T.9.1 Ajouter `receiptNumber` (String?) au FuelRequestModel
- [x] T.9.2 Ajouter le champ numéro de reçu dans le formulaire de saisie du litrage (pompiste)
- [x] T.9.3 Afficher le numéro de reçu dans les détails de la demande
- [x] T.9.4 Ajouter les traductions FR/EN/ZH

### T.10 — Responsable Opérations : Validation demandes carburant en litige
- [x] T.10.1 Ajouter un statut `disputed` (contesté) et `rejected` aux demandes de carburant
- [x] T.10.2 Permettre au responsable opérations de voir les demandes en litige
- [x] T.10.3 Permettre la validation/rejet des demandes contestées
- [x] T.10.4 Ajouter les traductions FR/EN/ZH

### T.11 — Véhicules : Ajouter numéro radar
- [x] T.11.1 Ajouter `radarNumber` (String?) au TruckModel
- [x] T.11.2 Ajouter le champ dans le formulaire de création/édition véhicule
- [x] T.11.3 Afficher le numéro radar dans les détails du véhicule
- [x] T.11.4 Ajouter les traductions FR/EN/ZH

### T.12 — Gestion des photos (Firebase Storage)
- [x] T.12.1 Firebase Storage déjà configuré (firebase_storage + image_picker dans pubspec)
- [x] T.12.2 Créer un service centralisé d'upload/download de photos (image_service.dart)
- [x] T.12.3 Créer un widget réutilisable PhotoPickerWidget (caméra + galerie + visionneuse)
- [x] T.12.4 Intégrer dans le formulaire de pesée (weighing_form_widget.dart)
- [x] T.12.5 Ajouter les traductions FR/EN/ZH

---

## 🔲 EN COURS : Nouvelles Améliorations (Itération 2)

### T.13 — Dashboard général : Filtres, Formatage & Indicateurs
- [x] T.13.1 Filtres de synthèse : Ajouter des filtres par Camion et par Date sur les rapports exportables
- [x] T.13.2 Formatage : Intégrer un séparateur de milliers sur les boutons Tonnage Mine et Port
- [x] T.13.3 Indicateurs : Ajouter le compteur "Nombre de vacations terminées / global" ⚠️ Code présent, traductions manquantes
- [x] T.13.4 Ajouter les traductions FR/EN/ZH

### T.14 — Superviseur Flotte : Correction bug Dashboard
- [x] T.14.1 Correction Bug : Réparer le bouton "Tableau de bord" non fonctionnel dans FleetSupervisorScreen

### T.15 — Superviseur Flotte : Demandes de carburant interactives
- [x] T.15.1 Interaction : Permettre le clic sur "Litrage servis" pour ouvrir le détail dans l'onglet carburant
- [x] T.15.2 Ajouter les traductions FR/EN/ZH

### T.16 — Superviseur Flotte : Vue Véhicules
- [x] T.16.1 Nomenclature : Afficher chaque véhicule sous le format Plaque (AA-123-AAA) + Numéro Interne
- [x] T.16.2 Recherche multi-critères : Permettre la recherche par Plaque OU Numéro interne
- [x] T.16.3 Affectations : Afficher directement les chauffeurs affectés au véhicule sur cette vue
- [x] T.16.4 Ajouter les traductions FR/EN/ZH

### T.17 — Superviseur Flotte : Vue Chauffeurs
- [x] T.17.1 Affectation : Permettre l'affectation d'un chauffeur à un Camion ou à une Zone
- [x] T.17.2 Hiérarchie : Gérer les rangs des chauffeurs (Principal / Secondaire / Remplaçant)
- [x] T.17.3 Mettre à jour ShiftModel / TruckModel pour stocker le rang du chauffeur
- [x] T.17.4 Ajouter les traductions FR/EN/ZH

### T.18 — Superviseur Flotte : Vue Inspection
- [x] T.18.1 Recherche rapide : Recherche par plaque ou numéro interne dans la liste d'inspection
- [x] T.18.2 États du véhicule : Ajouter les statuts "Accidenté" et "Autres" aux options existantes
- [x] T.18.3 Mettre à jour InspectionModel et les providers associés
- [x] T.18.4 Ajouter les traductions FR/EN/ZH

### T.19 — Superviseur Flotte : Vue Affectation & Vacation
- [x] T.19.1 Règle métier (Critique) : Bloquer l'affectation d'un chauffeur déjà affecté à un autre camion actif
- [x] T.19.2 Afficher un message d'erreur explicite si la règle est violée
- [x] T.19.3 Ajouter les traductions FR/EN/ZH

### T.20 — Superviseur Flotte : Réorganisation du flux de navigation (UX/UI)
- [x] T.20.1 Réordonner les onglets/vues selon l'ordre logique métier :
  Vue d'ensemble ➔ Inspection ➔ Affectation ➔ Vacation ➔ Véhicules ➔ Chauffeurs ➔ Demande de carburant ➔ Rapport Carburant

### T.21 — Menu Statistiques : Tableau comparatif flottes (Export Excel/PDF)
- [x] T.21.1 Créer un nouveau menu "Statistiques" accessible depuis le dashboard (direction / responsableOperations)
- [x] T.21.2 Permettre la sélection des indicateurs à afficher dans le tableau comparatif (colonnes configurables)
- [x] T.21.3 Générer le tableau comparatif multi-flottes avec les indicateurs sélectionnés
- [x] T.21.4 Exporter le tableau en Excel (xlsx) et en PDF
- [x] T.21.5 Ajouter les traductions FR/EN/ZH

### T.22 — Rapport Carburant : Export PDF/Excel/CSV + Vue Direction
- [x] T.22.1 Ajouter export CSV, Excel, PDF dans FuelReportScreen (vue superviseur flotte)
- [x] T.22.2 Créer DirectionFuelReportScreen : rapport carburant global avec filtre flotte + date + véhicule
- [x] T.22.3 Ajouter menu "Rapport Carburant Global" dans la navigation direction (index 10)
- [x] T.22.4 Ajouter les traductions FR/EN/ZH

## Rôles du système
| Rôle | Description |
|------|-------------|
| chauffeur | Conduit les camions |
| pompiste | Sert le carburant |
| superviseurFlotte | Gère une flotte, inspections, affectations |
| superviseurGeneral | Supervise toutes les flottes |
| superviseurMine | Pointeur à la mine (pesée) |
| superviseurPort | Pointeur au port (pesée) |
| chefRavitaillement | Supervise le ravitaillement |
| responsableApprovisionnement | Gestion approvisionnement |
| responsableOperations | KPIs et rapports |
| centreTechnique | Diagnostic et réparation pannes |
| direction | Accès complet |

## Règles
- Toujours lancer `flutter analyze` après modifications
- Ajouter les traductions FR/EN/ZH pour tout nouveau texte
- Suivre le pattern existant des autres features
- Un prompt = une tâche atomique
- Cocher les cases après chaque tâche terminée

---

## 🔲 EN COURS : Refactor Responsive (Itération 3)

### Contexte & Bilan de l'audit
- 23 écrans au total, aucun pleinement responsive
- Breakpoints déjà définis dans `lib/core/utils/extensions.dart` (`isMobile` < 600, `isTablet` 600–1200, `isDesktop` >= 1200)
- Text scaling limité dans `main.dart` (0.8–1.3x) — OK
- **Problèmes critiques :** tailles de police hardcodées, largeurs fixes en pixels (sidebar 220–280px), zéro `LayoutBuilder` dans les écrans de données, navigation non adaptative, `AppSpacing` constants non proportionnels

### Breakpoints de référence
| Breakpoint | Largeur | Cible |
|---|---|---|
| Mobile | < 600px | Téléphones portrait |
| Tablet | 600–1200px | Tablettes, téléphones landscape |
| Desktop | >= 1200px | Grands écrans, web |

---

### R.1 — Phase 1 : Fondations responsives
> Créer les utilitaires centraux partagés par tous les écrans

- [x] R.1.1 Créer `lib/core/utils/responsive_helper.dart` — widget `ResponsiveLayout` + helper `responsiveValue<T>(mobile, tablet, desktop)`
- [x] R.1.2 Ajouter `responsivePadding`, `responsiveFontScale` et `responsiveIconSize` à `ContextExtensions` dans `extensions.dart`
- [x] R.1.3 Mettre à jour `app_theme.dart` pour des tailles de police scalables (facteur selon breakpoint)
- [x] R.1.4 Lancer `flutter analyze` et valider

### R.2 — Phase 2 : Navigation adaptative
> Adapter le shell principal de navigation selon la taille d'écran

- [x] R.2.1 `dashboard_screen.dart` : sidebar fixe (desktop) → `NavigationRail` (tablet) → `Drawer` + `BottomNavigationBar` ou `NavigationDrawer` (mobile)
- [x] R.2.2 Vérifier que tous les rôles bénéficient du nouveau shell de navigation
- [x] R.2.3 Lancer `flutter analyze` et valider

### R.3 — Phase 3 : Écrans critiques
> Écrans les plus utilisés / les plus cassés sur mobile

- [x] R.3.1 `fleet_supervisor_dashboard_screen.dart` — grille actions responsive (2/3/4 cols) + icon sizes adaptatifs
- [x] R.3.2 `truck_management_screen.dart` — tableau → cards sur mobile, stats 2×2, filtres empilés
- [x] R.3.3 `user_management_screen.dart` — search bar empilée sur mobile, padding responsive
- [x] R.3.4 `statistics/fleet_statistics_screen.dart` — header boutons compacts sur mobile (icône seule), sous-widgets déjà responsives
- [x] R.3.5 Lancer `flutter analyze` et valider

### R.4 — Phase 4 : Écrans haute priorité
> Écrans métier fréquemment utilisés

- [x] R.4.1 `fuel_supply_manager_screen.dart` — header OK (Expanded), tabs OK (Expanded)
- [x] R.4.2 `fuel_report_screen.dart` — padding empty-state responsive
- [x] R.4.3 `direction_fuel_report_screen.dart` — padding empty-state responsive
- [x] R.4.4 `operations_manager_screen.dart` — padding dashboard responsive, KPI déjà en 2×2
- [x] R.4.5 `general_supervisor_screen.dart` — stat row 3-col → Wrap 2-col sur mobile
- [x] R.4.6 `inspection_list_screen.dart` — padding responsive
- [x] R.4.7 Lancer `flutter analyze` et valider

### R.5 — Phase 5 : Écrans secondaires
> Écrans détail, formulaires, écrans spécialisés

- [x] R.5.1 `login_screen.dart` — déjà responsive (tablet/mobile layout, SingleChildScrollView) ✅
- [x] R.5.2 `fleet_list_screen.dart`, `fleet_detail_screen.dart` — Rows utilisent Expanded ✅
- [x] R.5.3 `truck_dashboard_screen.dart` — header padding responsive + LayoutBuilder wide/narrow existant ✅
- [x] R.5.4 `chauffeur_screen.dart` — Flexible sur textes à risque (immatriculation + heure); driver_list/detail OK ✅
- [x] R.5.5 `fuel_attendant_screen.dart`, `ravitaillement_screen.dart` — layout colonne unique, dialogs contraints ✅
- [x] R.5.6 `unified_weighing_screen.dart` — Rows utilisent Expanded ✅
- [x] R.5.7 `technical_center_screen.dart` — Rows utilisent Expanded ✅
- [x] R.5.8 `settings_screen.dart` — header Row avec Expanded ✅
- [x] R.5.9 Lancer `flutter analyze` et valider

### R.6 — Phase 6 : Tests & validation finale
- [ ] R.6.1 Tester tous les écrans en 360×640 (mobile portrait)
- [ ] R.6.2 Tester tous les écrans en 768×1024 (tablette portrait)
- [ ] R.6.3 Tester les orientations landscape pour les écrans clés
- [ ] R.6.4 Vérifier tous les rôles (chauffeur, superviseurFlotte, direction, pompiste…)
- [ ] R.6.5 Vérifier le text scaling (0.8–1.3x) sur tous les écrans
- [ ] R.6.6 Vérifier `SafeArea` présent sur tous les écrans (notches, barres système)

---

## 🔲 EN COURS : Règles Métier & Correctifs (Itération 4)

### T.23 — Rapports : Affichage des filtres dans les exports
> Tous les rapports (PDF, Excel, CSV, XML) doivent refléter les filtres appliqués

- [x] T.23.1 Inclure les dates de filtre sélectionnées dans l'en-tête de chaque rapport exporté
- [x] T.23.2 Inclure les autres filtres actifs (camion, flotte, véhicule…) dans l'en-tête si renseignés
- [x] T.23.3 Ajouter les traductions FR/EN/ZH

---

### T.24 — Gestionnaire Principal : Corrections & Améliorations
> Corrections de bugs et nouvelles capacités pour le rôle gestionnaire

- [x] T.24.1 Dashboard camion : Afficher immatriculation + No interne **avant** la marque et le modèle dans la carte récapitulative
- [x] T.24.2 Bug : Corriger l'impossibilité d'assigner un chauffeur et un véhicule après création d'une flotte
- [x] T.24.3 Lier les demandes de carburant des superviseurs au stock principal (pompiste) — variations du stock reflétées en temps réel
- [x] T.24.4 Rendre visibles chez le gestionnaire les photos (reçus, bons) prises par les superviseurs et pompistes
- [x] T.24.5 Verrouiller la suppression d'un ravitaillement après validation par le fournisseur (lecture seule)
- [x] T.24.6 Permettre la suppression d'une flotte (avec confirmation + contrôle des dépendances actives)
- [x] T.24.7 Ajouter les traductions FR/EN/ZH

---

### T.25 — Superviseur Flotte : Règles Métier & UX
> Renforcement des contraintes métier et amélioration de l'expérience superviseur

- [x] T.25.1 Restreindre toutes les vues du superviseur à sa propre flotte (véhicules, chauffeurs, inspections, carburant…)
- [x] T.25.2 Verrouiller les assignations véhicules et chauffeurs une fois l'affectation active (pas de modification libre)
- [x] T.25.3 Vacation : Le superviseur choisit le chauffeur principal dans une liste avant de démarrer — la vacation ne peut démarrer sans chauffeur principal sélectionné
- [x] T.25.4 Conserver les affectations chauffeur/véhicule après fin de vacation — aucune suppression automatique ; le superviseur doit explicitement réaffecter
- [x] T.25.5 Interdire au superviseur le retrait d'un véhicule ou d'un chauffeur de la flotte (opération réservée au gestionnaire principal)
- [x] T.25.6 Alerte "Hors service" : permettre de signaler l'immobilisation d'un camion (grève, accident, route bloquée…) avec horodatage et calcul de la durée hors service
- [x] T.25.7 Volet "Vacation en cours" : afficher les informations de la demande de carburant validée par le pompiste + les pesées enregistrées par les pointeurs
- [x] T.25.8 Alerte de fin de vacation : notification automatique envoyée au superviseur flotte lorsqu'un pointeur (mine ou port) valide la dernière pesée
- [x] T.25.9 Verrouiller la demande de carburant tant que la vacation n'a pas démarré ⚠️ Règle assouplie par T.28 (Itération 5)
- [x] T.25.10 Ajouter les traductions FR/EN/ZH

---

### T.26 — Pompiste : Saisies Obligatoires & Export
> Renforcement des contrôles de saisie et amélioration de l'export

- [x] T.26.1 Rendre obligatoire la saisie du No de reçu de la demande de carburant (blocage si absent)
- [x] T.26.2 Afficher la date et l'heure de la prise de carburant sur le bon exporté
- [x] T.26.3 Rendre obligatoire la photo du bon lors de la saisie du litrage (blocage si aucune photo)
- [x] T.26.4 Ajouter une case "Observation" pour signaler un écart entre la quantité demandée et la quantité servie
- [x] T.26.5 Ajouter les traductions FR/EN/ZH

---

### T.27 — Superviseur Mine/Port/Stockage : Règles Métier & Nouveau Site
> No de bon obligatoire, nouveau site stockage, filtrage des véhicules en vacation

- [x] T.27.1 Rendre obligatoire la saisie du No de bon ; rejeter le No de bon à la sortie s'il ne correspond pas à celui saisi à l'entrée
- [x] T.27.2 Créer un troisième site **"Stockage"** : lieu de déchargement pour la zone mine et de chargement pour la zone port
  - Alerte → superviseur flotte zone mine : notifie le déchargement d'un camion (permet de terminer la vacation et d'en démarrer une nouvelle)
  - Alerte → superviseur flotte zone port : notifie le chargement d'un camion (permet de démarrer une vacation)
- [x] T.27.3 Afficher uniquement les véhicules en vacation active dans les interfaces mine/port/stockage
- [x] T.27.4 Générer automatiquement le No de bon de sortie identique à celui de l'entrée — y compris pour les véhicules remis en circulation après une mise en attente
- [x] T.27.5 Ajouter les traductions FR/EN/ZH

---

## ✅ TERMINÉ : Corrections & Refonte Vacation (Itération 5)

### T.28 — Demande Carburant : Indépendance vis-à-vis de la vacation
> Assouplissement de la règle T.25.9 — la demande de carburant ne doit plus être conditionnée au démarrage de la vacation

- [x] T.28.1 Retirer le verrou bloquant la demande de carburant tant que la vacation n'est pas démarrée (annule T.25.9)
- [x] T.28.2 Permettre d'effectuer une demande de carburant indépendamment du statut de la vacation (démarrée ou non)
- [x] T.28.3 Vérifier les écrans/messages d'erreur impactés (superviseur flotte, pompiste) et les mettre à jour en conséquence
- [x] T.28.4 Ajouter les traductions FR/EN/ZH

### T.29 — Bug : Visibilité des images sur ordinateur (desktop)
> Les photos (bons, reçus, pannes…) ne s'affichent que sur tablette, pas sur ordinateur, et ce pour tous les comptes

- [x] T.29.1 Identifier la cause : aucune condition `isDesktop`/`isTablet` ne cache les images dans le code (vérifié par recherche exhaustive) ⚠️ Cause probable hors code Dart — absence de configuration CORS sur le bucket Firebase Storage (`cors.json` créé, à appliquer via `gsutil cors set cors.json gs://soguifleet-manager.firebasestorage.app`)
- [x] T.29.2 Corriger les `errorBuilder` qui rendaient les images totalement invisibles en cas d'échec de chargement (`fuel_supply_manager_screen.dart`, `fleet_detail_screen.dart` — remplacés par un placeholder visible + indicateur de chargement)
- [ ] T.29.3 Vérifier le rendu sur mobile, tablette et desktop après correction ⚠️ Nécessite un test manuel dans le navigateur (non réalisable depuis cet environnement) — à confirmer après déploiement + application du CORS

### T.30 — Inspection : Photos non obligatoires + Propagation des statuts
> Assouplir la contrainte photo et corriger la synchronisation du statut véhicule entre comptes

- [x] T.30.1 Retirer l'obligation de prise de photo sur les statuts qui la requièrent actuellement dans l'inspection
- [x] T.30.2 Bug (Critique) : Corriger la propagation du changement de statut d'un camion (inspection) vers tous les comptes concernés — cause identifiée : `InspectionRepository.addInspection` ne mettait jamais à jour `trucks/{truckId}.statut` (seul `TruckStatus.enService` par défaut donnait l'illusion que "Bon état" fonctionnait). Ajout du mapping `VehicleState → TruckStatus` et écriture Firestore systématique
- [x] T.30.3 Vérifié : les écrans consommateurs (direction, superviseur flotte) font déjà un `switch` exhaustif sur `TruckStatus` — la correction de l'écriture suffit à propager tous les statuts (panne, accidenté, autres…) partout où le statut est déjà affiché
- [x] T.30.4 Ajouter les traductions FR/EN/ZH si nécessaire — aucune nouvelle chaîne introduite, pas de traduction requise

### T.31 — Refonte de la Vue Vacation (Superviseur Flotte)
> Nouvelle structure à deux onglets avec code couleur pour les vacations en cours et vue façon rapport carburant pour l'historique

- [x] T.31.1 Onglet "Vacation en cours" : liste des vacations en cours avec les informations du camion en cours de vacation
- [x] T.31.2 Onglet "Période & Historique" : liste des vacations terminées de la flotte avec système de filtre par période
- [x] T.31.3 Détail vacation (au clic) : afficher toutes les informations liées à la vacation sélectionnée — réutilise `_buildShiftDetailView` déjà existante (onglets Carburant/Pesées, impression)
- [x] T.31.4 Vacation en cours → liste des véhicules en vacation avec code couleur (clic sur une carte → détail) :
  - 🟡 Jaune : pesée non encore enregistrée (`weighingsByShiftProvider` vide)
  - 🟢 Vert : pesée déjà enregistrée
  - 🔴 Rouge : statut de service passé en "panne" via le volet inspection (`truck.statut == TruckStatus.enPanne`, prioritaire)
- [x] T.31.5 Vacations terminées (historique) → affichage façon `FuelReportScreen` :
  - Filtre de période en haut
  - Liste des véhicules de la flotte en bas (sélection multiple par chips)
  - Recherche → regroupement par véhicule avec nombre de vacations effectuées sur la période (liste dépliable, clic sur une vacation → détail)
- [x] T.31.6 Ajouter les traductions FR/EN/ZH

### T.32 — Profil Direction : Corrections & Nouvelles Fonctionnalités
- [x] T.32.1 Afficher les images (bons, reçus, pannes…) prises par superviseurs/pompistes/pointeurs dans le détail des demandes de carburant (vue direction) — ajout des photos de la dernière inspection véhicule (`lastInspectionForTruckProvider`) dans `FuelRequestDetailSheet`, en complément de la photo du bon déjà affichée
- [x] T.32.2 Permettre la suppression d'un chauffeur depuis le menu Chauffeurs (cas de démission) — bouton supprimer avec confirmation dans `driver_list_screen.dart` (désactivation logique via `deactivateUser`, cohérent avec le pattern existant ; le chauffeur disparaît de la liste qui filtre déjà `isActive`)
- [x] T.32.3 Bug Dashboard (Critique) : Corriger le filtre de date par véhicule — cause identifiée dans `direction_fuel_section.dart` : seul le filtre véhicule était appliqué, le filtre date (`DashboardFilter.matchesDate`) était ignoré. Corrigé
- [x] T.32.4 Volet Flotte : Ajouter un 4ème menu "Pesée" après (Véhicules, Chauffeurs, Demande de carburant) — `fleet_detail_screen.dart` (nouvel onglet `_WeighingsTab`)
- [x] T.32.5 Ajouter dans chacun des 4 menus du volet Flotte un filtre de recherche (par nom de l'élément ou par date) — `_FleetTabSearchBar` partagée, appliquée aux 4 onglets
- [x] T.32.6 Rapport Carburant : Ajouter un filtre par colonne, répercuté dans le fichier exporté (PDF/Excel/CSV) — implémenté dans `fuel_report_screen.dart` (superviseur, en-têtes centralisées ajoutées) et `direction_fuel_report_screen.dart` (déjà centralisé)
- [x] T.32.7 Ajouter les traductions FR/EN/ZH
