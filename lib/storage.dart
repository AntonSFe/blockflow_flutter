import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> getStorageDirectory() async {
  final directory = await getApplicationDocumentsDirectory();
  final customDir = Directory('${directory.path}/camera_files');
  if (!await customDir.exists()) {
    await customDir.create(recursive: true);
  }
  return customDir.path;
}
