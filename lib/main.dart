import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'camera_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

  return runApp(
    MaterialApp(
      home: CameraPage(cameras: cameras),
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
    ),
  );
}
