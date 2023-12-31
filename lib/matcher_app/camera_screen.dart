import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:cattle_care/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_opencv_plugin/flutter_opencv_plugin.dart';
// import 'package:image/image.dart' as imglib;
// import '../constants.dart';
var cameras;
/// CameraApp is the Main Application.
class CameraScreen extends StatefulWidget {

  CameraScreen();

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? controller;
  String imagePath = "";
  bool imageTaken = false;
  List<Positioned> cornerAvatars = [];
  List<List<double>> prevCorners = [];
  List<List<double>> cornerPoints = [];
  bool isDetecting = false;
  bool detectedValidFrame = false;
  late CameraImage frame;
  late double roiWidthFactor;
  late double roiHeightFactor;
  double lowerBarLengthFraction = 0.4;
  int detectedSpotCount = 0;
  bool detectedValidSpot = false;
  List<int> prevDetectedSpotCounts = List<int>.filled(5, 0,growable: true); //Keep track of the last 10 spot counts
  int prevDetectedSpotCountIdx = 0; //has a max value of 9
  int maxIdx = 4;
  bool imageClear = false;
  bool imageInFocus = true;
  String? prediction = "hello";
  int nullDetectionCount = 0;



  @override
  void initState() {
    super.initState();
    Future(()async{
      try {
        cameras = await availableCameras();
        debugPrint("There ${cameras.length} Cameras available");
        final camera = cameras!.first;
        controller = CameraController(camera, ResolutionPreset.medium);
        setState(() {

        });
      }catch(e) {
        return;
      }

        controller?.initialize().then((_) {
        controller!.setExposureMode(ExposureMode.auto);
        controller!.setFocusMode(FocusMode.auto);
        // controller!.setFlashMode(FlashMode.torch);
        debugPrint("Started image Stream");
        controller!.startImageStream(
                (imgFrame) async{
              frame = imgFrame;
              /// Do not detect skin lesions if already detecting skin lession
              int sensorExpTime = frame.sensorExposureTime ?? -1;
              if(isDetecting == true && sensorExpTime < 50000000) return;
              if(mounted) {
                setState(() {
                  isDetecting = true;
                });
              }
              int start = DateTime.now().microsecondsSinceEpoch;
              String? tempPrediction = await Opencv().findBestMatch(frame: frame);
              await Future.delayed(Duration(milliseconds: 600));

              if(mounted){
                setState(() {
                  prediction = tempPrediction;

                  if(prediction == null) {
                    nullDetectionCount++;
                  } else {
                        nullDetectionCount = 0;
                        Map<String, String> newData = {"cattle_id" : prediction! , "status" : "Present"};
                        bool alreadyContainsCattle = false;
                        for(var data in myAttendanceReportData) {
                          if(data['cattle_id'] == newData['cattle_id']) {
                            alreadyContainsCattle = true;
                            break;
                          }
                        }
                        if(alreadyContainsCattle == false) {
                          myAttendanceReportData.add(newData);
                        }
                  }
                });
              }

              int stop = DateTime.now().microsecondsSinceEpoch;
              if(mounted) {
                setState(() {
                  isDetecting = false;
                });
              }
            }
        );
        if(mounted) {
          setState(() {
          });
        }

      });
    });

  }

  Color blackTransparent = Colors.black.withOpacity(0.5);


  @override
  void dispose() {
    Opencv().close();
    try {
      controller!.stopImageStream();
    }catch(e) {
      debugPrint("$e");
    }
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Opencv().close();
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
    }

  }


  Widget changeOrientationMessage() {
    return nullDetectionCount > 3 ? Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Try rotating your phone" , style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        SizedBox(width: 10),
        Icon(Icons.screen_rotation_sharp, color: Colors.green, size: 20)
      ],
    ) : Container();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return Container();
    }
    // controller!.setZoomLevel(1.6);
    double displayHeight = MediaQuery.of(context).size.height;
    double displayWidth = MediaQuery.of(context).size.width;
    return SafeArea(
          child: Scaffold(
            body: Stack(
                  children: [
                    Container(
                        width: displayWidth,
                        height: displayHeight,
                        child: CameraPreview(controller!)),
                    Column(
                      children: [
                        Expanded(
                            child: Container(
                                color: blackTransparent,
                                child: Center(
                                  child: changeOrientationMessage()
                                )
                            )),
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Expanded(child: Container(color: blackTransparent)),
                              Expanded(
                                  flex: 4, child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        width: 5,
                                        color: prediction == null ? Colors.red : Colors.green)
                                  ),
                              )),
                              Expanded(
                                  child: Container(
                                      color: blackTransparent,
                                  )),
                            ]
                          ),
                        ),
                        Expanded(child: Container(
                            color: blackTransparent,
                          child: Center(
                              child: Text(prediction??"", style: TextStyle(color: Colors.white))
                          ),
                        )),
                      ],
                    )
                  ],
                ),
            ),

          );
  }
}

class FeedbackTile extends StatelessWidget {
  const FeedbackTile({
    super.key,
    required this.title,
    required this.state,
  });

  final bool state;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: TextStyle(color: Colors.white)),
        SizedBox(width: 20),
        state == false ? Icon(Icons.close, color: Colors.red) : Icon(Icons.check, color: Colors.green)
      ],
    );
  }
}
