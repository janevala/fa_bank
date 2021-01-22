import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:fa_bank/widget/spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';


class CameraScreen extends StatefulWidget {
  static const String route = '/camera_screen';

  CameraScreen({Key key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  bool isUpdatingLocalImage = false;
  List<CameraDescription> _cameras;
  CameraDescription _cameraDescription;

  @override
  void initState() {
    super.initState();

    _searchCameras();
  }

  _searchCameras() async {
    _cameras = await availableCameras();

    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) {
        setState(() {
          _cameraDescription = _cameras[i];
        });

        break;
      }
    }
    _controlCamera();
  }

  _controlCamera() {
    if (_controller == null) {
      _initCamera();
    } else if (!_controller.value.isInitialized) {
      _controller.dispose();
      _initCamera();
    }
  }

  _initCamera() {
    try {
      _controller = CameraController(_cameraDescription, ResolutionPreset.high, enableAudio: false);
      _initializeControllerFuture = _controller.initialize().then((_) {
        if (!mounted) {
          print('NOT MOUNTED');
          return;
        }
      }).catchError((onError) {
        print(onError);
      });
    } catch (onError) {
      print(onError);
    }
  }

  Future<void> _mockWait() async {
    int rand = Random().nextInt(2000);
    await Future.delayed(Duration(milliseconds: rand));
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (_controller == null || !_controller.value.isInitialized) {
          return Container(color: Colors.black);
        } else if (snapshot.connectionState == ConnectionState.done) {
          return Transform.scale(
            scale: _controller.value.aspectRatio / deviceRatio,
            child: Center(
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: CameraPreview(_controller),
                  ),
                  Spinner(),
                ],
              ),
            ),
          );
        } else {
          return Container(color: Colors.black);
        }
      },
    );
  }

  Future<String> takePicture(BuildContext context) async {
    await _initializeControllerFuture;
/*
    if (!_controller.value.isInitialized) {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.camera]);
      checkCameraPermission(permissions[PermissionGroup.camera]);
      return null;
    }*/

    final extDir = await getApplicationDocumentsDirectory();
    final dirPath = '${extDir.path}';
    await Directory(dirPath).create(recursive: true);
    final filePath = '$dirPath/${timestamp()}.jpg';

    if (_controller.value.isTakingPicture) {
      return null;
    }

    try {
//      await _controller.takePicture(filePath);
    } on CameraException catch (e) {
//      showToast(context, 'Error: ${e.code}\n${e.description}');
      return null;
    }

    return filePath;
  }

  void onCaptureButtonPressed(BuildContext context) {
    if (_controller != null) {
      takePicture(context).then((String filePath) {
        if (mounted) {
          if (filePath != null) {
//            model.openExpense(context, File(filePath));
//            showToast(context, 'Picture saved to $filePath');
//            openImagePreviewDialog(context, filePath);
          }
        }
      });
    } else {
      _controlCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Theme.of(context).primaryColor,
    ));

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(children: [
        _buildCameraPreview(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 140.0,
              color: Colors.transparent,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(),
                  ),
                  Expanded(
                    child: SizedBox(),
                  ),
                  Expanded(
                      child: Center(
                        child: IconButton(
                            icon: const Icon(Icons.close),
                            color: Theme.of(context).primaryColor,
                            iconSize: 36.0,
                            onPressed: () {}),
                      )),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              height: 100.0,
              color: Colors.transparent,
              child: Row(
                children: <Widget>[
                  Expanded(
                      child: Container()),
                  Expanded(
                      child: Container(
                        height: 60.0,
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColorLight,
                              width: 5,
                            )),
                        child: Builder(
                          builder: (BuildContext buildContext) {
                            return FloatingActionButton(
                                backgroundColor:
                                Theme.of(context).primaryColor,
                                onPressed: () {});
                          },
                        ),
                      )),
                  Expanded(
                      child: Center(
                        child: IconButton(
                            icon: const Icon(Icons.image),
                            color: Theme.of(context).primaryColor,
                            iconSize: 36.0,
                            onPressed: () {}),
                      )),
                ],
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
