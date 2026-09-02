import 'dart:html' as html;
import 'dart:typed_data';

/// Trigger download file di browser (Flutter Web) menggunakan Blob + <a download>.
/// Ini lebih andal dibanding FilePicker.saveFile() yang belum sepenuhnya
/// diimplementasikan untuk web di beberapa versi package file_picker.
Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
