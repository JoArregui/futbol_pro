import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Descarga un fichero con el cliente autenticado (JWT) y lo guarda
/// en documentos (móvil/desktop). En web abre la URL externa.
/// Devuelve la ruta guardada o la URL abierta.
class FileDownloadService {
  final http.Client client;
  FileDownloadService(this.client);

  Future<String> downloadText({
    required String apiPath,
    required String filename,
  }) async {
    final uri = Uri.parse(apiPath);
    if (kIsWeb) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return uri.toString();
    }
    final res = await client.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Descarga falló: ${res.statusCode}');
    }
    final dir = (await getApplicationDocumentsDirectory()).path;
    final file = File('$dir/$filename');
    await file.writeAsBytes(res.bodyBytes);
    return file.path;
  }
}
