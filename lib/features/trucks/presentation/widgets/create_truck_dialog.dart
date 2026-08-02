import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/truck_model.dart';
import '../providers/truck_providers.dart';

/// Modèles de véhicules pré-configurés
enum TruckTemplate {
  none('Aucun (saisie manuelle)', ''),
  benneMonobloc8x4('Benne Monobloc 8x4', 'DFV3319GP6DJ'),
  tracteur6x4('Tracteur 6x4 460ch', 'EQ4250GD5D-T54M3'),
  semiRemorqueBenne('Semi-remorque Benne 50m³', 'ZJV9950UZX');

  const TruckTemplate(this.displayName, this.modelCode);
  final String displayName;
  final String modelCode;
}

/// Dialog pour créer un nouveau camion avec formulaire multi-étapes
class CreateTruckDialog extends ConsumerStatefulWidget {
  const CreateTruckDialog({super.key});

  @override
  ConsumerState<CreateTruckDialog> createState() => _CreateTruckDialogState();
}

class _CreateTruckDialogState extends ConsumerState<CreateTruckDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs pour les champs obligatoires
  final _proprietaireController = TextEditingController();
  final _numeroFlotteController = TextEditingController();
  final _immatriculationController = TextEditingController();
  final _vinController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _anneeFabricationController = TextEditingController();
  final _kilometrageInitialController = TextEditingController();
  final _kilometrageActuelController = TextEditingController();

  // Contrôleurs optionnels
  final _numeroCarteGriseController = TextEditingController();
  final _paysOrigineController = TextEditingController();
  final _couleurController = TextEditingController();
  final _numeroMoteurController = TextEditingController();
  final _normeMoteurController = TextEditingController();
  final _radarNumberController = TextEditingController();
  final _puissanceCVController = TextEditingController();
  final _puissanceKWController = TextEditingController();
  final _cylindreeController = TextEditingController();
  final _capaciteReservoirController = TextEditingController();
  final _nombreRapportsController = TextEditingController();
  final _typeEmbrayageController = TextEditingController();
  final _poidsAVideController = TextEditingController();
  final _ptacController = TextEditingController();
  final _ptraController = TextEditingController();
  final _chargeUtileMaxController = TextEditingController();
  final _volumeUtileController = TextEditingController();
  final _longueurController = TextEditingController();
  final _largeurController = TextEditingController();
  final _hauteurController = TextEditingController();
  final _frequenceEntretienKmController = TextEditingController();
  final _typeMoteurController = TextEditingController();
  final _siteAffectationController = TextEditingController();
  final _notesController = TextEditingController();

  // Template sélectionné
  TruckTemplate _selectedTemplate = TruckTemplate.none;

  // Valeurs sélectionnées
  TruckType _selectedType = TruckType.porteur;
  TruckConfiguration _selectedConfiguration = TruckConfiguration.config4x2;
  TruckStatus _selectedStatut = TruckStatus.enService;
  FuelType? _selectedCarburant;
  GearboxType? _selectedBoiteVitesses;
  ActivityType? _selectedActivite;
  MaintenancePlan? _selectedPlanMaintenance;

  // Dates
  DateTime? _dateMiseEnCirculation;
  DateTime _dateEntreeFlotte = DateTime.now();

  /// Applique les valeurs pré-remplies selon le template sélectionné
  void _applyTemplate(TruckTemplate template) {
    setState(() {
      _selectedTemplate = template;

      // Réinitialiser les champs si "Aucun" est sélectionné
      if (template == TruckTemplate.none) {
        _marqueController.clear();
        _modeleController.clear();
        _paysOrigineController.clear();
        _selectedType = TruckType.porteur;
        _selectedConfiguration = TruckConfiguration.config4x2;
        _normeMoteurController.clear();
        _typeMoteurController.clear();
        _puissanceCVController.clear();
        _puissanceKWController.clear();
        _cylindreeController.clear();
        _selectedCarburant = null;
        _capaciteReservoirController.clear();
        _selectedBoiteVitesses = null;
        _nombreRapportsController.clear();
        _typeEmbrayageController.clear();
        _poidsAVideController.clear();
        _ptacController.clear();
        _ptraController.clear();
        _chargeUtileMaxController.clear();
        _volumeUtileController.clear();
        _longueurController.clear();
        _largeurController.clear();
        _hauteurController.clear();
        _selectedActivite = null;
        _selectedPlanMaintenance = null;
        _frequenceEntretienKmController.clear();
        return;
      }

      switch (template) {
        case TruckTemplate.benneMonobloc8x4:
          _marqueController.text = 'Dongfeng';
          _modeleController.text = 'DFV3319GP6DJ';
          _paysOrigineController.text = 'Chine';
          _selectedType = TruckType.benne;
          _selectedConfiguration = TruckConfiguration.config8x4;
          _normeMoteurController.text = 'Euro II';
          _typeMoteurController.text = 'Yuchai YC6MK400-33';
          _puissanceCVController.text = '400';
          _puissanceKWController.text = '294';
          _cylindreeController.text = '10338';
          _selectedCarburant = FuelType.diesel;
          _capaciteReservoirController.text = '400';
          _selectedBoiteVitesses = GearboxType.manuelle;
          _nombreRapportsController.text = '12';
          _typeEmbrayageController.text = 'Pneumatique à assistance hydraulique - Ø430mm';
          _poidsAVideController.text = '21500';
          _ptacController.text = '80000';
          _ptraController.clear();
          _chargeUtileMaxController.clear();
          _volumeUtileController.clear();
          _longueurController.text = '10.800';
          _largeurController.text = '2.715';
          _hauteurController.text = '3.680';
          _selectedActivite = ActivityType.chantier;
          _selectedPlanMaintenance = MaintenancePlan.parKilometrage;
          _frequenceEntretienKmController.text = '10000';
          break;

        case TruckTemplate.tracteur6x4:
          _marqueController.text = 'Dongfeng';
          _modeleController.text = 'EQ4250GD5D-T54M3';
          _paysOrigineController.text = 'Chine';
          _selectedType = TruckType.tracteurRoutier;
          _selectedConfiguration = TruckConfiguration.config6x4;
          _normeMoteurController.text = 'Euro II';
          _typeMoteurController.text = 'Yuchai YC6MJ460-33';
          _puissanceCVController.text = '460';
          _puissanceKWController.text = '326';
          _cylindreeController.text = '11700';
          _selectedCarburant = FuelType.diesel;
          _capaciteReservoirController.text = '400';
          _selectedBoiteVitesses = GearboxType.manuelle;
          _nombreRapportsController.text = '12';
          _typeEmbrayageController.text = 'Pneumatique à assistance hydraulique - Ø430mm';
          _poidsAVideController.text = '11800';
          _ptacController.clear();
          _ptraController.text = '120000';
          _chargeUtileMaxController.clear();
          _volumeUtileController.clear();
          _longueurController.text = '7.010';
          _largeurController.text = '2.550';
          _hauteurController.text = '3.300';
          _selectedActivite = ActivityType.longCourrier;
          _selectedPlanMaintenance = MaintenancePlan.parKilometrage;
          _frequenceEntretienKmController.text = '15000';
          break;

        case TruckTemplate.semiRemorqueBenne:
          _marqueController.text = 'CIMC';
          _modeleController.text = 'ZJV9950UZX';
          _paysOrigineController.text = 'Chine';
          _selectedType = TruckType.benne;
          _selectedConfiguration = TruckConfiguration.config6x4;
          _normeMoteurController.clear();
          _typeMoteurController.clear();
          _puissanceCVController.clear();
          _puissanceKWController.clear();
          _cylindreeController.clear();
          _selectedCarburant = null;
          _capaciteReservoirController.clear();
          _selectedBoiteVitesses = null;
          _nombreRapportsController.clear();
          _typeEmbrayageController.clear();
          _poidsAVideController.text = '16000';
          _ptacController.text = '96000';
          _ptraController.clear();
          _chargeUtileMaxController.text = '80';
          _volumeUtileController.text = '50';
          _longueurController.text = '10.320';
          _largeurController.text = '3.010';
          _hauteurController.text = '3.900';
          _selectedActivite = ActivityType.mine;
          _selectedPlanMaintenance = MaintenancePlan.parKilometrage;
          _frequenceEntretienKmController.text = '20000';
          break;

        case TruckTemplate.none:
          break;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _proprietaireController.dispose();
    _numeroFlotteController.dispose();
    _immatriculationController.dispose();
    _vinController.dispose();
    _marqueController.dispose();
    _modeleController.dispose();
    _anneeFabricationController.dispose();
    _kilometrageInitialController.dispose();
    _kilometrageActuelController.dispose();
    _numeroCarteGriseController.dispose();
    _paysOrigineController.dispose();
    _couleurController.dispose();
    _numeroMoteurController.dispose();
    _normeMoteurController.dispose();
    _radarNumberController.dispose();
    _puissanceCVController.dispose();
    _puissanceKWController.dispose();
    _cylindreeController.dispose();
    _capaciteReservoirController.dispose();
    _nombreRapportsController.dispose();
    _typeEmbrayageController.dispose();
    _poidsAVideController.dispose();
    _ptacController.dispose();
    _ptraController.dispose();
    _chargeUtileMaxController.dispose();
    _volumeUtileController.dispose();
    _longueurController.dispose();
    _largeurController.dispose();
    _hauteurController.dispose();
    _frequenceEntretienKmController.dispose();
    _typeMoteurController.dispose();
    _siteAffectationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (_currentStep < 3) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
        await _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      await _createTruck();
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      await _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createTruck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(truckRepositoryProvider);

      final truck = TruckModel(
        id: '', // Sera généré par Firestore
        proprietaire: _proprietaireController.text,
        numeroInterneFlotte: _numeroFlotteController.text,
        immatriculation: _immatriculationController.text,
        numeroChassis: _vinController.text,
        marque: _marqueController.text,
        modele: _modeleController.text,
        anneeFabrication: int.parse(_anneeFabricationController.text),
        numeroCarteGrise: _numeroCarteGriseController.text.isEmpty
            ? null
            : _numeroCarteGriseController.text,
        dateMiseEnCirculation: _dateMiseEnCirculation,
        dateEntreeFlotte: _dateEntreeFlotte,
        paysOrigine: _paysOrigineController.text.isEmpty
            ? null
            : _paysOrigineController.text,
        type: _selectedType,
        configuration: _selectedConfiguration,
        couleur: _couleurController.text.isEmpty
            ? null
            : _couleurController.text,
        numeroMoteur: _numeroMoteurController.text.isEmpty
            ? null
            : _numeroMoteurController.text,
        normeMoteur: _normeMoteurController.text.isEmpty
            ? null
            : _normeMoteurController.text,
        radarNumber: _radarNumberController.text.isEmpty
            ? null
            : _radarNumberController.text,
        typeMoteur: _typeMoteurController.text.isEmpty
            ? null
            : _typeMoteurController.text,
        puissanceCV: _puissanceCVController.text.isEmpty
            ? null
            : int.parse(_puissanceCVController.text),
        puissanceKW: _puissanceKWController.text.isEmpty
            ? null
            : int.parse(_puissanceKWController.text),
        cylindree: _cylindreeController.text.isEmpty
            ? null
            : int.parse(_cylindreeController.text),
        typeCarburant: _selectedCarburant,
        capaciteReservoir: _capaciteReservoirController.text.isEmpty
            ? null
            : int.parse(_capaciteReservoirController.text),
        boiteVitesses: _selectedBoiteVitesses,
        nombreRapports: _nombreRapportsController.text.isEmpty
            ? null
            : int.parse(_nombreRapportsController.text),
        typeEmbrayage: _typeEmbrayageController.text.isEmpty
            ? null
            : _typeEmbrayageController.text,
        poidsAVide: _poidsAVideController.text.isEmpty
            ? null
            : double.parse(_poidsAVideController.text),
        ptac: _ptacController.text.isEmpty
            ? null
            : double.parse(_ptacController.text),
        ptra: _ptraController.text.isEmpty
            ? null
            : double.parse(_ptraController.text),
        chargeUtileMax: _chargeUtileMaxController.text.isEmpty
            ? null
            : double.parse(_chargeUtileMaxController.text),
        volumeUtile: _volumeUtileController.text.isEmpty
            ? null
            : double.parse(_volumeUtileController.text),
        longueur: _longueurController.text.isEmpty
            ? null
            : double.parse(_longueurController.text),
        largeur: _largeurController.text.isEmpty
            ? null
            : double.parse(_largeurController.text),
        hauteur: _hauteurController.text.isEmpty
            ? null
            : double.parse(_hauteurController.text),
        statut: _selectedStatut,
        siteAffectation: _siteAffectationController.text.isEmpty
            ? null
            : _siteAffectationController.text,
        typeActivite: _selectedActivite,
        planMaintenance: _selectedPlanMaintenance,
        frequenceEntretienKm: _frequenceEntretienKmController.text.isEmpty
            ? null
            : int.parse(_frequenceEntretienKmController.text),
        kilometrageInitial: int.parse(_kilometrageInitialController.text),
        kilometrageActuel: int.parse(_kilometrageActuelController.text),
        createdAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await repository.createTruck(truck);

      // Invalider le provider pour recharger les données
      ref.invalidate(activeTrucksProvider);
      ref.invalidate(truckStatsByStatusProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('trucks.createTruck.success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('trucks.createTruck.error')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildStepIndicator(),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(
            Iconsax.truck,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('trucks.createTruck.title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('trucks.fields.immatriculation'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.close_square, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.translate('trucks.createTruck.step1'),
      l10n.translate('trucks.createTruck.step2'),
      l10n.translate('trucks.createTruck.step3'),
      l10n.translate('trucks.createTruck.step4'),
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive || isCompleted
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive || isCompleted
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Container(
                  width: 20,
                  height: 2,
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.textSecondary.withValues(alpha: 0.3),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step1Description'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Sélecteur de modèle pré-configuré
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Iconsax.magic_star, color: AppColors.primary, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Modèle pré-configuré',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildDropdown<TruckTemplate>(
                  label: 'Sélectionner un modèle pour pré-remplir les champs',
                  value: _selectedTemplate,
                  items: TruckTemplate.values,
                  itemLabel: (template) => template == TruckTemplate.none
                      ? template.displayName
                      : '${template.displayName} (${template.modelCode})',
                  onChanged: (value) {
                    if (value != null) {
                      _applyTemplate(value);
                    }
                  },
                  icon: Iconsax.document,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _proprietaireController,
                  label: '${l10n.translate('trucks.fields.proprietaire')} *',
                  hint: l10n.translate('trucks.placeholders.proprietaire'),
                  icon: Iconsax.user,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _numeroFlotteController,
                  label: '${l10n.translate('trucks.fields.numeroInterneFlotte')} *',
                  hint: l10n.translate('trucks.placeholders.numeroInterneFlotte'),
                  icon: Iconsax.hashtag,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _radarNumberController,
            label: l10n.translate('trucks.fields.radarNumber'),
            hint: l10n.translate('trucks.placeholders.radarNumber'),
            icon: Iconsax.radar,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _immatriculationController,
                  label: '${l10n.translate('trucks.fields.immatriculation')} *',
                  hint: l10n.translate('trucks.placeholders.immatriculation'),
                  icon: Iconsax.card,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _vinController,
                  label: '${l10n.translate('trucks.fields.numeroChassis')} *',
                  hint: l10n.translate('trucks.placeholders.numeroChassis'),
                  icon: Iconsax.scan_barcode,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _marqueController,
                  label: '${l10n.translate('trucks.fields.marque')} *',
                  hint: l10n.translate('trucks.placeholders.marque'),
                  icon: Iconsax.tag,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _modeleController,
                  label: '${l10n.translate('trucks.fields.modele')} *',
                  hint: l10n.translate('trucks.placeholders.modele'),
                  icon: Iconsax.tag,
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _anneeFabricationController,
                  label: '${l10n.translate('trucks.fields.anneeFabrication')} *',
                  hint: l10n.translate('trucks.placeholders.anneeFabrication'),
                  icon: Iconsax.calendar,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return l10n.translate('trucks.createTruck.validation.required');
                    final year = int.tryParse(value!);
                    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                      return l10n.translate('trucks.createTruck.validation.yearInvalid').replaceAll('{year}', '${DateTime.now().year + 1}');
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _numeroCarteGriseController,
                  label: l10n.translate('trucks.fields.numeroCarteGrise'),
                  hint: l10n.translate('trucks.placeholders.immatriculation'),
                  icon: Iconsax.card,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<TruckType>(
                  label: '${l10n.translate('trucks.fields.type')} *',
                  value: _selectedType,
                  items: TruckType.values,
                  itemLabel: (type) => _getTruckTypeLabel(type, l10n),
                  onChanged: (value) => setState(() => _selectedType = value!),
                  icon: Iconsax.truck,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdown<TruckConfiguration>(
                  label: '${l10n.translate('trucks.fields.configuration')} *',
                  value: _selectedConfiguration,
                  items: TruckConfiguration.values,
                  itemLabel: (config) => _getConfigurationLabel(config, l10n),
                  onChanged: (value) =>
                      setState(() => _selectedConfiguration = value!),
                  icon: Iconsax.setting_2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step2Description'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _couleurController,
                  label: l10n.translate('trucks.fields.couleur'),
                  hint: l10n.translate('trucks.placeholders.couleur'),
                  icon: Iconsax.brush_1,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _paysOrigineController,
                  label: l10n.translate('trucks.fields.paysOrigine'),
                  hint: l10n.translate('trucks.placeholders.immatriculation'),
                  icon: Iconsax.global,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _numeroMoteurController,
                  label: l10n.translate('trucks.fields.numeroMoteur'),
                  hint: l10n.translate('trucks.placeholders.numeroMoteur'),
                  icon: Iconsax.setting_3,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _normeMoteurController,
                  label: l10n.translate('trucks.fields.normeMoteur'),
                  hint: l10n.translate('trucks.placeholders.normeMoteur'),
                  icon: Iconsax.shield_tick,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _puissanceCVController,
                  label: l10n.translate('trucks.fields.puissanceCV'),
                  hint: l10n.translate('trucks.placeholders.puissanceCV'),
                  icon: Iconsax.flash,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdown<FuelType>(
                  label: l10n.translate('trucks.fields.typeCarburant'),
                  value: _selectedCarburant,
                  items: FuelType.values,
                  itemLabel: (type) => _getFuelTypeLabel(type, l10n),
                  onChanged: (value) => setState(() => _selectedCarburant = value),
                  icon: Iconsax.gas_station,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _capaciteReservoirController,
                  label: l10n.translate('trucks.fields.capaciteReservoir'),
                  hint: l10n.translate('trucks.placeholders.capaciteReservoir'),
                  icon: Iconsax.gas_station,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdown<GearboxType>(
                  label: l10n.translate('trucks.fields.boiteVitesses'),
                  value: _selectedBoiteVitesses,
                  items: GearboxType.values,
                  itemLabel: (type) => _getGearboxTypeLabel(type, l10n),
                  onChanged: (value) =>
                      setState(() => _selectedBoiteVitesses = value),
                  icon: Iconsax.setting_2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step3Description'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<TruckStatus>(
                  label: '${l10n.translate('trucks.fields.statut')} *',
                  value: _selectedStatut,
                  items: TruckStatus.values,
                  itemLabel: (status) => _getStatusLabel(status, l10n),
                  onChanged: (value) => setState(() => _selectedStatut = value!),
                  icon: Iconsax.status,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _siteAffectationController,
                  label: l10n.translate('trucks.fields.siteAffectation'),
                  hint: l10n.translate('trucks.placeholders.siteAffectation'),
                  icon: Iconsax.location,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdown<ActivityType>(
            label: l10n.translate('trucks.fields.typeActivite'),
            value: _selectedActivite,
            items: ActivityType.values,
            itemLabel: (type) => _getActivityTypeLabel(type, l10n),
            onChanged: (value) => setState(() => _selectedActivite = value),
            icon: Iconsax.brifecase_tick,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _kilometrageInitialController,
                  label: '${l10n.translate('trucks.fields.kilometrageInitial')} *',
                  hint: l10n.translate('trucks.placeholders.kilometrageInitial'),
                  icon: Iconsax.speedometer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) =>
                      value?.isEmpty ?? true ? l10n.translate('trucks.createTruck.validation.required') : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildTextField(
                  controller: _kilometrageActuelController,
                  label: '${l10n.translate('trucks.fields.kilometrageActuel')} *',
                  hint: l10n.translate('trucks.placeholders.kilometrageActuel'),
                  icon: Iconsax.speedometer,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value?.isEmpty ?? true) return l10n.translate('trucks.createTruck.validation.required');
                    final initial = int.tryParse(_kilometrageInitialController.text) ?? 0;
                    final actuel = int.tryParse(value!) ?? 0;
                    if (actuel < initial) {
                      return l10n.translate('trucks.createTruck.validation.kmInvalid');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(
            label: '${l10n.translate('trucks.fields.dateEntreeFlotte')} *',
            value: _dateEntreeFlotte,
            onChanged: (date) => setState(() => _dateEntreeFlotte = date),
            icon: Iconsax.calendar,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(
            label: l10n.translate('trucks.fields.dateMiseEnCirculation'),
            value: _dateMiseEnCirculation,
            onChanged: (date) => setState(() => _dateMiseEnCirculation = date),
            icon: Iconsax.calendar,
            isOptional: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step4Description'),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.info_circle, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.translate('trucks.createTruck.step4Description'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSummaryItem(
                    l10n.translate('trucks.fields.immatriculation'), _immatriculationController.text),
                _buildSummaryItem(l10n.translate('trucks.fields.marque'), _marqueController.text),
                _buildSummaryItem(l10n.translate('trucks.fields.modele'), _modeleController.text),
                _buildSummaryItem(l10n.translate('trucks.fields.type'), _getTruckTypeLabel(_selectedType, l10n)),
                _buildSummaryItem(l10n.translate('trucks.fields.numeroInterneFlotte'), _numeroFlotteController.text),
                _buildSummaryItem(l10n.translate('trucks.fields.statut'), _getStatusLabel(_selectedStatut, l10n)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _notesController,
            label: l10n.translate('trucks.fields.notes'),
            hint: l10n.translate('trucks.placeholders.notes'),
            icon: Iconsax.note,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: value,
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: AppColors.surface,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required void Function(DateTime) onChanged,
    required IconData icon,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.md),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : '--/--/----',
                  style: TextStyle(
                    color: value != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Iconsax.arrow_left, size: 18),
            label: Text(l10n.translate('trucks.createTruck.previous')),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('trucks.createTruck.cancel')),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _nextStep,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _currentStep < 3 ? Iconsax.arrow_right : Iconsax.tick_circle,
                  size: 18,
                ),
          label: Text(_currentStep < 3 ? l10n.translate('trucks.createTruck.next') : l10n.translate('trucks.createTruck.create')),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods to get translated enum labels
  String _getTruckTypeLabel(TruckType type, AppLocalizations l10n) {
    switch (type) {
      case TruckType.porteur:
        return l10n.translate('trucks.types.porteur');
      case TruckType.tracteurRoutier:
        return l10n.translate('trucks.types.tracteurRoutier');
      case TruckType.benne:
        return l10n.translate('trucks.types.benne');
      case TruckType.plateau:
        return l10n.translate('trucks.types.plateau');
      case TruckType.citerne:
        return l10n.translate('trucks.types.citerne');
      case TruckType.frigorifique:
        return l10n.translate('trucks.types.frigorifique');
    }
  }

  String _getConfigurationLabel(TruckConfiguration config, AppLocalizations l10n) {
    switch (config) {
      case TruckConfiguration.config4x2:
        return l10n.translate('trucks.configuration.config4x2');
      case TruckConfiguration.config6x4:
        return l10n.translate('trucks.configuration.config6x4');
      case TruckConfiguration.config8x4:
        return l10n.translate('trucks.configuration.config8x4');
    }
  }

  String _getStatusLabel(TruckStatus status, AppLocalizations l10n) {
    switch (status) {
      case TruckStatus.enService:
        return l10n.translate('trucks.status.enService');
      case TruckStatus.enMaintenance:
        return l10n.translate('trucks.status.enMaintenance');
      case TruckStatus.enPanne:
        return l10n.translate('trucks.status.enPanne');
      case TruckStatus.immobilise:
        return l10n.translate('trucks.status.immobilise');
    }
  }

  String _getFuelTypeLabel(FuelType type, AppLocalizations l10n) {
    switch (type) {
      case FuelType.diesel:
        return l10n.translate('trucks.fuelType.diesel');
      case FuelType.essence:
        return l10n.translate('trucks.fuelType.essence');
      case FuelType.gaz:
        return l10n.translate('trucks.fuelType.gaz');
      case FuelType.electrique:
        return l10n.translate('trucks.fuelType.electrique');
      case FuelType.hybride:
        return l10n.translate('trucks.fuelType.hybride');
    }
  }

  String _getGearboxTypeLabel(GearboxType type, AppLocalizations l10n) {
    switch (type) {
      case GearboxType.manuelle:
        return l10n.translate('trucks.gearbox.manuelle');
      case GearboxType.automatique:
        return l10n.translate('trucks.gearbox.automatique');
      case GearboxType.robotisee:
        return l10n.translate('trucks.gearbox.robotisee');
    }
  }

  String _getActivityTypeLabel(ActivityType type, AppLocalizations l10n) {
    switch (type) {
      case ActivityType.mine:
        return l10n.translate('trucks.activityType.chantier');
      case ActivityType.chantier:
        return l10n.translate('trucks.activityType.chantier');
      case ActivityType.port:
        return l10n.translate('trucks.activityType.distribution');
      case ActivityType.longCourrier:
        return l10n.translate('trucks.activityType.longueDistance');
    }
  }
}
