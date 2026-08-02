import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/truck_model.dart';
import '../providers/truck_providers.dart';

/// Dialog pour éditer un camion existant avec formulaire multi-étapes
class EditTruckDialog extends ConsumerStatefulWidget {

  const EditTruckDialog({
    required this.truck, super.key,
  });
  final TruckModel truck;

  @override
  ConsumerState<EditTruckDialog> createState() => _EditTruckDialogState();
}

class _EditTruckDialogState extends ConsumerState<EditTruckDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Contrôleurs pour les champs obligatoires
  late final TextEditingController _proprietaireController;
  late final TextEditingController _numeroFlotteController;
  late final TextEditingController _immatriculationController;
  late final TextEditingController _vinController;
  late final TextEditingController _marqueController;
  late final TextEditingController _modeleController;
  late final TextEditingController _anneeFabricationController;
  late final TextEditingController _kilometrageInitialController;
  late final TextEditingController _kilometrageActuelController;

  // Contrôleurs optionnels
  late final TextEditingController _numeroCarteGriseController;
  late final TextEditingController _paysOrigineController;
  late final TextEditingController _couleurController;
  late final TextEditingController _numeroMoteurController;
  late final TextEditingController _normeMoteurController;
  late final TextEditingController _radarNumberController;
  late final TextEditingController _puissanceCVController;
  late final TextEditingController _capaciteReservoirController;
  late final TextEditingController _siteAffectationController;
  late final TextEditingController _notesController;

  // Valeurs sélectionnées
  late TruckType _selectedType;
  late TruckConfiguration _selectedConfiguration;
  late TruckStatus _selectedStatut;
  FuelType? _selectedCarburant;
  GearboxType? _selectedBoiteVitesses;
  ActivityType? _selectedActivite;

  // Dates
  DateTime? _dateMiseEnCirculation;
  late DateTime _dateEntreeFlotte;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final truck = widget.truck;

    // Initialiser les contrôleurs avec les valeurs existantes
    _proprietaireController = TextEditingController(text: truck.proprietaire);
    _numeroFlotteController = TextEditingController(text: truck.numeroInterneFlotte);
    _immatriculationController = TextEditingController(text: truck.immatriculation);
    _vinController = TextEditingController(text: truck.numeroChassis);
    _marqueController = TextEditingController(text: truck.marque);
    _modeleController = TextEditingController(text: truck.modele);
    _anneeFabricationController = TextEditingController(text: truck.anneeFabrication.toString());
    _kilometrageInitialController = TextEditingController(text: truck.kilometrageInitial.toString());
    _kilometrageActuelController = TextEditingController(text: truck.kilometrageActuel.toString());

    _numeroCarteGriseController = TextEditingController(text: truck.numeroCarteGrise ?? '');
    _paysOrigineController = TextEditingController(text: truck.paysOrigine ?? '');
    _couleurController = TextEditingController(text: truck.couleur ?? '');
    _numeroMoteurController = TextEditingController(text: truck.numeroMoteur ?? '');
    _normeMoteurController = TextEditingController(text: truck.normeMoteur ?? '');
    _radarNumberController = TextEditingController(text: truck.radarNumber ?? '');
    _puissanceCVController = TextEditingController(text: truck.puissanceCV?.toString() ?? '');
    _capaciteReservoirController = TextEditingController(text: truck.capaciteReservoir?.toString() ?? '');
    _siteAffectationController = TextEditingController(text: truck.siteAffectation ?? '');
    _notesController = TextEditingController(text: truck.notes ?? '');

    // Initialiser les valeurs sélectionnées
    _selectedType = truck.type;
    _selectedConfiguration = truck.configuration;
    _selectedStatut = truck.statut;
    _selectedCarburant = truck.typeCarburant;
    _selectedBoiteVitesses = truck.boiteVitesses;
    _selectedActivite = truck.typeActivite;

    // Initialiser les dates
    _dateMiseEnCirculation = truck.dateMiseEnCirculation;
    _dateEntreeFlotte = truck.dateEntreeFlotte;
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
    _capaciteReservoirController.dispose();
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
      await _updateTruck();
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

  Future<void> _updateTruck() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(truckRepositoryProvider);

      final updatedTruck = widget.truck.copyWith(
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
        puissanceCV: _puissanceCVController.text.isEmpty
            ? null
            : int.parse(_puissanceCVController.text),
        typeCarburant: _selectedCarburant,
        capaciteReservoir: _capaciteReservoirController.text.isEmpty
            ? null
            : int.parse(_capaciteReservoirController.text),
        boiteVitesses: _selectedBoiteVitesses,
        statut: _selectedStatut,
        siteAffectation: _siteAffectationController.text.isEmpty
            ? null
            : _siteAffectationController.text,
        typeActivite: _selectedActivite,
        kilometrageInitial: int.parse(_kilometrageInitialController.text),
        kilometrageActuel: int.parse(_kilometrageActuelController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await repository.updateTruck(updatedTruck);

      // Invalider le provider pour recharger les données
      ref.invalidate(activeTrucksProvider);
      ref.invalidate(truckStatsByStatusProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('trucks.editTruck.success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('trucks.editTruck.error')),
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
            Iconsax.edit,
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
                l10n.translate('trucks.editTruck.title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.truck.immatriculation,
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isActive || isCompleted
                            ? AppColors.primaryGradient
                            : null,
                        color: isActive || isCompleted
                            ? null
                            : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive || isCompleted
                              ? AppColors.primary
                              : AppColors.surfaceBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? AppColors.primaryGradient
                          : null,
                      color: isCompleted ? null : AppColors.surfaceBorder,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Iconsax.arrow_left_2),
            label: Text(l10n.translate('trucks.createTruck.previous')),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          )
        else
          const SizedBox(),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.translate('trucks.createTruck.cancel')),
            ),
            const SizedBox(width: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _nextStep,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      _currentStep < 3 ? Iconsax.arrow_right_3 : Iconsax.tick_circle,
                    ),
              label: Text(
                _currentStep < 3
                    ? l10n.translate('trucks.createTruck.next')
                    : l10n.translate('trucks.editTruck.update'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Étape 1 : Identification
  Widget _buildStep1() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step1Description'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
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
                    if (value?.isEmpty ?? true) {
                      return l10n.translate('trucks.createTruck.validation.required');
                    }
                    final year = int.tryParse(value!);
                    final currentYear = DateTime.now().year;
                    if (year == null || year < 1900 || year > currentYear) {
                      return l10n.translate('trucks.createTruck.validation.yearInvalid').replaceAll('{year}', currentYear.toString());
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
                  hint: l10n.translate('trucks.fields.numeroCarteGrise'),
                  icon: Iconsax.document,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: l10n.translate('trucks.fields.dateMiseEnCirculation'),
                  value: _dateMiseEnCirculation,
                  onChanged: (date) => setState(() => _dateMiseEnCirculation = date),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDateField(
                  label: l10n.translate('trucks.fields.dateEntreeFlotte'),
                  value: _dateEntreeFlotte,
                  onChanged: (date) => setState(() => _dateEntreeFlotte = date ?? DateTime.now()),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
                  hint: l10n.translate('trucks.fields.paysOrigine'),
                  icon: Iconsax.global,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Étape 2 : Caractéristiques techniques
  Widget _buildStep2() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step2Description'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<TruckType>(
                  label: '${l10n.translate('trucks.fields.type')} *',
                  value: _selectedType,
                  items: TruckType.values,
                  onChanged: (value) => setState(() => _selectedType = value!),
                  itemLabel: (type) => _getTruckTypeLabel(type, l10n),
                  icon: Iconsax.truck,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdown<TruckConfiguration>(
                  label: '${l10n.translate('trucks.fields.configuration')} *',
                  value: _selectedConfiguration,
                  items: TruckConfiguration.values,
                  onChanged: (value) => setState(() => _selectedConfiguration = value!),
                  itemLabel: (config) => _getConfigurationLabel(config, l10n),
                  icon: Iconsax.setting_2,
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
                  icon: Iconsax.document_text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildDropdown<FuelType?>(
                  label: l10n.translate('trucks.fields.typeCarburant'),
                  value: _selectedCarburant,
                  items: [null, ...FuelType.values],
                  onChanged: (value) => setState(() => _selectedCarburant = value),
                  itemLabel: (fuel) => fuel == null ? '-' : _getFuelTypeLabel(fuel, l10n),
                  icon: Iconsax.gas_station,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                child: _buildDropdown<GearboxType?>(
                  label: l10n.translate('trucks.fields.boiteVitesses'),
                  value: _selectedBoiteVitesses,
                  items: [null, ...GearboxType.values],
                  onChanged: (value) => setState(() => _selectedBoiteVitesses = value),
                  itemLabel: (gearbox) => gearbox == null ? '-' : _getGearboxTypeLabel(gearbox, l10n),
                  icon: Iconsax.setting_2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Étape 3 : Exploitation
  Widget _buildStep3() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step3Description'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDropdown<TruckStatus>(
            label: '${l10n.translate('trucks.fields.statut')} *',
            value: _selectedStatut,
            items: TruckStatus.values,
            onChanged: (value) => setState(() => _selectedStatut = value!),
            itemLabel: (status) => _getStatusLabel(status, l10n),
            icon: Iconsax.status,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _siteAffectationController,
                  label: l10n.translate('trucks.fields.siteAffectation'),
                  hint: l10n.translate('trucks.placeholders.siteAffectation'),
                  icon: Iconsax.location,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDropdown<ActivityType?>(
                  label: l10n.translate('trucks.fields.typeActivite'),
                  value: _selectedActivite,
                  items: [null, ...ActivityType.values],
                  onChanged: (value) => setState(() => _selectedActivite = value),
                  itemLabel: (activity) => activity == null ? '-' : _getActivityTypeLabel(activity, l10n),
                  icon: Iconsax.brifecase_tick,
                ),
              ),
            ],
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
                    if (value?.isEmpty ?? true) {
                      return l10n.translate('trucks.createTruck.validation.required');
                    }
                    final kmActuel = int.tryParse(value!);
                    final kmInitial = int.tryParse(_kilometrageInitialController.text);
                    if (kmActuel != null && kmInitial != null && kmActuel < kmInitial) {
                      return l10n.translate('trucks.createTruck.validation.kmInvalid');
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Étape 4 : Validation et notes
  Widget _buildStep4() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('trucks.createTruck.step4Description'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildTextField(
            controller: _notesController,
            label: l10n.translate('trucks.fields.notes'),
            hint: l10n.translate('trucks.placeholders.notes'),
            icon: Iconsax.note,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('trucks.editTruck.summary'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSummaryRow(
                  l10n.translate('trucks.fields.immatriculation'),
                  _immatriculationController.text,
                ),
                _buildSummaryRow(
                  l10n.translate('trucks.fields.marque'),
                  '${_marqueController.text} ${_modeleController.text}',
                ),
                _buildSummaryRow(
                  l10n.translate('trucks.fields.type'),
                  _getTruckTypeLabel(_selectedType, l10n),
                ),
                _buildSummaryRow(
                  l10n.translate('trucks.fields.statut'),
                  _getStatusLabel(_selectedStatut, l10n),
                ),
                _buildSummaryRow(
                  l10n.translate('trucks.fields.kilometrageActuel'),
                  '${_kilometrageActuelController.text} km',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
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
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.calendar, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value != null
                      ? DateFormat('dd/MM/yyyy').format(value)
                      : l10n.translate('common.select'),
                  style: TextStyle(
                    color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods pour les traductions d'énumérations
  String _getTruckTypeLabel(TruckType type, AppLocalizations l10n) {
    return l10n.translate('trucks.types.${type.name}');
  }

  String _getConfigurationLabel(TruckConfiguration config, AppLocalizations l10n) {
    return l10n.translate('trucks.configuration.${config.name}');
  }

  String _getStatusLabel(TruckStatus status, AppLocalizations l10n) {
    return l10n.translate('trucks.status.${status.name}');
  }

  String _getFuelTypeLabel(FuelType fuel, AppLocalizations l10n) {
    return l10n.translate('trucks.fuelType.${fuel.name}');
  }

  String _getGearboxTypeLabel(GearboxType gearbox, AppLocalizations l10n) {
    return l10n.translate('trucks.gearbox.${gearbox.name}');
  }

  String _getActivityTypeLabel(ActivityType activity, AppLocalizations l10n) {
    return l10n.translate('trucks.activityType.${activity.name}');
  }
}
