import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../i18n/app_localizations.dart';

/// Widget réutilisable pour sélectionner et afficher des photos.
/// Utilise [XFile] pour être compatible web et mobile.
class PhotoPickerWidget extends StatelessWidget {
  const PhotoPickerWidget({
    required this.photos,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
    super.key,
    this.existingUrls = const [],
    this.onRemoveUrl,
    this.onTapUrl,
    this.maxPhotos = 5,
    this.photoHeight = 120.0,
  });

  /// Photos locales (XFile) pas encore uploadées
  final List<XFile> photos;

  /// URLs de photos déjà uploadées (mode édition)
  final List<String> existingUrls;

  /// Callbacks (null = mode lecture seule, boutons masqués)
  final VoidCallback? onPickCamera;
  final VoidCallback? onPickGallery;
  final void Function(int index) onRemove;
  final void Function(int index)? onRemoveUrl;
  final void Function(String url)? onTapUrl;
  final int maxPhotos;
  final double photoHeight;

  int get _totalPhotos => photos.length + existingUrls.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.translate('photos.title'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$_totalPhotos / $maxPhotos',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Photos existantes (URLs)
        if (existingUrls.isNotEmpty) ...[
          SizedBox(
            height: photoHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: existingUrls.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _buildUrlPhoto(existingUrls[index], index);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Photos locales
        if (photos.isNotEmpty) ...[
          SizedBox(
            height: photoHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return _buildXFilePhoto(photos[index], index);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Boutons de sélection (masqués en mode lecture seule)
        if (_totalPhotos < maxPhotos &&
            (onPickCamera != null || onPickGallery != null))
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickCamera,
                  icon: const Icon(Iconsax.camera, size: 20),
                  label: Text(l10n.translate('photos.camera')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickGallery,
                  icon: const Icon(Iconsax.gallery, size: 20),
                  label: Text(l10n.translate('photos.gallery')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// Affiche un XFile de façon compatible web + mobile.
  /// Web  : XFile.path est une blob URL → Image.network()
  /// Mobile: XFile.path est un chemin fichier → Image.file()
  Widget _buildXFilePhoto(XFile xfile, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: kIsWeb
              ? Image.network(
                  xfile.path,
                  width: photoHeight,
                  height: photoHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _errorBox(),
                )
              : Image.file(
                  File(xfile.path),
                  width: photoHeight,
                  height: photoHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _errorBox(),
                ),
        ),
        _buildRemoveButton(() => onRemove(index)),
      ],
    );
  }

  Widget _buildUrlPhoto(String url, int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTapUrl != null ? () => onTapUrl!(url) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              url,
              width: photoHeight,
              height: photoHeight,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _errorBox(),
            ),
          ),
        ),
        if (onRemoveUrl != null)
          _buildRemoveButton(() => onRemoveUrl!(index)),
      ],
    );
  }

  Widget _errorBox() {
    return Container(
      width: photoHeight,
      height: photoHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: const Icon(
        Iconsax.image,
        color: AppColors.textSecondary,
        size: 32,
      ),
    );
  }

  Widget _buildRemoveButton(VoidCallback onTap) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.close_circle,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher une photo en plein écran
class PhotoViewerDialog extends StatelessWidget {
  const PhotoViewerDialog({required this.url, super.key});

  final String url;

  static void show(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (context) => PhotoViewerDialog(url: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Stack(
        children: [
          InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.close_circle,
                    color: AppColors.textPrimary, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche une image depuis un [XFile] de façon compatible web + mobile.
Widget buildXFileImage({
  required XFile xfile,
  required double size,
  BoxFit fit = BoxFit.cover,
}) {
  return kIsWeb
      ? Image.network(xfile.path, width: size, height: size, fit: fit)
      : Image.file(File(xfile.path), width: size, height: size, fit: fit);
}
