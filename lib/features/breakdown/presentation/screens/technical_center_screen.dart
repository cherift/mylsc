import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/breakdown_report_model.dart';
import '../providers/breakdown_providers.dart';

/// Écran du centre technique - gestion des pannes
class TechnicalCenterScreen extends ConsumerStatefulWidget {
  const TechnicalCenterScreen({super.key});

  @override
  ConsumerState<TechnicalCenterScreen> createState() =>
      _TechnicalCenterScreenState();
}

class _TechnicalCenterScreenState
    extends ConsumerState<TechnicalCenterScreen> {
  int _currentTab = 0;
  bool _showSettings = false;
  bool _isProcessing = false;

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
                      ? _buildActiveList(l10n, user)
                      : _buildAllList(l10n),
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
              Iconsax.setting_4,
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
                  l10n.translate('breakdown.title'),
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
              label: l10n.translate('breakdown.activeBreakdowns'),
              icon: Iconsax.warning_2,
              isSelected: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildTabButton(
              label: l10n.translate('breakdown.allBreakdowns'),
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

  Widget _buildActiveList(AppLocalizations l10n, UserModel user) {
    final breakdownsAsync = ref.watch(activeBreakdownsStreamProvider);

    return breakdownsAsync.when(
      data: (breakdowns) {
        if (breakdowns.isEmpty) {
          return _buildEmptyState(l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: breakdowns.length,
          itemBuilder: (context, index) =>
              _buildActiveCard(l10n, breakdowns[index], user),
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

  Widget _buildAllList(AppLocalizations l10n) {
    final breakdownsAsync = ref.watch(allBreakdownsStreamProvider);

    return breakdownsAsync.when(
      data: (breakdowns) {
        if (breakdowns.isEmpty) {
          return _buildEmptyState(l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: breakdowns.length,
          itemBuilder: (context, index) =>
              _buildBreakdownCard(l10n, breakdowns[index]),
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
          Icon(Iconsax.tick_circle,
              color: AppColors.success.withValues(alpha: 0.5), size: 64),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.translate('breakdown.noBreakdowns'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCard(
      AppLocalizations l10n, BreakdownReportModel breakdown, UserModel user) {
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
          _buildBreakdownHeader(l10n, breakdown),
          const SizedBox(height: AppSpacing.md),
          _buildBreakdownDetails(l10n, breakdown),
          const SizedBox(height: AppSpacing.lg),
          _buildActionButtons(l10n, breakdown, user),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
      AppLocalizations l10n, BreakdownReportModel breakdown) {
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
          _buildBreakdownHeader(l10n, breakdown),
          const SizedBox(height: AppSpacing.md),
          _buildBreakdownDetails(l10n, breakdown),
          if (breakdown.diagnosticResults != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${l10n.translate('breakdown.diagnostic')}: ${breakdown.diagnosticResults}',
              style: const TextStyle(
                color: AppColors.info,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownHeader(
      AppLocalizations l10n, BreakdownReportModel breakdown) {
    final statusColor = _getStatusColor(breakdown.status);
    final statusLabel = _getStatusLabel(l10n, breakdown.status);
    final severityColor = _getSeverityColor(breakdown.severity);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(Iconsax.warning_2, color: severityColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                breakdown.truckImmatriculation,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${breakdown.reportedByName} • ${breakdown.formattedDate} ${breakdown.formattedTime}',
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

  Widget _buildBreakdownDetails(
      AppLocalizations l10n, BreakdownReportModel breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: _getSeverityColor(breakdown.severity)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                _getSeverityLabel(l10n, breakdown.severity),
                style: TextStyle(
                  color: _getSeverityColor(breakdown.severity),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (breakdown.location != null) ...[
              const SizedBox(width: AppSpacing.md),
              const Icon(Iconsax.location,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                breakdown.location!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          breakdown.description,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (breakdown.assignedToName != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Iconsax.user, color: AppColors.primary, size: 16),
              const SizedBox(width: 4),
              Text(
                '${l10n.translate('breakdown.assignedTo')}: ${breakdown.assignedToName}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
      AppLocalizations l10n, BreakdownReportModel breakdown, UserModel user) {
    switch (breakdown.status) {
      case BreakdownStatus.pending:
        return _buildAssignButton(l10n, breakdown, user);
      case BreakdownStatus.inDiagnostic:
        return _buildDiagnosticButton(l10n, breakdown);
      case BreakdownStatus.inRepair:
        return _buildResolveButton(l10n, breakdown, user);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAssignButton(
      AppLocalizations l10n, BreakdownReportModel breakdown, UserModel user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing
            ? null
            : () => _assignToSelf(breakdown, user),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        icon: const Icon(Iconsax.user_add, color: Colors.white, size: 20),
        label: Text(
          l10n.translate('breakdown.assignTechnician'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildDiagnosticButton(
      AppLocalizations l10n, BreakdownReportModel breakdown) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing
            ? null
            : () => _showDiagnosticDialog(breakdown),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.info,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        icon: const Icon(Iconsax.search_normal,
            color: Colors.white, size: 20),
        label: Text(
          l10n.translate('breakdown.saveDiagnostic'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildResolveButton(
      AppLocalizations l10n, BreakdownReportModel breakdown, UserModel user) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isProcessing
            ? null
            : () => _showResolveDialog(breakdown, user),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        icon: const Icon(Iconsax.tick_circle,
            color: Colors.white, size: 20),
        label: Text(
          l10n.translate('breakdown.resolve'),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _assignToSelf(
      BreakdownReportModel breakdown, UserModel user) async {
    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(breakdownRepositoryProvider);
      await repository.assignTechnician(
        breakdownId: breakdown.id,
        assignedTo: user.id,
        assignedToName: user.fullName,
      );

      ref.invalidate(activeBreakdownsStreamProvider);
      ref.invalidate(allBreakdownsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('common.success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('common.error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showDiagnosticDialog(BreakdownReportModel breakdown) async {
    final l10n = AppLocalizations.of(context);
    final diagnosticController = TextEditingController();
    final partsController = TextEditingController();
    final timeController = TextEditingController();
    final costController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('breakdown.diagnostic'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diagnosticController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.translate('breakdown.diagnosticResults'),
                  hintText: l10n.translate('breakdown.diagnosticHint'),
                  hintStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: partsController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.translate('breakdown.partsNeeded'),
                  hintText: l10n.translate('breakdown.partsHint'),
                  hintStyle:
                      const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: timeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText:
                      l10n.translate('breakdown.estimatedRepairTime'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: l10n.translate('breakdown.estimatedCost'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.info,
            ),
            child: Text(
              l10n.translate('breakdown.saveDiagnostic'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (diagnosticController.text.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(breakdownRepositoryProvider);
      final parts = partsController.text.trim().isNotEmpty
          ? partsController.text
              .split(',')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList()
          : null;

      await repository.saveDiagnostic(
        breakdownId: breakdown.id,
        diagnosticResults: diagnosticController.text.trim(),
        partsNeeded: parts,
        estimatedRepairTime: double.tryParse(timeController.text.trim()),
        estimatedCost: double.tryParse(costController.text.trim()),
      );

      ref.invalidate(activeBreakdownsStreamProvider);
      ref.invalidate(allBreakdownsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('common.success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('common.error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showResolveDialog(
      BreakdownReportModel breakdown, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final timeController = TextEditingController();
    final costController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('breakdown.resolve'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: timeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.translate('breakdown.actualRepairTime'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: costController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.translate('breakdown.actualCost'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: Text(
              l10n.translate('breakdown.resolve'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final repository = ref.read(breakdownRepositoryProvider);
      await repository.resolveBreakdown(
        breakdownId: breakdown.id,
        resolvedBy: user.id,
        resolvedByName: user.fullName,
        actualRepairTime: double.tryParse(timeController.text.trim()),
        actualCost: double.tryParse(costController.text.trim()),
      );

      ref.invalidate(activeBreakdownsStreamProvider);
      ref.invalidate(allBreakdownsStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('common.success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${AppLocalizations.of(context).translate('common.error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Color _getStatusColor(BreakdownStatus status) {
    switch (status) {
      case BreakdownStatus.pending:
        return AppColors.warning;
      case BreakdownStatus.inDiagnostic:
        return AppColors.info;
      case BreakdownStatus.inRepair:
        return AppColors.primary;
      case BreakdownStatus.resolved:
        return AppColors.success;
      case BreakdownStatus.closed:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(AppLocalizations l10n, BreakdownStatus status) {
    switch (status) {
      case BreakdownStatus.pending:
        return l10n.translate('breakdown.pending');
      case BreakdownStatus.inDiagnostic:
        return l10n.translate('breakdown.inDiagnostic');
      case BreakdownStatus.inRepair:
        return l10n.translate('breakdown.inRepair');
      case BreakdownStatus.resolved:
        return l10n.translate('breakdown.resolved');
      case BreakdownStatus.closed:
        return l10n.translate('breakdown.closed');
    }
  }

  Color _getSeverityColor(BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return AppColors.info;
      case BreakdownSeverity.medium:
        return AppColors.warning;
      case BreakdownSeverity.high:
        return AppColors.error;
      case BreakdownSeverity.critical:
        return const Color(0xFFB71C1C);
    }
  }

  String _getSeverityLabel(
      AppLocalizations l10n, BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return l10n.translate('breakdown.severityLow');
      case BreakdownSeverity.medium:
        return l10n.translate('breakdown.severityMedium');
      case BreakdownSeverity.high:
        return l10n.translate('breakdown.severityHigh');
      case BreakdownSeverity.critical:
        return l10n.translate('breakdown.severityCritical');
    }
  }
}
