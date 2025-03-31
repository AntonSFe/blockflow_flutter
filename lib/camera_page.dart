import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import 'gallery.dart';
import 'storage.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraDescription _activeCamera;

  late CameraDescription _frontCamera;
  late CameraDescription _backCamera;

  late CameraController _controller;
  late Future<void> _cameraInitialized;

  Timer? _timer;
  int _recordSeconds = 0;

  File? _overlayImage;

  get isRecordingVideo => _controller.value.isRecordingVideo;

  void _changeCamera() {
    setState(() {
      _activeCamera =
          _activeCamera == _frontCamera ? _backCamera : _frontCamera;

      _updateCameraController(_activeCamera);
    });
  }

  void _updateCameraController(CameraDescription camera) {
    _controller = CameraController(camera, ResolutionPreset.max);
    _cameraInitialized = _controller.initialize();
  }

  Future<void> _takePicture() async {
    try {
      final XFile picture = await _controller.takePicture();

      final String saveDir = await getStorageDirectory();
      final String newPath =
          '$saveDir/picture_${DateTime.now().millisecondsSinceEpoch}${path.extension(picture.path)}';
      await picture.saveTo(newPath);

      _showSnackBar('Picture saved to: $newPath');
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      await _controller.prepareForVideoRecording();
      await _controller.startVideoRecording();

      setState(() {
        _recordSeconds = 0;
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordSeconds++;
        });
      });
    } catch (e) {
      print('Error starting video: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      final XFile video = await _controller.stopVideoRecording();
      _timer?.cancel();
      setState(() {});

      final String saveDir = await getStorageDirectory();
      final String newPath =
          '$saveDir/video_${DateTime.now().millisecondsSinceEpoch}${path.extension(video.path)}';
      await video.saveTo(newPath);

      _showSnackBar('Video saved to: $newPath');
    } catch (e) {
      print('Error stopping video: $e');
    }
  }

  Future<void> _toggleOverlay() async {
    if (_overlayImage is File) {
      setState(() {
        _overlayImage = null;
      });

      return;
    }

    File? image = await pickImage();

    if (image is File) {
      setState(() {
        _overlayImage = image;
      });
    }
  }

  String _formatDuration(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void initState() {
    super.initState();

    _frontCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _backCamera = widget.cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    _activeCamera = _frontCamera;

    _updateCameraController(_activeCamera);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera test task')),
      body: Stack(
        children: [
          if (isRecordingVideo)
            Positioned(
              top: 0,
              right: 8,
              child: Row(
                children: [
                  Container(
                    height: 8,
                    width: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    ),
                  ),

                  const SizedBox(width: 4.0, height: 4.0),

                  Text('Rec'),

                  const SizedBox(width: 4.0, height: 4.0),

                  Text(
                    _formatDuration(_recordSeconds),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          Center(
            child: FutureBuilder(
              future: _cameraInitialized,
              builder: (context, snapshot) {
                return snapshot.connectionState == ConnectionState.done
                    ? Container(
                      foregroundDecoration:
                          (_overlayImage is File)
                              ? BoxDecoration(
                                image: DecorationImage(
                                  opacity: 0.2,
                                  image: Image.file(_overlayImage!).image,
                                ),
                              )
                              : null,
                      child: CameraPreview(_controller),
                    )
                    : const CircularProgressIndicator.adaptive();
              },
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withAlpha(20)),
              height: 120,
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _changeCamera,
                        icon: const Icon(
                          Icons.flip_camera_android,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 8.0, height: 8.0),

                      IconButton(
                        onPressed: _toggleOverlay,
                        icon:
                            _overlayImage is File
                                ? const Icon(
                                  Icons.remove_circle,
                                  size: 32,
                                  color: Colors.white,
                                )
                                : const Icon(
                                  Icons.add_circle,
                                  size: 32,
                                  color: Colors.white,
                                ),
                      ),
                    ],
                  ),

                  IconButton(
                    onPressed: _takePicture,
                    icon: const Icon(
                      Icons.photo_camera,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 32.0,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap:
                    isRecordingVideo
                        ? _stopVideoRecording
                        : _startVideoRecording,
                child: Container(
                  height: 60,
                  width: 60,
                  padding:
                      isRecordingVideo ? EdgeInsets.all(16) : EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  child: Container(
                    decoration:
                        isRecordingVideo
                            ? BoxDecoration(color: Colors.red)
                            : BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
