import "dart:typed_data";

import "file_saver_io.dart"
    if (dart.library.html) "file_saver_web.dart" as saver;

Future<String?> saveCsvBytes({
  required Uint8List bytes,
  required String fileName,
}) {
  return saver.saveCsvBytes(bytes: bytes, fileName: fileName);
}
