import 'dart:typed_data';
import 'dart:html' as html;

/// En web no existe "galería": lo que hacemos es que el navegador
/// descargue el archivo, como al hacer clic derecho -> "Guardar imagen como".
Future<void> saveImageBytes(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
