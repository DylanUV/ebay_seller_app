// This file has no code of its own: it just decides, based on the platform
// the app is compiled for, which real implementation to use.
//
// - image_saver_io.dart   -> Android / iOS / macOS / Windows / Linux (uses `gal`)
// - image_saver_web.dart  -> Browser (downloads the file via the browser)
//
// `dart.library.js_interop` only exists when compiling for web, so it works
// as an automatic switch (it's the modern replacement for the now-deprecated
// `dart.library.html` check).

export 'image_saver_io.dart'
    if (dart.library.js_interop) 'image_saver_web.dart';
