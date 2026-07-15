// Este archivo no tiene código propio: solo decide, según la plataforma
// donde se compila la app, cuál implementación real usar.
//
// - image_saver_io.dart   -> Android / iOS / macOS / Windows / Linux (usa `gal`)
// - image_saver_web.dart  -> Navegador (descarga el archivo con el navegador)
//
// `dart.library.html` solo existe cuando se compila para web, por eso sirve
// como interruptor automático.

export 'image_saver_io.dart' if (dart.library.html) 'image_saver_web.dart';
