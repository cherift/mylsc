/// Stub pour les plateformes non-web (mobile, desktop).
/// Le téléchargement est géré via path_provider + share_plus.
void downloadFileWeb(String content, String filename) {
  // No-op : non appelé sur les plateformes non-web
}

/// Stub binaire pour les plateformes non-web.
void downloadFileBytesWeb(List<int> bytes, String filename) {
  // No-op : non appelé sur les plateformes non-web
}
