import 'dart:async';
import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Délai maximal accordé à un upload avant d'abandonner (réseau instable).
const _uploadTimeout = Duration(seconds: 30);

/// Service centralisé pour la gestion des images (pick + upload + delete).
/// Utilise [XFile] comme type universel pour fonctionner sur web et mobile.
class ImageService {
  ImageService({
    FirebaseStorage? storage,
    ImagePicker? picker,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _picker = picker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _picker;

  // ── Pick ──

  /// Prendre une photo avec la caméra
  Future<XFile?> pickFromCamera({
    double maxWidth = 1200,
    double maxHeight = 1200,
    int imageQuality = 80,
  }) {
    return _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Choisir une photo depuis la galerie
  Future<XFile?> pickFromGallery({
    double maxWidth = 1200,
    double maxHeight = 1200,
    int imageQuality = 80,
  }) {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Choisir plusieurs photos depuis la galerie
  Future<List<XFile>> pickMultipleFromGallery({
    double maxWidth = 1200,
    double maxHeight = 1200,
    int imageQuality = 80,
  }) {
    return _picker.pickMultiImage(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  // ── Upload ──

  /// Upload un [XFile] (web + mobile) et retourne l'URL de téléchargement.
  /// Utilise [putData] pour garantir la compatibilité web.
  Future<String> uploadXFile(XFile xfile, String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    final bytes = await xfile.readAsBytes();
    final metadata = SettableMetadata(
      contentType: _contentTypeFromPath(xfile.name),
    );
    await ref.putData(bytes, metadata).timeout(_uploadTimeout);
    return ref.getDownloadURL();
  }

  /// Upload un [File] dart:io (mobile uniquement, utilise putFile sur mobile).
  /// Sur web, lit les bytes et utilise putData.
  Future<String> uploadFile(File file, String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await ref.putData(bytes).timeout(_uploadTimeout);
    } else {
      await ref.putFile(file).timeout(_uploadTimeout);
    }
    return ref.getDownloadURL();
  }

  /// Upload plusieurs [XFile] et retourne les URLs
  Future<List<String>> uploadXFiles(
    List<XFile> xfiles,
    String folderPath,
  ) async {
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < xfiles.length; i++) {
      final path = '$folderPath/${timestamp}_$i.jpg';
      final url = await uploadXFile(xfiles[i], path);
      urls.add(url);
    }

    return urls;
  }

  // ── Delete ──

  /// Supprimer un fichier par son URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore si le fichier n'existe pas
    }
  }

  /// Supprimer plusieurs fichiers par leurs URLs
  Future<void> deleteMultipleByUrls(List<String> urls) async {
    for (final url in urls) {
      await deleteByUrl(url);
    }
  }

  // ── Helpers ──

  String _contentTypeFromPath(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
