import "dart:io";
import "dart:typed_data";

import "package:file_picker/file_picker.dart";

Future<String?> saveCsvBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final savePath = await FilePicker.platform.saveFile(
    dialogTitle: "Save withdrawals CSV",
    fileName: fileName,
    allowedExtensions: const ["csv"],
    type: FileType.custom,
  );
  if (savePath == null) return null;

  final file = File(savePath);
  await file.writeAsBytes(bytes, flush: true);
  return savePath;
}
