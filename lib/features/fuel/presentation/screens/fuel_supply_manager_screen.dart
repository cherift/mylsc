import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/fuel_request_model.dart';
import '../providers/fuel_request_providers.dart';

/// Écran du chef ravitaillement - gestion des demandes de carburant
class FuelSupplyManagerScreen extends ConsumerStatefulWidget {
  const FuelSupplyManagerScreen({super.key});

  @override
  ConsumerState<FuelSupplyManagerScreen> createState() =>
      _FuelSupplyManagerScreenState();
}

class _FuelSupplyManagerScreenState
    extends ConsumerState<FuelSupplyManagerScreen> {
  int _currentTab = 0;
  bool _showSettings = false;

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
                _buildTabBar(l10n),
                Expanded(
                  child: _currentTab == 0
                      ? _buildPendingList(l10n, user)
                      : _buildAllRequestsList(l10n),
                ),
              ],
            ),
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
            child: const Icon(
              Iconsax.gas_station,
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
                  l10n.translate('fuelRequest.title'),
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
            tooltip: l10n.translate('auth.logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: l10n.translate('fuelRequest.pendingRequests'),
              icon: Iconsax.clock,
              isSelected: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildTabButton(
              label: l10n.translate('fuelRequest.allRequests'),
              icon: Iconsax.document_text,
              isSelected: _currentTab == 1,
              onTap: () => setState(() => _currentTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 20),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList(AppLocalizations l10n, UserModel user) {
    final requestsAsync = ref.watch(pendingRequestsStreamProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: requests.length,
          itemBuilder: (context, index) =>
              _buildPendingCard(l10n, requests[index], user),
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

  Widget _buildAllRequestsList(AppLocalizations l10n) {
    final requestsAsync = ref.watch(allRequestsStreamProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: requests.length,
          itemBuilder: (context, index) =>
              _buildRequestCard(l10n, requests[index]),
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.document,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('fuelRequest.noRequests'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(
      AppLocalizations l10n, FuelRequestModel request, UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestHeader(l10n, request),
          const SizedBox(height: AppSpacing.md),
          _buildRequestDetails(l10n, request),
        ],
      ),
    );
  }

  Widget _buildRequestCard(AppLocalizations l10n, FuelRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestHeader(l10n, request),
          const SizedBox(height: AppSpacing.md),
          _buildRequestDetails(l10n, request),
          if (request.rejectionReason != null &&
              request.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.translate('fuelRequest.rejectionReason')}: ${request.rejectionReason}',
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (request.fulfilledLiters != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.translate('fuelRequest.fulfilledLiters')}: ${request.fulfilledLiters!.toStringAsFixed(0)} L',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (request.status == FuelRequestStatus.validated &&
              request.isAutoValidated) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                l10n.translate('fuel.autoValidated'),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // No reçu + photo du bon (pompiste)
          if (request.receiptNumber != null &&
              request.receiptNumber!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Iconsax.receipt_item,
                    color: AppColors.textSecondary, size: 15),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${l10n.translate('fuelRequest.receiptNumber')}: ${request.receiptNumber}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ],
          if (request.receiptPhotoUrl != null &&
              request.receiptPhotoUrl!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: AppColors.backgroundSecondary,
                  child: InteractiveViewer(
                    child: Image.network(request.receiptPhotoUrl!),
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  request.receiptPhotoUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 100,
                      color: AppColors.surface,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    height: 100,
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(Iconsax.image,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestHeader(
      AppLocalizations l10n, FuelRequestModel request) {
    final statusColor = _getStatusColor(request.status);
    final statusLabel = _getStatusLabel(l10n, request.status);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child:
              const Icon(Iconsax.truck, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.truckImmatriculation,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${request.requestedByName} • ${request.formattedDate} ${request.formattedTime}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDetails(
      AppLocalizations l10n, FuelRequestModel request) {
    return Row(
      children: [
        const Icon(Iconsax.gas_station,
            color: AppColors.textSecondary, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${request.requestedLiters.toStringAsFixed(0)} L',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (request.reason != null && request.reason!.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.lg),
          const Icon(Iconsax.document_text,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              request.reason!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(FuelRequestStatus status) {
    switch (status) {
      case FuelRequestStatus.pending:
        return AppColors.warning;
      case FuelRequestStatus.fulfilled:
        return AppColors.info;
      case FuelRequestStatus.validated:
        return AppColors.success;
      case FuelRequestStatus.disputed:
        return AppColors.error;
      case FuelRequestStatus.rejected:
        return AppColors.error;
      case FuelRequestStatus.cancelled:
        return AppColors.textTertiary;
    }
  }

  String _getStatusLabel(AppLocalizations l10n, FuelRequestStatus status) {
    switch (status) {
      case FuelRequestStatus.pending:
        return l10n.translate('fuelRequest.pending');
      case FuelRequestStatus.fulfilled:
        return l10n.translate('fuelRequest.fulfilled');
      case FuelRequestStatus.validated:
        return l10n.translate('fuelRequest.validated');
      case FuelRequestStatus.disputed:
        return l10n.translate('fuelRequest.disputed');
      case FuelRequestStatus.rejected:
        return l10n.translate('fuelRequest.rejected');
      case FuelRequestStatus.cancelled:
        return l10n.translate('fuelRequest.cancelled');
    }
  }

}
