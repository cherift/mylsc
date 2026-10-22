import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/permission.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/models/truck_model.dart';
import '../providers/truck_providers.dart';

/// Droit de supprimer un véhicule (Direction / RH — T.40)
bool canDeleteTrucks(WidgetRef ref) =>
    ref
        .watch(authControllerProvider)
        .valueOrNull
        ?.hasPermission(Permission.deleteVehicles) ??
    false;

/// Suppression d'un véhicule (T.40) :
/// contrôle des dépendances → confirmation → désactivation logique.
/// Retourne true si le véhicule a été supprimé.
Future<bool> confirmAndDeleteTruck(
  BuildContext context,
  WidgetRef ref,
  TruckModel truck,
) async {
  final l10n = AppLocalizations.of(context);
  final repository = ref.read(truckRepositoryProvider);
  final label = truck.numeroInterneFlotte.isNotEmpty
      ? '${truck.immatriculation} (${truck.numeroInterneFlotte})'
      : truck.immatriculation;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.error,
      content: Text(message),
    ));
  }

  // Contrôle des dépendances actives
  try {
    final blocker = await repository.checkDeletionBlockers(truck.id);
    if (blocker != null) {
      if (context.mounted) {
        final key = blocker == 'active_shift'
            ? 'trucks.delete.blockedActiveShift'
            : 'trucks.delete.blockedPendingFuel';
        showError(l10n.translate(key).replaceAll('{truck}', label));
      }
      return false;
    }
  } catch (e) {
    if (context.mounted) showError('${l10n.translate('common.error')}: $e');
    return false;
  }

  if (!context.mounted) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        l10n.translate('trucks.delete.title'),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        '${l10n.translate('trucks.delete.confirm').replaceAll('{truck}', label)}\n\n'
        '${l10n.translate('trucks.delete.consequences')}',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            l10n.translate('common.delete'),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    ),
  );

  if (!(confirmed ?? false)) return false;

  try {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    await repository.softDeleteTruck(truck.id, deletedBy: currentUser?.id);
    ref
      ..invalidate(activeTrucksProvider)
      ..invalidate(allTrucksProvider)
      ..invalidate(truckStatsByStatusProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(l10n.translate('trucks.delete.success')),
      ));
    }
    return true;
  } catch (e) {
    if (context.mounted) showError('${l10n.translate('common.error')}: $e');
    return false;
  }
}
