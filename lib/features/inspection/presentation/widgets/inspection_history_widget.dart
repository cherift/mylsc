import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../domain/models/vehicle_inspection_model.dart';
import '../providers/inspection_providers.dart';

/// Historique des inspections d'un véhicule
class InspectionHistoryWidget extends ConsumerWidget {
  const InspectionHistoryWidget({required this.truckId, super.key});

  final String truckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final inspectionsAsync = ref.watch(inspectionsStreamProvider(truckId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Iconsax.clipboard_tick,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.translate('inspection.history'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          inspectionsAsync.when(
            data: (inspections) {
              if (inspections.isEmpty) {
                return _buildEmpty(l10n);
              }
              return Column(
                children: inspections
                    .take(10)
                    .map((i) => _InspectionCard(inspection: i))
                    .toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.warning),
              ),
            ),
            error: (e, _) => Text(
              'Erreur: $e',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(
            Iconsax.clipboard_tick,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.translate('inspection.noInspections'),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InspectionCard extends StatelessWidget {
  const _InspectionCard({required this.inspection});
  final VehicleInspectionModel inspection;

  Color _stateColor() {
    switch (inspection.state) {
      case VehicleState.bonEtat:
        return AppColors.success;
      case VehicleState.bonEtatAvecObservation:
        return AppColors.warning;
      case VehicleState.nonFonctionnel:
        return AppColors.error;
      case VehicleState.accidente:
        return const Color(0xFFE91E63);
      case VehicleState.autres:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _stateColor();
    final hasPhotos =
        inspection.photoUrls != null && inspection.photoUrls!.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _InspectionDetailDialog(inspection: inspection),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.translate(inspection.state.i18nKey),
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(inspection.inspectionDate),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${l10n.translate('inspection.inspectedBy')} ${inspection.inspectedByName ?? inspection.inspectedBy}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (hasPhotos) ...[
              const SizedBox(width: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Iconsax.image, color: AppColors.info, size: 14),
                  const SizedBox(width: 2),
                  Text(
                    '${inspection.photoUrls!.length}',
                    style: const TextStyle(
                        color: AppColors.info, fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            const Icon(Iconsax.arrow_right_3,
                color: AppColors.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Dialog détail inspection ──────────────────────────────────────────────────

class _InspectionDetailDialog extends StatelessWidget {
  const _InspectionDetailDialog({required this.inspection});
  final VehicleInspectionModel inspection;

  Color _stateColor() {
    switch (inspection.state) {
      case VehicleState.bonEtat:
        return AppColors.success;
      case VehicleState.bonEtatAvecObservation:
        return AppColors.warning;
      case VehicleState.nonFonctionnel:
        return AppColors.error;
      case VehicleState.accidente:
        return const Color(0xFFE91E63);
      case VehicleState.autres:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _stateColor();
    final photos = inspection.photoUrls ?? [];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
                border: Border(
                    bottom: BorderSide(
                        color: color.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Iconsax.clipboard_tick,
                        color: color, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('inspection.title'),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm')
                              .format(inspection.inspectionDate),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // État
                    _DetailRow(
                      icon: Iconsax.activity,
                      label: l10n.translate('inspection.state'),
                      value: l10n.translate(inspection.state.i18nKey),
                      valueColor: color,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Inspecteur
                    _DetailRow(
                      icon: Iconsax.user,
                      label: l10n.translate('inspection.inspectedBy'),
                      value: inspection.inspectedByName ?? inspection.inspectedBy,
                    ),
                    // Observation
                    if (inspection.observation != null &&
                        inspection.observation!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SectionTitle(
                          l10n.translate('inspection.observation')),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: AppColors.surfaceBorder),
                        ),
                        child: Text(
                          inspection.observation!,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13),
                        ),
                      ),
                    ],

                    // Photos
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _SectionTitle(
                        '${l10n.translate('inspection.photos')} (${photos.length})',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        height: 120,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                            },
                          ),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) => _PhotoThumb(
                              url: photos[index],
                              allUrls: photos,
                              initialIndex: index,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label : ',
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Miniature photo cliquable ─────────────────────────────────────────────────

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    required this.url,
    required this.allUrls,
    required this.initialIndex,
  });
  final String url;
  final List<String> allUrls;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _PhotoViewerScreen(
            urls: allUrls,
            initialIndex: initialIndex,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.network(
          url,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 120,
            height: 120,
            color: AppColors.backgroundSecondary,
            child: const Icon(Iconsax.image,
                color: AppColors.textTertiary, size: 32),
          ),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 120,
              height: 120,
              color: AppColors.backgroundSecondary,
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppColors.warning, strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Visionneuse plein écran (swipe + zoom) ────────────────────────────────────

class _PhotoViewerScreen extends StatefulWidget {
  const _PhotoViewerScreen({
    required this.urls,
    required this.initialIndex,
  });
  final List<String> urls;
  final int initialIndex;

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.urls.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: Image.network(
                widget.urls[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Iconsax.image,
                      color: Colors.white54, size: 64),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
          );
        },
      ),
      // Indicateurs de page
      bottomNavigationBar: widget.urls.length > 1
          ? Container(
              height: 40,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
