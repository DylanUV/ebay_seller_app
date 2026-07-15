import 'dart:typed_data';
import 'package:gal/gal.dart';

/// Guarda los bytes de una imagen en la galería del dispositivo.
///
/// Funciona en Android, iOS y macOS. En Windows/Linux, `gal` no tiene
/// concepto de "galería", así que lanza una excepción que la UI atrapa
/// y sugiere usar el botón de compartir en su lugar.
Future<void> saveImageBytes(Uint8List bytes, String filename) async {
  await Gal.putImageBytes(bytes, name: filename);
}
