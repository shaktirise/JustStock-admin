import "dart:html" as html;
import "dart:typed_data";

Future<String?> saveCsvBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  final blob = html.Blob([bytes], "text/csv");
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)..download = fileName;
  anchor.click();
  html.Url.revokeObjectUrl(url);
  return fileName;
}
