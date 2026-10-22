import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../clients/domain/models/client_model.dart';
import '../../../clients/presentation/providers/client_providers.dart';
import '../../domain/models/weighing_record_model.dart';
import '../../domain/weighing_edit_policy.dart';
import '../providers/weighing_providers.dart';

/// Dialog de correction d'une pesée (T.38).
/// Retourne `true` si la pesée a été corrigée.
class WeighingEditDialog extends ConsumerStatefulWidget {
  const WeighingEditDialog({required this.record, super.key});

  final WeighingRecordModel record;

  @override
  ConsumerState<WeighingEditDialog> createState() => _WeighingEditDialogState();
}

class _WeighingEditDialogState extends ConsumerState<WeighingEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emptyController;
  late final TextEditingController _loadedController;
  late final TextEditingController _ticketController;
  late final TextEditingController _notesController;
  final _reasonController = TextEditingController();
  String? _clientId;
  String? _clientName;
  bool _isSaving = false;

  WeighingRecordModel get r => widget.record;

  @override
  void initState() {
    super.initState();
    _emptyController = TextEditingController(text: _formatWeight(r.emptyWeight));
    _loadedController =
        TextEditingController(text: _formatWeight(r.loadedWeight));
    _ticketController = TextEditingController(text: r.ticketNumber ?? '');
    _notesController = TextEditingController(text: r.notes ?? '');
    _clientId = r.clientId;
    _clientName = r.clientName;
  }

  @override
  void dispose() {
    _emptyController.dispose();
    _loadedController.dispose();
    _ticketController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  /// Poids sans zéros superflus, pour éviter des écarts d'arrondi fictifs
  String _formatWeight(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  double? get _netPreview {
    final empty = r.emptyWeight != null ? _parse(_emptyController.text) : null;
    final loaded =
        r.loadedWeight != null ? _parse(_loadedController.text) : null;
    if (empty == null || loaded == null) return null;
    return loaded - empty;
  }

  String? _validateWeight(String? value, AppLocalizations l10n) {
    final w = _parse(value ?? '');
    if (w == null || w <= 0) return l10n.translate('weighing.weightInvalid');
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final net = _netPreview;
    if (net != null && net <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.error,
        content: Text(l10n.translate('weighing.edit.netMustBePositive')),
      ));
      return;
    }

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final changed =
          await ref.read(weighingRepositoryProvider).correctRecord(
                original: r,
                editedBy: user.id,
                editedByName:
                    user.fullName.isEmpty ? user.email : user.fullName,
                reason: _reasonController.text,
                emptyWeight: r.emptyWeight != null
                    ? _parse(_emptyController.text)
                    : null,
                loadedWeight: r.loadedWeight != null
                    ? _parse(_loadedController.text)
                    : null,
                ticketNumber: WeighingEditPolicy.canEditTicket(user)
                    ? _ticketController.text
                    : null,
                clientId: _clientId,
                clientName: _clientName,
                notes: _notesController.text,
              );

      if (!mounted) return;
      if (!changed) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.translate('weighing.edit.noChanges')),
        ));
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.error,
          content: Text('${l10n.translate('common.error')}: $e'),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final canEditTicket =
        user != null && WeighingEditPolicy.canEditTicket(user);
    final net = _netPreview;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Iconsax.edit, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${l10n.translate('weighing.edit.title')} — ${r.truckImmatriculation}',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 17),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClientField(l10n),
                const SizedBox(height: AppSpacing.md),
                if (r.emptyWeight != null) ...[
                  _buildWeightField(
                    l10n,
                    controller: _emptyController,
                    label: l10n.translate('weighing.emptyWeight'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (r.loadedWeight != null) ...[
                  _buildWeightField(
                    l10n,
                    controller: _loadedController,
                    label: l10n.translate('weighing.loadedWeight'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (net != null) ...[
                  Text(
                    '${l10n.translate('weighing.netWeight')} : ${net.toStringAsFixed(2)} T',
                    style: TextStyle(
                      color: net > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  controller: _ticketController,
                  enabled: canEditTicket,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.translate('weighing.ticketNumber'),
                    helperText: canEditTicket
                        ? null
                        : l10n.translate('weighing.edit.ticketLocked'),
                    helperMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => canEditTicket && (v ?? '').trim().isEmpty
                      ? l10n.translate('weighing.ticketRequired')
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: l10n.translate('weighing.notes'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _reasonController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: '${l10n.translate('weighing.edit.reason')} *',
                    hintText: l10n.translate('weighing.edit.reasonHint'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.translate('weighing.edit.reasonRequired')
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.translate('common.save')),
        ),
      ],
    );
  }

  Widget _buildWeightField(
    AppLocalizations l10n, {
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'T',
        border: const OutlineInputBorder(),
      ),
      validator: (v) => _validateWeight(v, l10n),
    );
  }

  Widget _buildClientField(AppLocalizations l10n) {
    final clients =
        ref.watch(activeClientsProvider).valueOrNull ?? const <ClientModel>[];
    // Conserver l'affichage d'un client désactivé depuis la pesée
    final items = <ClientModel>[
      ...clients,
      if (_clientId != null && !clients.any((c) => c.id == _clientId))
        ClientModel(
          id: _clientId!,
          name: _clientName ?? _clientId!,
          createdAt: DateTime.now(),
          createdBy: '',
        ),
    ];

    return DropdownButtonFormField<String>(
      initialValue: _clientId,
      isExpanded: true,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: l10n.translate('weighing.client'),
        border: const OutlineInputBorder(),
      ),
      items: items
          .map((c) => DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.displayName, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (id) {
        final client = items.where((c) => c.id == id).firstOrNull;
        setState(() {
          _clientId = client?.id;
          _clientName = client?.name;
        });
      },
      validator: (v) =>
          v == null ? l10n.translate('weighing.clientRequired') : null,
    );
  }
}
