import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'file_download.dart';

/// Imprime ou exporte un PDF selon la plateforme.
///
/// - **Web** : téléchargement direct du PDF dans le navigateur via blob URL.
///   Évite les MissingPluginException (sharePdf / printPdf non supportés sur web).
///   L'utilisateur reçoit le fichier et peut l'imprimer depuis son lecteur PDF.
///
/// - **Mobile / Desktop** : dialogue d'impression natif via Printing.layoutPdf.
Future<void> printOrSharePdf(
  Uint8List bytes, {
  required String filename,
}) async {
  if (kIsWeb) {
    downloadFileBytesWeb(bytes, filename);
  } else {
    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: filename,
    );
  }
}
