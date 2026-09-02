// Conditional export: pakai implementasi dart:html di Flutter Web,
// dan implementasi fallback (file_picker) di platform lain.
export 'download_helper_io.dart'
    if (dart.library.html) 'download_helper_web.dart';
