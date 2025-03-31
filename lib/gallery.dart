import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<File?> pickImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? overlayImage = await picker.pickImage(
    source: ImageSource.gallery,
  );

  if (overlayImage is XFile) {
    return File(overlayImage.path);
  }
}
