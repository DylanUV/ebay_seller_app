import 'dart:typed_data';
import 'package:gal/gal.dart';

/// Saves an image's bytes to the device's gallery.
///
/// Works on Android, iOS and macOS. On Windows/Linux, `gal` has no concept
/// of a "gallery", so it throws an exception that the UI catches and uses
/// to suggest the share button instead.
Future<void> saveImageBytes(Uint8List bytes, String filename) async {
  await Gal.putImageBytes(bytes, name: filename);
}
