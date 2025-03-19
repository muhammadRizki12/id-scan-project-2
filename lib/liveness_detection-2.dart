// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
// import 'dart:developer' as dev;
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter/services.dart';
// import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
// import 'package:permission_handler/permission_handler.dart';

// class FaceAuthScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;

//   const FaceAuthScreen({super.key, required this.cameras});

//   @override
//   State<FaceAuthScreen> createState() => _FaceAuthScreenState();
// }

// class _FaceAuthScreenState extends State<FaceAuthScreen> {
//   late CameraController _cameraController;
//   late FaceDetector _faceDetector;
//   bool isProcessing = false;
//   String authStatus = "Tidak terdeteksi";

//   // Challenge management
//   List<String> challenges = [
//     'HADAP_KANAN',
//     'HADAP_KIRI',
//     'KEDIP',
//     'SENYUM',
//     'HADAP_ATAS',
//     'HADAP_BAWAH'
//   ];

//   List<String> currentChallenges = [];

//   // current chalenge
//   int currentChallengeIndex = 0;

//   // chalange complete
//   bool isChallengeComplete = false;

//   // Face detection states
//   bool isFaceDetected = false;

//   // distance
//   bool isProperDistance = false;

//   bool isCapturing = false;

//   @override
//   void initState() {
//     super.initState();
//     // init camera
//     _initializeCamera();

//     // face detector config
//     _faceDetector = FaceDetector(
//         options: FaceDetectorOptions(
//             enableClassification: true,
//             enableLandmarks: true,
//             enableContours: true));

//     // generate chalange
//     _generateNewChallenges();
//   }

//   void _generateNewChallenges() {
//     challenges.shuffle();
//     currentChallenges = challenges.take(4).toList();
//     currentChallengeIndex = 0;
//     setState(() {});
//   }

//   String _getCurrentChallenge() {
//     // check index challenge
//     if (currentChallengeIndex >= currentChallenges.length) {
//       return "Verifikasi selesai!";
//     }

//     // case check challange
//     String challenge = currentChallenges[currentChallengeIndex];
//     switch (challenge) {
//       case 'HADAP_KANAN':
//         return "Silakan hadap kanan";
//       case 'HADAP_KIRI':
//         return "Silakan hadap kiri";
//       case 'KEDIP':
//         return "Silakan kedipkan mata";
//       case 'SENYUM':
//         return "Silakan tersenyum";
//       case 'HADAP_ATAS':
//         return "Silakan hadap atas";
//       case 'HADAP_BAWAH':
//         return "Silakan hadap bawah";
//       default:
//         return "Tidak terdeteksi";
//     }
//   }

//   void _initializeCamera() {
//     // initial front camera
//     final frontCamera = widget.cameras.firstWhere(
//         (camera) => camera.lensDirection == CameraLensDirection.front,
//         orElse: () => widget.cameras.first);
//     _cameraController = CameraController(frontCamera, ResolutionPreset.high,
//         imageFormatGroup: ImageFormatGroup.nv21);
//     _cameraController.initialize().then((_) {
//       if (!mounted) return;
//       setState(() {});
//       _startFaceDetection();
//     });
//   }

//   Future<void> requestStoragePermission() async {
//     if (await Permission.storage.isDenied) {
//       await Permission.storage.request();
//     }
//     if (await Permission.photos.isDenied) {
//       await Permission.photos.request();
//     }
//   }

//   // saves fotos
//   Future<void> _captureAndSave() async {
//     try {
//       await requestStoragePermission();
//       // final directory = await getApplicationDocumentsDirectory();
//       final XFile image = await _cameraController.takePicture();
//       final Uint8List bytes = await image.readAsBytes();

//       final challengeName = currentChallenges[currentChallengeIndex];
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       // final fileName = 'liveness_${challengeName}_$timestamp';
//       final fileName = '${challengeName}_$timestamp';

//       final result = await ImageGallerySaverPlus.saveImage(bytes,
//           quality: 100, name: fileName);

//       // final filePath = path.join(directory.path, fileName);

//       // await File(image.path).copy(filePath);
//       dev.log('Image saved at: $result');
//     } catch (e) {
//       dev.log('Error capturing image: $e');
//     }
//   }

//   void _startFaceDetection() {
//     // start streaming
//     _cameraController.startImageStream((image) async {
//       if (isProcessing) return;
//       isProcessing = true;

//       // detct face
//       final faces = await _detectFaces(image);
//       setState(() {
//         isFaceDetected = faces.isNotEmpty;
//         if (!isFaceDetected) {
//           authStatus = "Tidak terdeteksi";
//           isProperDistance = false;
//         }
//       });

//       if (faces.isNotEmpty) {
//         _processFace(faces.first);
//       }

//       await Future.delayed(const Duration(milliseconds: 1000));
//       isProcessing = false;
//     });
//   }

//   Future<List<Face>> _detectFaces(CameraImage image) async {
//     final inputImage = InputImage.fromBytes(
//       bytes: _concatenatePlanes(image.planes),
//       metadata: InputImageMetadata(
//         size: Size(image.width.toDouble(), image.height.toDouble()),
//         rotation: InputImageRotation.rotation270deg,
//         format: InputImageFormat.nv21,
//         bytesPerRow: image.planes[0].bytesPerRow,
//       ),
//     );
//     return await _faceDetector.processImage(inputImage);
//   }

//   Uint8List _concatenatePlanes(List<Plane> planes) {
//     final WriteBuffer allBytes = WriteBuffer();
//     for (Plane plane in planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     return allBytes.done().buffer.asUint8List();
//   }

//   void _processFace(Face face) async {
//     final boundingBox = face.boundingBox;
//     final double headEulerAngleY = (face.headEulerAngleY! * -1);
//     final double headEulerAngleX = (face.headEulerAngleX! * -1);
//     final double leftEyeOpen = face.leftEyeOpenProbability ?? 0.0;
//     final double rightEyeOpen = face.rightEyeOpenProbability ?? 0.0;
//     final double smiling = face.smilingProbability ?? 0.0;

//     if (boundingBox.width < 100 || boundingBox.height < 100) {
//       setState(() {
//         authStatus = "Dekatkan wajah ke kamera!";
//         isProperDistance = false;
//       });
//       return;
//     }

//     isProperDistance = true;
//     String currentChallenge = currentChallenges[currentChallengeIndex];
//     bool challengeCompleted = false;

//     switch (currentChallenge) {
//       case 'HADAP_KANAN':
//         if (headEulerAngleY > 15) challengeCompleted = true;
//         break;
//       case 'HADAP_KIRI':
//         if (headEulerAngleY < -15) challengeCompleted = true;
//         break;
//       case 'KEDIP':
//         if (leftEyeOpen < 0.3 && rightEyeOpen < 0.3) challengeCompleted = true;
//         break;
//       case 'SENYUM':
//         if (smiling > 0.8) challengeCompleted = true;
//         break;
//       case 'HADAP_ATAS':
//         if (headEulerAngleX < -10) challengeCompleted = true;
//         break;
//       case 'HADAP_BAWAH':
//         if (headEulerAngleX > 10) challengeCompleted = true;
//         break;
//     }

//     if (challengeCompleted) {
//       authStatus = "$currentChallenge terdeteksi!";
//       if (!isCapturing) {
//         isCapturing = true;
//         await _captureAndSave();
//         isCapturing = false;
//       }

//       setState(() {
//         if (currentChallengeIndex < currentChallenges.length - 1) {
//           currentChallengeIndex++;
//         } else {
//           isChallengeComplete = true;
//           authStatus = "Verifikasi selesai!";
//         }
//       });
//     }
//     // else {
//     //   setState(() {
//     //     authStatus = "Wajah terdeteksi - ${_getCurrentChallenge()}";
//     //   });
//     // }
//   }

//   @override
//   void dispose() {
//     _cameraController.dispose();
//     _faceDetector.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Liveness Detection")),
//       body: Column(
//         children: [
//           Expanded(
//             child: _cameraController.value.isInitialized
//                 ? CameraPreview(_cameraController)
//                 : const Center(child: CircularProgressIndicator()),
//           ),
//           Container(
//             padding: const EdgeInsets.all(16.0),
//             color: Colors.black87,
//             child: Column(
//               children: [
//                 if (!isChallengeComplete)
//                   Text(
//                     authStatus,
//                     style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white),
//                   ),
//                 if (isChallengeComplete)
//                   Text(
//                     "Challenge telah selesai",
//                     style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
