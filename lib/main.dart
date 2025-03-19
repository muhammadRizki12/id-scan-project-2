import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter1/ktp_ocr.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Face Detection',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: FaceAuthScreen(cameras: cameras),
      home: KTPAuthScreen(cameras: cameras),
    );
  }
}
