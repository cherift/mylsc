import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../i18n/app_localizations.dart';
import '../providers/update_provider.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

/// Point d'entrée de l'application : vérifie la version avant d'afficher [child].
class UpdateGate extends ConsumerStatefulWidget {
  const UpdateGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends ConsumerState<UpdateGate> {
  bool _optionalDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final updateAsync = ref.watch(updateCheckProvider);
    final l10n = AppLocalizations.of(context);

    return updateAsync.when(
      error: (_, __) => widget.child,
      loading: () => const _SplashScreen(),
      data: (config) {
        if (config == null || config.status == UpdateStatus.none) {
          return widget.child;
        }
        if (config.isForced) {
          return _ForceUpdateScreen(config: config, l10n: l10n);
        }
        if (config.isOptional && !_optionalDialogShown) {
          _optionalDialogShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showOptionalDialog(config, l10n);
          });
        }
        return widget.child;
      },
    );
  }

  Future<void> _showOptionalDialog(
      AppUpdateConfig config, AppLocalizations l10n) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _UpdateDialog(config: config, l10n: l10n),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Splash
// ─────────────────────────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AppLogo(size: 80),
              SizedBox(height: AppSpacing.lg),
              _AppNameText(),
              SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Écran bloquant — mise à jour obligatoire
// ─────────────────────────────────────────────────────────────────────────────

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen({required this.config, required this.l10n});

  final AppUpdateConfig config;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration:
              const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const _AppLogo(size: 72),
                  const SizedBox(height: AppSpacing.sm),
                  const _AppNameText(),
                  const Spacer(flex: 2),
                  _UpdateCard(
                    icon: Iconsax.refresh,
                    accentColor: AppColors.warning,
                    title: l10n.translate('update.requiredTitle'),
                    versionBadge:
                        '${l10n.translate('update.currentVersion')}: ${config.currentVersion}'
                        '   →   ${config.minVersion}',
                    actions: _StoreButton(config: config, l10n: l10n),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialog — mise à jour optionnelle
// ─────────────────────────────────────────────────────────────────────────────

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.config, required this.l10n});

  final AppUpdateConfig config;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: _UpdateCard(
        icon: Iconsax.refresh,
        accentColor: AppColors.primary,
        title: l10n.translate('update.title'),
        versionBadge:
            '${l10n.translate('update.latestVersion')}: ${config.latestVersion}',
        actions: Column(
          children: [
            _StoreButton(config: config, l10n: l10n),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: Text(
                  l10n.translate('update.laterButton'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Carte partagée
// ─────────────────────────────────────────────────────────────────────────────

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.versionBadge,
    required this.actions,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String versionBadge;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: accentColor.withValues(alpha: 0.06),
            blurRadius: 60,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: accentColor, size: 32),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Titre
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Badge version
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              versionBadge,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action(s)
          actions,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bouton store
// ─────────────────────────────────────────────────────────────────────────────

class _StoreButton extends StatelessWidget {
  const _StoreButton({required this.config, required this.l10n});

  final AppUpdateConfig config;
  final AppLocalizations l10n;

  Future<void> _openStore(BuildContext context) async {
    String urlStr;
    if (kIsWeb) {
      urlStr = Uri.base.toString();
    } else {
      final isIos = Theme.of(context).platform == TargetPlatform.iOS;
      urlStr = isIos ? config.storeUrlIos : config.storeUrlAndroid;
    }
    if (urlStr.isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_self');
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = kIsWeb
        ? l10n.translate('update.refreshButton')
        : l10n.translate('update.updateButton');
    const icon = kIsWeb ? Iconsax.refresh : Iconsax.export_2;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => _openStore(context),
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: Colors.white.withValues(alpha: 0.15),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo de l'application
// ─────────────────────────────────────────────────────────────────────────────

class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Iconsax.truck,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nom de l'application
// ─────────────────────────────────────────────────────────────────────────────

class _AppNameText extends StatelessWidget {
  const _AppNameText();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'My LSC',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Logistic System Control',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.8,
          ),
        ),
      ],
    );
  }
}
