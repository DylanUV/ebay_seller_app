import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// On web there's no "gallery": instead, we make the browser download the
/// file, the same as right-clicking an image -> "Save image as".
Future<void> saveImageBytes(Uint8List bytes, String filename) async {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  anchor.click();

  web.URL.revokeObjectURL(url);
}
