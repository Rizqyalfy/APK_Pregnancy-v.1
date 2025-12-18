// Conditional export: re-export the platform implementation so callers
// can use `imageThumbnail(...)` directly.
export 'image_loader_io.dart'
    if (dart.library.html) 'image_loader_web.dart';

// The exported files provide `imageThumbnail` with signature:
// Widget imageThumbnail(String path, {double width = 56, double height = 56});
