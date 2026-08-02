import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../../core/widgets/photo_picker_widget.dart';
import '../../../../services/image_service.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../domain/models/weighing_record_model.dart';
import '../providers/weighing_providers.dart';
import '../widgets/weighing_detail_dialog.dart';

/// Écran unifié pesée mine/port avec onglet En attente
class UnifiedWeighingScreen extends ConsumerStatefulWidget {
  const UnifiedWeighingScreen({
    required this.defaultLocation,
    super.key,
  });

  final WeighingLocation defaultLocation;

  @override
  ConsumerState<UnifiedWeighingScreen> createState() =>
      _UnifiedWeighingScreenState();
}

class _UnifiedWeighingScreenState
    extends ConsumerState<UnifiedWeighingScreen> {
  int _currentTab = 0;
  bool _showSettings = false;
  WeighingRecordModel? _pendingRecordToResume;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (_showSettings) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.backgroundSecondary,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left,
                    color: AppColors.textPrimary),
                onPressed: () => setState(() => _showSettings = false),
              ),
              title: Text(
                l10n.translate('settings.title'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
            body: const SettingsScreen(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(user, l10n),
                Expanded(
                  child: IndexedStack(
                    index: _currentTab,
                    children: [
                      _WeighingFormTab(
                        defaultLocation: widget.defaultLocation,
                        onPendingSaved: () =>
                            setState(() => _currentTab = 1),
                        pendingToResume: _pendingRecordToResume,
                        onResumeConsumed: () =>
                            setState(() => _pendingRecordToResume = null),
                      ),
                      _PendingWeighingsTab(
                        userId: user.id,
                        onResume: (record) {
                          setState(() {
                            _pendingRecordToResume = record;
                            _currentTab = 0;
                          });
                        },
                      ),
                      const _StorageTab(),
                      _HistoryTab(userId: user.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            backgroundColor: AppColors.backgroundSecondary,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Iconsax.weight),
                label: l10n.translate('weighing.newWeighing'),
              ),
              BottomNavigationBarItem(
                icon: Consumer(
                  builder: (context, ref, _) {
                    final pending = ref
                        .watch(pendingWeighingsByUserProvider(user.id))
                        .valueOrNull;
                    final count = pending?.length ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Iconsax.clock),
                        if (count > 0)
                          Positioned(
                            top: -4,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.warning,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 14, minHeight: 14),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                label: l10n.translate('weighing.pendingTab'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Iconsax.box),
                label: l10n.translate('weighing.storageTab'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Iconsax.document_text),
                label: l10n.translate('weighing.history'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Erreur: $error',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child:
                const Icon(Iconsax.weight, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('weighing.title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.fullName.isEmpty ? user.email : user.fullName,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSettings = true),
            icon: const Icon(Iconsax.setting_2,
                color: AppColors.textSecondary),
            tooltip: l10n.translate('settings.title'),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) {
                await Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Iconsax.logout, color: AppColors.error),
            tooltip: l10n.authLogout,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET FORMULAIRE
// ─────────────────────────────────────────────────────────────────────────────

class _WeighingFormTab extends ConsumerStatefulWidget {
  const _WeighingFormTab({
    required this.defaultLocation,
    required this.onPendingSaved,
    this.pendingToResume,
    this.onResumeConsumed,
  });

  final WeighingLocation defaultLocation;
  final VoidCallback onPendingSaved;
  final WeighingRecordModel? pendingToResume;
  final VoidCallback? onResumeConsumed;

  @override
  ConsumerState<_WeighingFormTab> createState() => _WeighingFormTabState();
}

class _WeighingFormTabState extends ConsumerState<_WeighingFormTab> {
  late WeighingLocation _location;
  int _currentStep = 0;
  TruckModel? _selectedTruck;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _firstWeightController = TextEditingController();
  final _secondWeightController = TextEditingController();
  final _ticketController = TextEditingController();
  final _notesController = TextEditingController();
  final List<XFile> _photos = [];
  final _imageService = ImageService();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Mode reprise d'une pesée en attente
  WeighingRecordModel? _resumeRecord;

  @override
  void initState() {
    super.initState();
    _location = widget.defaultLocation;
  }

  @override
  void didUpdateWidget(_WeighingFormTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final record = widget.pendingToResume;
    if (record != null && record != oldWidget.pendingToResume) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resumePending(record);
        widget.onResumeConsumed?.call();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _firstWeightController.dispose();
    _secondWeightController.dispose();
    _ticketController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _currentStep = 0;
      _selectedTruck = null;
      _searchQuery = '';
      _searchController.clear();
      _firstWeightController.clear();
      _secondWeightController.clear();
      _ticketController.clear();
      _notesController.clear();
      _photos.clear();
      _errorMessage = null;
      _resumeRecord = null;
    });
  }

  /// Démarrer la reprise d'une pesée en attente
  void resumePending(WeighingRecordModel record) {
    setState(() {
      _resumeRecord = record;
      _currentStep = 1; // Aller directement au second poids
      _location = record.location;
      _errorMessage = null;
      _secondWeightController.clear();
      _ticketController.text = record.ticketNumber ?? '';
      _notesController.clear();
      _photos.clear();
    });
  }

  double? _parseWeight(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.'));
  }

  // Premier poids selon location (mine=vide, port=chargé)
  String get _firstWeightLabel {
    final l10n = AppLocalizations.of(context);
    return _location == WeighingLocation.mine
        ? l10n.translate('weighing.emptyWeight')
        : l10n.translate('weighing.loadedWeight');
  }

  String get _firstWeightHint {
    final l10n = AppLocalizations.of(context);
    return _location == WeighingLocation.mine
        ? l10n.translate('weighing.emptyWeightHint')
        : l10n.translate('weighing.loadedWeightHint');
  }

  // Second poids (inverse du premier)
  String get _secondWeightLabel {
    final l10n = AppLocalizations.of(context);
    return _location == WeighingLocation.mine
        ? l10n.translate('weighing.loadedWeight')
        : l10n.translate('weighing.emptyWeight');
  }

  String get _secondWeightHint {
    final l10n = AppLocalizations.of(context);
    return _location == WeighingLocation.mine
        ? l10n.translate('weighing.loadedWeightHint')
        : l10n.translate('weighing.emptyWeightHint');
  }

  double get _netWeight {
    double empty, loaded;
    if (_resumeRecord != null) {
      final isMine = _location == WeighingLocation.mine;
      final second = _parseWeight(_secondWeightController.text) ?? 0;
      empty = isMine ? (_resumeRecord!.emptyWeight ?? 0) : second;
      loaded = isMine ? second : (_resumeRecord!.loadedWeight ?? 0);
    } else {
      empty = _location == WeighingLocation.mine
          ? (_parseWeight(_firstWeightController.text) ?? 0)
          : (_parseWeight(_secondWeightController.text) ?? 0);
      loaded = _location == WeighingLocation.mine
          ? (_parseWeight(_secondWeightController.text) ?? 0)
          : (_parseWeight(_firstWeightController.text) ?? 0);
    }
    return loaded - empty;
  }

  bool _validateStep() {
    final l10n = AppLocalizations.of(context);
    if (_resumeRecord != null) {
      // Mode reprise: step 1 = second poids + ticket, step 2 = confirmation
      if (_currentStep == 1) {
        final w = _parseWeight(_secondWeightController.text);
        if (_secondWeightController.text.trim().isEmpty) {
          setState(() => _errorMessage =
              l10n.translate('weighing.secondWeightRequired'));
          return false;
        }
        if (w == null || w <= 0) {
          setState(
              () => _errorMessage = l10n.translate('weighing.weightInvalid'));
          return false;
        }
        final storedTicket = _resumeRecord!.ticketNumber ?? '';
        final enteredTicket = _ticketController.text.trim();
        if (enteredTicket.isEmpty) {
          setState(() => _errorMessage =
              l10n.translate('weighing.ticketRequired'));
          return false;
        }
        if (storedTicket.isNotEmpty && enteredTicket != storedTicket) {
          setState(() => _errorMessage =
              l10n.translate('weighing.ticketMismatch'));
          return false;
        }
      }
    } else {
      switch (_currentStep) {
        case 0:
          if (_selectedTruck == null) {
            setState(() => _errorMessage =
                l10n.translate('weighing.truckRequired'));
            return false;
          }
          break;
        case 1:
          final w = _parseWeight(_firstWeightController.text);
          if (_firstWeightController.text.trim().isEmpty) {
            setState(() => _errorMessage =
                l10n.translate('weighing.firstWeightRequired'));
            return false;
          }
          if (w == null || w <= 0) {
            setState(() =>
                _errorMessage = l10n.translate('weighing.weightInvalid'));
            return false;
          }
          if (_ticketController.text.trim().isEmpty) {
            setState(() => _errorMessage =
                l10n.translate('weighing.ticketRequired'));
            return false;
          }
          break;
        case 2:
          final w = _parseWeight(_secondWeightController.text);
          if (_secondWeightController.text.trim().isEmpty) {
            setState(() => _errorMessage =
                l10n.translate('weighing.secondWeightRequired'));
            return false;
          }
          if (w == null || w <= 0) {
            setState(() =>
                _errorMessage = l10n.translate('weighing.weightInvalid'));
            return false;
          }
          break;
      }
    }
    setState(() => _errorMessage = null);
    return true;
  }

  void _nextStep() {
    if (!_validateStep()) return;
    final maxStep = _resumeRecord != null ? 2 : 3;
    if (_currentStep < maxStep) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > (_resumeRecord != null ? 1 : 0)) {
      setState(() {
        _currentStep--;
        _errorMessage = null;
      });
    }
  }

  // Sauvegarder en attente et réinitialiser
  Future<void> _saveAsPending() async {
    final l10n = AppLocalizations.of(context);
    final weight = _parseWeight(_firstWeightController.text);
    if (weight == null || weight <= 0) {
      setState(
          () => _errorMessage = l10n.translate('weighing.firstWeightRequired'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null || _selectedTruck == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // Lecture fraîche (pas via le provider mis en cache) pour éviter
      // d'attacher la pesée à une vacation déjà terminée entre-temps.
      final activeShift = await ref
          .read(shiftRepositoryProvider)
          .getActiveShiftForTruck(_selectedTruck!.id);
      final repository = ref.read(weighingRepositoryProvider);
      await repository.createPartialRecord(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        truckFleetNumber: _selectedTruck!.numeroInterneFlotte,
        location: _location,
        firstWeight: weight,
        ticketNumber: _ticketController.text.trim(),
        weighedBy: user.id,
        weighedByName:
            user.fullName.isEmpty ? user.email : user.fullName,
        weighedByMatricule: user.matricule,
        shiftId: activeShift?.id,
        driverId: activeShift?.driverId,
        driverName: activeShift?.driverName,
      );

      ref.invalidate(pendingWeighingsByUserProvider(user.id));

      if (mounted) {
        _resetForm();
        widget.onPendingSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            content: Text(
              l10n.translate('weighing.pendingSaved'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            '${l10n.translate('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitWeighing() async {
    if (!_validateStep()) return;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      List<String>? photoUrls;
      if (_photos.isNotEmpty) {
        final truckId =
            _resumeRecord?.truckId ?? _selectedTruck!.id;
        photoUrls = await _imageService.uploadXFiles(
          _photos,
          'weighings/$truckId',
        );
      }

      final repository = ref.read(weighingRepositoryProvider);

      WeighingRecordModel? savedRecord;

      if (_resumeRecord != null) {
        // Mode reprise (T.27.1 — ticket exit validé en amont dans _validateStep)
        final second = _parseWeight(_secondWeightController.text)!;
        await repository.completeRecord(
          recordId: _resumeRecord!.id,
          location: _location,
          secondWeight: second,
          exitTicketNumber: _ticketController.text.trim(),
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          photoUrls: photoUrls,
        );
        savedRecord = _resumeRecord;
        ref.invalidate(pendingWeighingsByUserProvider(user.id));
      } else {
        // Nouveau complet
        final first = _parseWeight(_firstWeightController.text)!;
        final second = _parseWeight(_secondWeightController.text)!;
        final isMine = _location == WeighingLocation.mine;
        // Lecture fraîche (pas via le provider mis en cache) pour éviter
        // d'attacher la pesée à une vacation déjà terminée entre-temps.
        final activeShift = await ref
            .read(shiftRepositoryProvider)
            .getActiveShiftForTruck(_selectedTruck!.id);
        savedRecord = await repository.createRecord(
          truckId: _selectedTruck!.id,
          truckImmatriculation: _selectedTruck!.immatriculation,
          truckFleetNumber: _selectedTruck!.numeroInterneFlotte,
          location: _location,
          emptyWeight: isMine ? first : second,
          loadedWeight: isMine ? second : first,
          weighedBy: user.id,
          weighedByName:
              user.fullName.isEmpty ? user.email : user.fullName,
          weighedByMatricule: user.matricule,
          shiftId: activeShift?.id,
          driverId: activeShift?.driverId,
          driverName: activeShift?.driverName,
          ticketNumber: _ticketController.text.trim().isNotEmpty
              ? _ticketController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          photoUrls: photoUrls,
        );
      }

      if (_location == WeighingLocation.storage && savedRecord != null) {
        final fleetId = _selectedTruck?.fleetId ??
            (_resumeRecord != null
                ? ref
                    .read(activeTrucksProvider)
                    .valueOrNull
                    ?.where((t) => t.id == _resumeRecord!.truckId)
                    .firstOrNull
                    ?.fleetId
                : null);
        await repository.createStorageEvent(
          truckId: savedRecord.truckId,
          truckImmatriculation: savedRecord.truckImmatriculation,
          fleetId: fleetId,
          weighingId: savedRecord.id,
          recordedBy: user.id,
          recordedByName: user.fullName.isEmpty ? user.email : user.fullName,
          ticketNumber: savedRecord.ticketNumber,
        );
      }

      if (_location == WeighingLocation.mine) {
        ref.invalidate(mineWeighingsStreamProvider);
      } else if (_location == WeighingLocation.port) {
        ref.invalidate(portWeighingsStreamProvider);
      }

      if (mounted) _showSuccessDialog(l10n);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            '${l10n.translate('common.error')}: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(AppLocalizations l10n) {
    final netWeight = _netWeight;
    final immat = _resumeRecord?.truckImmatriculation ??
        _selectedTruck!.immatriculation;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.tick_circle,
                  color: AppColors.success, size: 48),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('weighing.success'),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.translate('weighing.netWeight')}: ${netWeight.toStringAsFixed(2)} T',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(immat,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 16),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(l10n),
          const SizedBox(height: AppSpacing.xl),
          if (_resumeRecord != null) _buildResumeHeader(l10n),
          if (_resumeRecord == null && _currentStep == 0)
            _buildStep0VehicleLocation(l10n),
          if (_currentStep == 1 && _resumeRecord == null)
            _buildWeightStep(
              l10n,
              controller: _firstWeightController,
              label: _firstWeightLabel,
              hint: _firstWeightHint,
            ),
          if (_currentStep == 1 && _resumeRecord != null)
            _buildWeightStep(
              l10n,
              controller: _secondWeightController,
              label: _secondWeightLabel,
              hint: _secondWeightHint,
              showFirstWeightReminder: true,
            ),
          if (_currentStep == 2 && _resumeRecord == null)
            _buildWeightStep(
              l10n,
              controller: _secondWeightController,
              label: _secondWeightLabel,
              hint: _secondWeightHint,
              showFirstWeightReminder: true,
            ),
          if ((_currentStep == 3 && _resumeRecord == null) ||
              (_currentStep == 2 && _resumeRecord != null))
            _buildConfirmationStep(l10n),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildErrorBanner(),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildNavigationButtons(l10n),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(AppLocalizations l10n) {
    final List<String> steps;
    final int totalSteps;
    if (_resumeRecord != null) {
      // Mine : second poids = chargé ; Port : second poids = vide
      final isMineResume = _resumeRecord!.location == WeighingLocation.mine;
      steps = [
        if (isMineResume) l10n.translate('weighing.step3')  // Poids chargé
        else l10n.translate('weighing.step2'),               // Poids vide
        l10n.translate('weighing.step4'),
      ];
      totalSteps = 2;
    } else {
      final isMine = _location == WeighingLocation.mine;
      steps = [
        l10n.translate('weighing.step1'),
        if (isMine) l10n.translate('weighing.step2')   // Poids vide
        else l10n.translate('weighing.step3'),          // Poids chargé
        if (isMine) l10n.translate('weighing.step3')   // Poids chargé
        else l10n.translate('weighing.step2'),          // Poids vide
        l10n.translate('weighing.step4'),
      ];
      totalSteps = 4;
    }

    final adjustedStep =
        _resumeRecord != null ? _currentStep - 1 : _currentStep;

    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index == adjustedStep;
        final isDone = index < adjustedStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.success
                      : isActive
                          ? AppColors.primary
                          : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? AppColors.primary
                            : AppColors.surfaceBorder,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check,
                          color: Colors.white, size: 14)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  steps[index],
                  style: TextStyle(
                    color: isActive
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: isActive
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (index < totalSteps - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 12,
                    height: 2,
                    color: isDone
                        ? AppColors.success
                        : AppColors.surfaceBorder,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildResumeHeader(AppLocalizations l10n) {
    final rec = _resumeRecord!;
    final isMine = rec.location == WeighingLocation.mine;
    final firstWeight =
        isMine ? rec.emptyWeight : rec.loadedWeight;
    final firstLabel = isMine
        ? l10n.translate('weighing.emptyWeight')
        : l10n.translate('weighing.loadedWeight');

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.clock, color: AppColors.warning, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.translate('weighing.resumeWeighing'),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Bouton pour abandonner la reprise et démarrer une nouvelle pesée
              TextButton.icon(
                onPressed: () => setState(() {
                  _resumeRecord = null;
                  _currentStep = 0;
                  _secondWeightController.clear();
                  _ticketController.clear();
                  _notesController.clear();
                  _photos.clear();
                  _errorMessage = null;
                }),
                icon: const Icon(Iconsax.add_circle,
                    color: AppColors.primary, size: 16),
                label: Text(
                  l10n.translate('weighing.newWeighing'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(Iconsax.truck, 'Immatriculation',
              rec.truckImmatriculation),
          _buildInfoRow(
            Iconsax.location,
            l10n.translate('weighing.location'),
            switch (rec.location) {
              WeighingLocation.mine => l10n.translate('weighing.mine'),
              WeighingLocation.port => l10n.translate('weighing.port'),
              WeighingLocation.storage =>
                l10n.translate('weighing.storage'),
            },
          ),
          _buildInfoRow(
            Iconsax.weight,
            firstLabel,
            '${firstWeight?.toStringAsFixed(2)} T',
          ),
        ],
      ),
    );
  }

  Widget _buildStep0VehicleLocation(AppLocalizations l10n) {
    final trucksAsync = ref.watch(trucksInActiveShiftProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de lieu
        Text(
          l10n.translate('weighing.selectLocation'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildLocationButton(
                label: l10n.translate('weighing.mine'),
                icon: Iconsax.map,
                isSelected: _location == WeighingLocation.mine,
                onTap: () =>
                    setState(() => _location = WeighingLocation.mine),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildLocationButton(
                label: l10n.translate('weighing.port'),
                icon: Iconsax.ship,
                isSelected: _location == WeighingLocation.port,
                onTap: () =>
                    setState(() => _location = WeighingLocation.port),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        // Recherche véhicule
        Text(
          l10n.translate('weighing.selectTruck'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (v) =>
                setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.search_normal,
                  color: AppColors.primary, size: 22),
              hintText: l10n.translate('weighing.searchTruck'),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _selectedTruck = null;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        trucksAsync.when(
          data: (trucks) {
            final filtered = _searchQuery.isEmpty
                ? trucks
                : trucks
                    .where((t) =>
                        t.immatriculation
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        t.numeroInterneFlotte
                            .toLowerCase()
                            .contains(_searchQuery))
                    .toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md),
                child: Text(
                  _searchQuery.isEmpty
                      ? l10n.translate('weighing.noActiveShiftTrucks')
                      : l10n.translate('weighing.noTruckFound'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final truck = filtered[i];
                  final isSelected =
                      _selectedTruck?.id == truck.id;
                  return InkWell(
                    onTap: () => setState(() {
                      _selectedTruck = truck;
                      _errorMessage = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.transparent,
                        border: i < filtered.length - 1
                            ? const Border(
                                bottom: BorderSide(
                                    color: AppColors.surfaceBorder,
                                    width: 0.5))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.truck,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  truck.immatriculation,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (truck.numeroInterneFlotte
                                    .isNotEmpty)
                                  Text(
                                    '${truck.marque} ${truck.modele} · N° ${truck.numeroInterneFlotte}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(
                  color: AppColors.primary),
            ),
          ),
          error: (error, _) => Text(
            '${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        if (_selectedTruck != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildTruckInfoCard(),
        ],
      ],
    );
  }

  Widget _buildLocationButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color:
                isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildInfoRow(Iconsax.truck, 'Immatriculation',
              _selectedTruck!.immatriculation),
          if (_selectedTruck!.numeroInterneFlotte.isNotEmpty)
            _buildInfoRow(Iconsax.hashtag, 'N\u00b0 Flotte',
                _selectedTruck!.numeroInterneFlotte),
          _buildInfoRow(Iconsax.tag, 'Type',
              '${_selectedTruck!.marque} ${_selectedTruck!.modele}'),
          _buildShiftInfoBanner(AppLocalizations.of(context)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftInfoBanner(AppLocalizations l10n) {
    final truckId =
        _resumeRecord?.truckId ?? _selectedTruck?.id;
    if (truckId == null) return const SizedBox.shrink();

    final shiftAsync = ref.watch(activeShiftForTruckProvider(truckId));
    return shiftAsync.when(
      data: (shift) {
        if (shift == null) return const SizedBox.shrink();
        var fleetName = '';
        final truck = _selectedTruck;
        if (truck?.fleetId != null) {
          final fleets =
              ref.watch(allFleetsProvider).valueOrNull ?? [];
          fleetName = fleets
                  .where((f) => f.id == truck!.fleetId)
                  .firstOrNull
                  ?.name ??
              '';
        }
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Iconsax.timer_start,
                  color: AppColors.success, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  fleetName.isNotEmpty
                      ? l10n
                          .translate('weighing.vehicleInShift')
                          .replaceAll('{fleetName}', fleetName)
                      : l10n
                          .translate('weighing.vehicleInShift')
                          .replaceAll('{fleetName}', '-'),
                  style: const TextStyle(
                      color: AppColors.success, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: InlineErrorRetry(
          onRetry: () => ref.invalidate(activeShiftForTruckProvider(truckId)),
        ),
      ),
    );
  }

  Widget _buildWeightStep(
    AppLocalizations l10n, {
    required TextEditingController controller,
    required String label,
    required String hint,
    bool showFirstWeightReminder = false,
  }) {
    final first = _parseWeight(_firstWeightController.text);
    final second = _parseWeight(controller.text);

    // Rappel du premier poids
    double? reminderWeight;
    String? reminderLabel;
    if (showFirstWeightReminder) {
      if (_resumeRecord != null) {
        final isMine = _location == WeighingLocation.mine;
        reminderWeight =
            isMine ? _resumeRecord!.emptyWeight : _resumeRecord!.loadedWeight;
        reminderLabel = isMine
            ? l10n.translate('weighing.emptyWeight')
            : l10n.translate('weighing.loadedWeight');
      } else if (first != null) {
        reminderWeight = first;
        reminderLabel = _firstWeightLabel;
      }
    }

    // Net weight dynamique (mine: second-first, port: first-second)
    double? dynamicNet;
    if (second != null) {
      if (_resumeRecord != null) {
        final isMine = _location == WeighingLocation.mine;
        final firstW = isMine
            ? _resumeRecord!.emptyWeight!
            : _resumeRecord!.loadedWeight!;
        dynamicNet = isMine ? second - firstW : firstW - second;
      } else if (first != null) {
        dynamicNet = _location == WeighingLocation.mine
            ? second - first
            : first - second;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reminderWeight != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.weight,
                    color: AppColors.info, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$reminderLabel: ${reminderWeight.toStringAsFixed(2)} T',
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildWeightField(
            controller: controller, label: label, hint: hint),
        if (dynamicNet != null && dynamicNet > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.chart_2,
                    color: AppColors.success, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.translate('weighing.netWeight'),
                          style: const TextStyle(
                              color: AppColors.success, fontSize: 12)),
                      Text(
                        '${dynamicNet.toStringAsFixed(2)} T',
                        style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        // Ticket + Notes
        Row(
          children: [
            Text('${l10n.translate('weighing.ticketNumber')} *',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            if (_resumeRecord?.ticketNumber != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.4)),
                ),
                child: Text(
                  l10n.translate('weighing.ticketAutoFilled'),
                  style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _ticketController,
          icon: Iconsax.receipt,
          hint: l10n.translate('weighing.ticketHint'),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.translate('weighing.notes'),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        _buildTextField(
          controller: _notesController,
          icon: Iconsax.document_text,
          hint: l10n.translate('weighing.notesHint'),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildWeightField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.weight,
                  color: AppColors.primary, size: 28),
              hintText: hint,
              hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 24,
                  fontWeight: FontWeight.w400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.lg),
              suffixText: 'T',
              suffixStyle: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: maxLines > 1
              ? Padding(
                  padding: EdgeInsets.only(bottom: (maxLines - 1) * 24.0),
                  child:
                      Icon(icon, color: AppColors.primary, size: 24),
                )
              : Icon(icon, color: AppColors.primary, size: 24),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
        ),
      ),
    );
  }

  Widget _buildConfirmationStep(AppLocalizations l10n) {
    final immat = _resumeRecord?.truckImmatriculation ??
        _selectedTruck!.immatriculation;
    final isMine = _location == WeighingLocation.mine;

    double emptyW, loadedW;
    if (_resumeRecord != null) {
      final second = _parseWeight(_secondWeightController.text) ?? 0;
      emptyW = isMine ? (_resumeRecord!.emptyWeight ?? 0) : second;
      loadedW = isMine ? second : (_resumeRecord!.loadedWeight ?? 0);
    } else {
      final first = _parseWeight(_firstWeightController.text) ?? 0;
      final second = _parseWeight(_secondWeightController.text) ?? 0;
      emptyW = isMine ? first : second;
      loadedW = isMine ? second : first;
    }
    final net = loadedW - emptyW;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.translate('weighing.confirmTitle'),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: [
              _buildConfirmRow(Iconsax.truck,
                  l10n.translate('weighing.vehicle'), immat),
              const Divider(color: AppColors.surfaceBorder, height: 24),
              _buildConfirmRow(
                Iconsax.location,
                l10n.translate('weighing.location'),
                switch (_location) {
                  WeighingLocation.mine => l10n.translate('weighing.mine'),
                  WeighingLocation.port => l10n.translate('weighing.port'),
                  WeighingLocation.storage =>
                    l10n.translate('weighing.storage'),
                },
              ),
              const Divider(color: AppColors.surfaceBorder, height: 24),
              _buildConfirmRow(
                Iconsax.weight,
                l10n.translate('weighing.emptyWeight'),
                '${emptyW.toStringAsFixed(2)} T',
              ),
              const Divider(color: AppColors.surfaceBorder, height: 24),
              _buildConfirmRow(
                Iconsax.weight,
                l10n.translate('weighing.loadedWeight'),
                '${loadedW.toStringAsFixed(2)} T',
              ),
              const Divider(color: AppColors.surfaceBorder, height: 24),
              _buildConfirmRow(
                Iconsax.chart_2,
                l10n.translate('weighing.netWeight'),
                '${net.toStringAsFixed(2)} T',
                valueColor: AppColors.success,
              ),
              if (_ticketController.text.trim().isNotEmpty) ...[
                const Divider(color: AppColors.surfaceBorder, height: 24),
                _buildConfirmRow(
                  Iconsax.receipt,
                  l10n.translate('weighing.ticketNumber'),
                  _ticketController.text.trim(),
                ),
              ],
              if (_notesController.text.trim().isNotEmpty) ...[
                const Divider(color: AppColors.surfaceBorder, height: 24),
                _buildConfirmRow(
                  Iconsax.document_text,
                  l10n.translate('weighing.notes'),
                  _notesController.text.trim(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Photos à la confirmation
        Text(l10n.translate('photos.title'),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        PhotoPickerWidget(
          photos: _photos,
          onPickCamera: () async {
            final file = await _imageService.pickFromCamera();
            if (file != null && mounted) {
              setState(() => _photos.add(file));
            }
          },
          onPickGallery: () async {
            final file = await _imageService.pickFromGallery();
            if (file != null && mounted) {
              setState(() => _photos.add(file));
            }
          },
          onRemove: (index) => setState(() => _photos.removeAt(index)),
        ),
      ],
    );
  }

  Widget _buildConfirmRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      color: valueColor ?? AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(_errorMessage!,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(AppLocalizations l10n) {
    final isResume = _resumeRecord != null;
    final lastStep = isResume ? 2 : 3;
    final isLastStep = _currentStep == lastStep;
    final isFirstStep =
        _currentStep == (isResume ? 1 : 0);
    // "Mettre en attente" visible au step 1 (nouveau mode seulement)
    final showSaveAsPending =
        !isResume && _currentStep == 1 && _selectedTruck != null;

    return Column(
      children: [
        if (showSaveAsPending) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _saveAsPending,
              icon: const Icon(Iconsax.clock,
                  color: AppColors.warning, size: 20),
              label: Text(
                l10n.translate('weighing.saveAsPending'),
                style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 15,
                    fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            if (!isFirstStep)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    side: const BorderSide(
                        color: AppColors.surfaceBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text(l10n.translate('weighing.previous'),
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            if (!isFirstStep) const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : isLastStep
                          ? _submitWeighing
                          : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLastStep
                        ? AppColors.success
                        : AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              isLastStep
                                  ? Iconsax.tick_circle
                                  : Iconsax.arrow_right_1,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              isLastStep
                                  ? l10n.translate('weighing.confirm')
                                  : l10n.translate('weighing.next'),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET EN ATTENTE
// ─────────────────────────────────────────────────────────────────────────────

class _PendingWeighingsTab extends ConsumerWidget {
  const _PendingWeighingsTab({
    required this.userId,
    required this.onResume,
  });

  final String userId;
  final void Function(WeighingRecordModel record) onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync =
        ref.watch(pendingWeighingsByUserProvider(userId));

    return pendingAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Iconsax.clock,
                    size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.translate('weighing.noPendingRecords'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final isMine =
                record.location == WeighingLocation.mine;
            final firstWeight =
                isMine ? record.emptyWeight : record.loadedWeight;
            final firstLabel = isMine
                ? l10n.translate('weighing.emptyWeight')
                : l10n.translate('weighing.loadedWeight');

            return Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: const BorderSide(color: AppColors.warning),
              ),
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Iconsax.truck,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            record.truckImmatriculation,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border:
                                Border.all(color: AppColors.warning),
                          ),
                          child: Row(
                            children: [
                              const Icon(Iconsax.clock,
                                  color: AppColors.warning, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                l10n.translate('weighing.pending'),
                                style: const TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Iconsax.location,
                            color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          isMine
                              ? l10n.translate('weighing.mine')
                              : l10n.translate('weighing.port'),
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(Iconsax.weight,
                            color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$firstLabel: ${firstWeight?.toStringAsFixed(2) ?? '-'} T',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Iconsax.clock,
                            color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${record.formattedDate} ${record.formattedTime}',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => onResume(record),
                          icon: const Icon(Iconsax.play,
                              color: AppColors.primary, size: 16),
                          label: Text(
                            l10n.translate('weighing.resumeWeighing'),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET HISTORIQUE
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends ConsumerStatefulWidget {
  const _HistoryTab({required this.userId});

  final String userId;

  @override
  ConsumerState<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<_HistoryTab> {
  String _vehicleFilter = '';
  String _agentFilter = '';
  WeighingLocation? _locationFilter;
  WeighingStatus? _statusFilter;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _filtersVisible = false;

  final _vehicleCtrl = TextEditingController();
  final _agentCtrl = TextEditingController();

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _agentCtrl.dispose();
    super.dispose();
  }

  bool _hasActiveFilters() =>
      _vehicleFilter.isNotEmpty ||
      _agentFilter.isNotEmpty ||
      _locationFilter != null ||
      _statusFilter != null ||
      _dateFrom != null ||
      _dateTo != null;

  void _clearFilters() {
    setState(() {
      _vehicleFilter = '';
      _agentFilter = '';
      _locationFilter = null;
      _statusFilter = null;
      _dateFrom = null;
      _dateTo = null;
      _vehicleCtrl.clear();
      _agentCtrl.clear();
    });
  }

  List<WeighingRecordModel> _applyFilters(List<WeighingRecordModel> records) {
    return records.where((r) {
      if (_vehicleFilter.isNotEmpty &&
          !r.truckImmatriculation
              .toLowerCase()
              .contains(_vehicleFilter.toLowerCase())) {
        return false;
      }
      if (_agentFilter.isNotEmpty) {
        final name = r.weighedBy.toLowerCase();
        if (!name.contains(_agentFilter.toLowerCase())) return false;
      }
      if (_locationFilter != null && r.location != _locationFilter) {
        return false;
      }
      if (_statusFilter != null && r.status != _statusFilter) {
        return false;
      }
      if (_dateFrom != null) {
        final day =
            DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
        if (day.isBefore(_dateFrom!)) return false;
      }
      if (_dateTo != null) {
        final day =
            DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day);
        if (day.isAfter(_dateTo!)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recordsAsync = ref.watch(userWeighingsStreamProvider(widget.userId));

    return recordsAsync.when(
      data: (records) {
        final completed =
            records.where((r) => r.status != WeighingStatus.pending).toList();
        final filtered = _applyFilters(completed);

        return Column(
          children: [
            _buildFilterBar(context, l10n, completed.length, filtered.length),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.weight,
                              size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _hasActiveFilters()
                                ? l10n.translate('common.noResults')
                                : l10n.translate('weighing.noRecords'),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildRecordCard(context, filtered[index], l10n),
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AppLocalizations l10n,
      int total, int filtered) {
    final hasFilters = _hasActiveFilters();
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle row
          InkWell(
            onTap: () => setState(() => _filtersVisible = !_filtersVisible),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Iconsax.filter,
                    size: 16,
                    color: hasFilters ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    hasFilters
                        ? '$filtered ${l10n.translate('weighing.allResults')}'
                        : l10n.translate('weighing.filterDate').split(' ').first,
                    style: TextStyle(
                      color: hasFilters
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight:
                          hasFilters ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (hasFilters)
                    GestureDetector(
                      onTap: _clearFilters,
                      child: Text(
                        l10n.translate('weighing.clearFilters'),
                        style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    _filtersVisible
                        ? Iconsax.arrow_up_2
                        : Iconsax.arrow_down_1,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersVisible) ...[
            const Divider(height: 1, color: AppColors.surfaceBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Vehicle + Agent row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _vehicleCtrl,
                          onChanged: (v) =>
                              setState(() => _vehicleFilter = v),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText:
                                l10n.translate('weighing.filterVehicle'),
                            labelStyle: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            prefixIcon: const Icon(Iconsax.truck,
                                size: 16, color: AppColors.textSecondary),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                  color: AppColors.surfaceBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                  color: AppColors.surfaceBorder),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _agentCtrl,
                          onChanged: (v) =>
                              setState(() => _agentFilter = v),
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText:
                                l10n.translate('weighing.filterAgent'),
                            labelStyle: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                            prefixIcon: const Icon(Iconsax.user,
                                size: 16, color: AppColors.textSecondary),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                  color: AppColors.surfaceBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              borderSide: const BorderSide(
                                  color: AppColors.surfaceBorder),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Site + Date row
                  Row(
                    children: [
                      _buildSiteToggle(l10n),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildDateButton(
                          context,
                          l10n,
                          isFrom: true,
                          date: _dateFrom,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text('→',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _buildDateButton(
                          context,
                          l10n,
                          isFrom: false,
                          date: _dateTo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Statut : Chargé / Déchargé
                  Row(
                    children: [
                      _buildStatusToggle(l10n),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, color: AppColors.surfaceBorder),
        ],
      ),
    );
  }

  Widget _buildSiteToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _siteChip(l10n.translate('weighing.filterAll'), null, l10n),
          _siteChip(l10n.translate('weighing.mine'), WeighingLocation.mine, l10n),
          _siteChip(l10n.translate('weighing.port'), WeighingLocation.port, l10n),
        ],
      ),
    );
  }

  Widget _buildStatusToggle(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceBorder),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statusChip(
              l10n.translate('weighing.statusLoaded'), WeighingStatus.loaded),
          _statusChip(
              l10n.translate('weighing.statusUnloaded'), WeighingStatus.unloaded),
        ],
      ),
    );
  }

  Widget _siteChip(
      String label, WeighingLocation? value, AppLocalizations l10n) {
    final selected = _locationFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _locationFilter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, WeighingStatus value) {
    final selected = _statusFilter == value;
    final color = value == WeighingStatus.loaded
        ? AppColors.primary
        : const Color(0xFF26A69A);
    return GestureDetector(
      onTap: () => setState(
          () => _statusFilter = selected ? null : value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(BuildContext context, AppLocalizations l10n,
      {required bool isFrom, required DateTime? date}) {
    final label = isFrom
        ? l10n.translate('weighing.filterFrom')
        : l10n.translate('weighing.filterTo');
    final display = date != null
        ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
        : label;
    return GestureDetector(
      onTap: () => _pickDate(context, isFrom),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceBorder),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.calendar, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(display,
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(
      BuildContext context, WeighingRecordModel record, AppLocalizations l10n) {
    final statusColor = switch (record.status) {
      WeighingStatus.pending => AppColors.warning,
      WeighingStatus.recorded => AppColors.info,
      WeighingStatus.validated => AppColors.success,
      WeighingStatus.rejected => AppColors.error,
      WeighingStatus.loaded => AppColors.primary,
      WeighingStatus.unloaded => const Color(0xFF26A69A),
    };
    final statusLabel = switch (record.status) {
      WeighingStatus.pending => l10n.translate('weighing.pending'),
      WeighingStatus.recorded => l10n.translate('weighing.recorded'),
      WeighingStatus.validated => l10n.translate('weighing.validated'),
      WeighingStatus.rejected => l10n.translate('weighing.rejected'),
      WeighingStatus.loaded => l10n.translate('weighing.statusLoaded'),
      WeighingStatus.unloaded => l10n.translate('weighing.statusUnloaded'),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => WeighingDetailDialog(record: record),
      ),
      child: Card(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.truck, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      record.truckImmatriculation,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Iconsax.location,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    switch (record.location) {
                      WeighingLocation.mine =>
                        l10n.translate('weighing.mine'),
                      WeighingLocation.port =>
                        l10n.translate('weighing.port'),
                      WeighingLocation.storage =>
                        l10n.translate('weighing.storage'),
                    },
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (record.emptyWeight != null && record.loadedWeight != null) ...[
                Row(
                  children: [
                    Expanded(
                        child: _buildWeightInfo(
                            l10n.translate('weighing.emptyWeight'),
                            record.formattedEmptyWeight)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _buildWeightInfo(
                            l10n.translate('weighing.loadedWeight'),
                            record.formattedLoadedWeight)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: _buildWeightInfo(
                            l10n.translate('weighing.netWeight'),
                            record.formattedWeight,
                            isHighlighted: true)),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.clock,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${record.formattedDate} ${record.formattedTime}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              if (record.ticketNumber != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.receipt,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${l10n.translate('weighing.ticketNumber')}: ${record.ticketNumber}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (record.photoUrls != null && record.photoUrls!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.camera,
                        color: AppColors.textSecondary, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${record.photoUrls!.length} ${l10n.translate('photos.title').toLowerCase()}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (record.chargedByName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.box_add,
                        color: AppColors.primary, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${l10n.translate('weighing.chargedBy')}: ${record.chargedByName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (record.dischargedByName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.box_remove,
                        color: Color(0xFF26A69A), size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${l10n.translate('weighing.dischargedBy')}: ${record.dischargedByName}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInfo(String label, String value,
      {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: isHighlighted
                    ? AppColors.success
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET STOCKAGE
// ─────────────────────────────────────────────────────────────────────────────

class _StorageTab extends ConsumerWidget {
  const _StorageTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.backgroundSecondary,
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: l10n.translate('weighing.chargeSubTab')),
                Tab(text: l10n.translate('weighing.dischargeSubTab')),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _StorageSubTab(isChargeTab: true),
                _StorageSubTab(isChargeTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageSubTab extends ConsumerStatefulWidget {
  const _StorageSubTab({required this.isChargeTab});

  /// true = Chargement (pesées mine), false = Déchargement (pesées port)
  final bool isChargeTab;

  @override
  ConsumerState<_StorageSubTab> createState() => _StorageSubTabState();
}

class _StorageSubTabState extends ConsumerState<_StorageSubTab> {
  final _processingIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recordsAsync = widget.isChargeTab
        ? ref.watch(mineRecordedWeighingsStreamProvider)
        : ref.watch(portRecordedWeighingsStreamProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isChargeTab ? Iconsax.box_add : Iconsax.box_remove,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.translate(widget.isChargeTab
                      ? 'weighing.noChargeRecords'
                      : 'weighing.noDischargeRecords'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: records.length,
          itemBuilder: (context, index) =>
              _buildCard(context, records[index], l10n),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text('Erreur: $error',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }

  Widget _buildCard(BuildContext context, WeighingRecordModel record,
      AppLocalizations l10n) {
    final accentColor =
        widget.isChargeTab ? AppColors.primary : const Color(0xFF26A69A);
    final isProcessing = _processingIds.contains(record.id);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.truck, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.truckImmatriculation,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (record.truckFleetNumber?.isNotEmpty ?? false)
                        Text(
                          'N° ${record.truckFleetNumber}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Iconsax.weight,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${l10n.translate('weighing.netWeight')}: ${record.formattedWeight}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(Iconsax.clock,
                    color: AppColors.textSecondary, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${record.formattedDate} ${record.formattedTime}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            if (record.ticketNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.receipt,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${l10n.translate('weighing.ticketNumber')}: ${record.ticketNumber}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
            if (record.weighedByName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Iconsax.user,
                      color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${l10n.translate('weighing.weighedBy')}: ${record.weighedByName}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: isProcessing ? null : () => _onAction(record, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                minimumSize: const Size(double.infinity, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isChargeTab
                              ? Iconsax.box_add
                              : Iconsax.box_remove,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          l10n.translate(widget.isChargeTab
                              ? 'weighing.chargeButton'
                              : 'weighing.dischargeButton'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(WeighingRecordModel record,
      AppLocalizations l10n) async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return;
    final validatorName =
        user.fullName.isEmpty ? user.email : user.fullName;

    final accentColor =
        widget.isChargeTab ? AppColors.primary : const Color(0xFF26A69A);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          l10n.translate(widget.isChargeTab
              ? 'weighing.confirmChargeTitle'
              : 'weighing.confirmDischargeTitle'),
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Iconsax.truck,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    record.truckImmatriculation,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (record.ticketNumber != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Iconsax.receipt,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    record.ticketNumber!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border:
                    Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.user, color: accentColor, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      validatorName,
                      style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.translate('common.cancel'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            child: Text(
              l10n.translate(widget.isChargeTab
                  ? 'weighing.chargeButton'
                  : 'weighing.dischargeButton'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingIds.add(record.id));

      try {
        final repository = ref.read(weighingRepositoryProvider);
        if (widget.isChargeTab) {
          await repository.markAsLoaded(
            recordId: record.id,
            chargedBy: validatorName,
            chargedByName: validatorName,
          );
        } else {
          await repository.markAsUnloaded(
            recordId: record.id,
            dischargedBy: validatorName,
            dischargedByName: validatorName,
          );
        }

        // Notifier le superviseur flotte via storage_event
        final trucks =
            ref.read(activeTrucksProvider).valueOrNull ?? <TruckModel>[];
        final truck = trucks
            .where((TruckModel t) => t.id == record.truckId)
            .firstOrNull;
        if (truck?.fleetId != null) {
          await repository.createStorageEvent(
            truckId: record.truckId,
            truckImmatriculation: record.truckImmatriculation,
            fleetId: truck!.fleetId,
            weighingId: record.id,
            recordedBy: validatorName,
            recordedByName: validatorName,
            ticketNumber: record.ticketNumber,
            eventType: widget.isChargeTab ? 'loaded' : 'unloaded',
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: widget.isChargeTab
                  ? AppColors.primary
                  : const Color(0xFF26A69A),
              content: Text(
                l10n.translate(widget.isChargeTab
                    ? 'weighing.chargeSuccess'
                    : 'weighing.dischargeSuccess'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('${l10n.translate('common.error')}: $e',
                  style: const TextStyle(color: Colors.white)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _processingIds.remove(record.id));
      }
  }
}
