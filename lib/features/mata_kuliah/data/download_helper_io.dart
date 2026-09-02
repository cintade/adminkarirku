import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// Fallback untuk platform non-web (desktop/mobile): pakai dialog simpan file.
Future<void> downloadBytes(Uint8List bytes, String fileName) async {
  await FilePicker.platform.saveFile(
    dialogTitle: 'Simpan File',
    fileName: fileName,
    bytes: bytes,
  );
}
