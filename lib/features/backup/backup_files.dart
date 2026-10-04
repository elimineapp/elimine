import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// The system dialogs for saving and opening a backup, behind an interface
/// so tests can replace them.
abstract interface class BackupFiles {
  /// Lets the user save [content] as [fileName]; false when cancelled.
  Future<bool> save(String fileName, String content);

  /// Lets the user pick a file and returns its text; null when cancelled.
  Future<String?> open();
}

class SystemBackupFiles implements BackupFiles {
  const SystemBackupFiles();

  @override
  Future<bool> save(String fileName, String content) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(content),
      mimeType: 'application/json',
    );
    return uri != null;
  }

  @override
  Future<String?> open() async {
    // Any type: document providers often report JSON as octet-stream, and
    // the content check decides anyway.
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }
}
