import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/user_management_providers.dart';

/// Suppression d'un utilisateur ou d'un chauffeur (T.39) :
/// contrôle des dépendances → confirmation → désactivation logique.
/// Retourne true si l'utilisateur a été supprimé.
Future<bool> confirmAndDeleteUser(
  BuildContext context,
  WidgetRef ref,
  UserModel user, {
  required String titleKey,
  required String confirmKey,
  required String successKey,
}) async {
  final l10n = AppLocalizations.of(context);
  final currentUser = ref.read(authControllerProvider).valueOrNull;
  final repository = ref.read(userManagementRepositoryProvider);
  final name = user.fullName.isNotEmpty ? user.fullName : user.email;

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.error,
      content: Text(message),
    ));
  }

  if (currentUser?.id == user.id) {
    showError(l10n.translate('users.delete.cannotDeleteSelf'));
    return false;
  }

  // Contrôle des dépendances actives
  try {
    final blocker = await repository.checkDeletionBlockers(user.id);
    if (blocker != null) {
      if (context.mounted) {
        showError(l10n
            .translate('users.delete.blockedActiveShift')
            .replaceAll('{name}', name));
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
        l10n.translate(titleKey),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Text(
        '${l10n.translate(confirmKey).replaceAll('{name}', name)}\n\n'
        '${l10n.translate('users.delete.consequences')}',
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
    await repository.deleteUser(user.id, deletedBy: currentUser?.id);
    ref.invalidate(allUsersProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.success,
        content: Text(l10n.translate(successKey)),
      ));
    }
    return true;
  } catch (e) {
    if (context.mounted) showError('${l10n.translate('common.error')}: $e');
    return false;
  }
}
