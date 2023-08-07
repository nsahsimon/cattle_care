import 'dart:io';
import 'dart:ui';
import 'package:cattle_care/ml_service.dart';
import 'package:cattle_care/ocr.dart';
import 'package:cattle_care/report_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

Future<List<dynamic>?> runHealthModel(String croppedImagePath) async{

  Tflite.close();
  ///Load disease classification model
  await Tflite.loadModel(
    model: "models/disease_classifier/disease_classifier.tflite",
    labels: "models/disease_classifier/labels.txt",
  );

  debugPrint("Detecting disease");
  var recognitions = await Tflite.runModelOnImage(
      path: croppedImagePath,   // required
      imageMean: 0.0,   // defaults to 117.0
      imageStd: 255.0,  // defaults to 1.0
      numResults: 1,    // defaults to 5
      threshold: 0.2,   // defaults to 0.1
      asynch: true      // defaults to true
  );

  return recognitions;
}


class HomeScreen extends StatefulWidget {

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? pickedImage;
  List? _recognitions;
  double? _imageHeight;
  double? _imageWidth;
  List<Widget> boxes = [];
  bool isLoading = false;
  Rect? cropRoi;
  String? prediction;
  String? recognizedText;
  double? confidence;
  var rel_tlx;
  var rel_tly;
  var rel_width;
  var rel_height;

  void startLoading() {
    setState(() {
      isLoading = true;
    });
  }

  void stopLoading() {
    setState(() {
      isLoading = false;
    });
  }

  double imgFrameHeight = 0.0;
  double imgFrameWidth = 0.0;

  List<Map<String, String>> myReportData = [
    {'tag_number': '12345', 'status' : 'unhealthy'},
    {'tag_number': '12346', 'status' : 'healthy'},
    {'tag_number': '12347', 'status' : 'unhealthy'},
    {'tag_number': '12348', 'status' : 'unhealthy'},
    {'tag_number': '12349', 'status' : 'healthy'},
    {'tag_number': '12340', 'status' : 'unhealthy'},
    {'tag_number': '12341', 'status' : 'healthy'},];

  Future<File?> getImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();

    try {
      XFile? pickedImageTemp = await _picker.pickImage(source: ImageSource.gallery);
      setState(() {
        pickedImage = pickedImageTemp;
        boxes = [];
        prediction = null;
        confidence = null;
      });
    } catch (e) {
      debugPrint('Error selecting image: $e');
    }

    if (pickedImage != null) {
      return File(pickedImage!.path);
    } else {
      return null;
    }
  }

  void takePhoto() async{
    final ImagePicker _picker = ImagePicker();

    try {
      XFile? pickedImageTemp = await _picker.pickImage(source: ImageSource.camera);
      setState(() {
        pickedImage = pickedImageTemp;
        boxes = [];
        prediction = null;
        confidence = null;
      });
    } catch (e) {
      debugPrint('Error selecting image: $e');
    }

    // if (pickedImage != null) {
    //   return File(pickedImage!.path);
    // } else {
    //   return null;
    // }
  }

  Future<File?> cropImage(File imageFile, int x, int y, int width, int height) async {
    try {
      // Read the image file bytes.
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode the image bytes using the decodeImage() method from the image package.
      img.Image image = img.decodeImage(imageBytes)!;

      // Perform the crop operation using the provided parameters (x, y, width, height).
      img.Image croppedImage = img.copyCrop(image, x:x, y:y, width: width, height: height);

      // Get the file extension from the original file path.
      String extension = path.extension(imageFile.path);

      // Create a temporary file for the cropped image.
      File croppedFile = await File('${imageFile.path}_cropped$extension').create();

      // Encode the cropped image and write it to the temporary file.
      croppedFile.writeAsBytesSync(img.encodePng(croppedImage));

      return croppedFile;
    } catch (e) {
      debugPrint('Error cropping image: $e');
      return null;
    }
  }

  Future detectMuzzle(File image) async {

    ///Load muzzle detection model
    await Tflite.loadModel(
      model: "models/muzzle_detector/muzzle_detector.tflite",
      labels: "models/muzzle_detector/labels.txt",
      // useGpuDelegate: true,
    );

    FileImage(image)
        .resolve(new ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageHeight = info.image.height.toDouble();
            _imageWidth = info.image.width.toDouble();
          });
        }));

      int startTime = new DateTime.now().millisecondsSinceEpoch;
      var recognitionsTemp = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1,
      );
      setState(() {
        _recognitions = recognitionsTemp;
        debugPrint('Detected ${_recognitions!.length} muzzles');
        var re = _recognitions!.first;
        rel_tlx = re["rect"]["x"] - 0.03;
        rel_tly = re["rect"]["y"] - 0.03;
        rel_width = re["rect"]["w"] + 0.08;
        rel_height = re["rect"]["h"] + 0.08;
        boxes = renderBoxes(Size(imgFrameWidth, imgFrameHeight));
      });


      cropRoi = Rect.fromLTWH(rel_tlx * _imageWidth, rel_tly * _imageHeight, rel_width * _imageWidth, rel_height * _imageHeight);
      // debugPrint("Coordinates: ${re["rect"]["x"] * factorX}, re["rect"]["y"] * factorY, re["rect"]["w"] * factorX, re["rect"]["h"] * factorY,");

      int endTime = new DateTime.now().millisecondsSinceEpoch;
      debugPrint("Inference took ${endTime - startTime}ms");

      debugPrint("Closing tflite object");
      debugPrint("tflite object succefully closed");
    }

  Future predictHealth(File image) async {


    if(cropRoi == null) return;

    debugPrint("Started cropping");
    File? croppedImage = await cropImage(image, cropRoi!.left.toInt(), cropRoi!.top.toInt(), cropRoi!.width.toInt(), cropRoi!.height.toInt());
    debugPrint("Stopped cropping");

    if(croppedImage == null) return;

    debugPrint("Detecting disease");
    String croppedImagePath = croppedImage.path;
    Map<String, dynamic> output = await MLService().detectDisease(croppedImagePath);//runHealthModel(croppedImagePath);
    debugPrint("Disease detection complete");

    // if(_recognitions == null) return;


    setState(() {
      prediction = output['predicted_class'];
      confidence = output['confidence'];
    });

    debugPrint("Prediction: $prediction, Confidence: $confidence");
    debugPrint("keys: ${output.keys}, detectedClass: ${output['detectedClass']}");
    debugPrint("Closing tflite object");
  }

  Future getEarTagNumber(File image) async {
    String? recognizedTextTemp = await performTextRecognition(image);
    if(recognizedText != null) recognizedTextTemp = recognizedTextTemp!.replaceAll('\n', "");
    setState(() {
      recognizedText = recognizedTextTemp;
    });
  }

  List<Widget> renderBoxes(Size container) {
        if (_recognitions == null) return [];
        if (_imageHeight == null || _imageWidth == null) return [];

        double factorX = container.width; //_imageWidth!;
        double factorY = _imageHeight! / _imageWidth! * container.width; // _imageHeight!;
        Color blue = Color.fromRGBO(37, 213, 253, 1.0);
        debugPrint("Rendering boxes");
        return _recognitions!.map((re) {
          // var tlx = re["rect"]["x"] - 0.05;
          // var tly = re["rect"]["y"] - 0.05;
          // var width = re["rect"]["w"] + 0.11;
          // var height = re["rect"]["h"] + 0.11;
          debugPrint("top left: ($rel_tlx, $rel_tly), Width: $rel_width, Height: $rel_height");
            return Positioned(
              left: rel_tlx * container.width ,
              top: rel_tly * container.height,
              width: rel_width * container.width,
              height: rel_height * container.height,
              child: Container(
                  decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  border: Border.all(
                    color: blue,
                    width: 2,
                    ),),
                  // child: Text(
                  //   "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
                  //   style: TextStyle(
                  //       background: Paint()..color = blue,
                  //       color: Colors.white,
                  //       fontSize: 12.0,
                  //   ),
                  // ),
                ),
              );
            }).toList();
    }

  @override
  Widget build(BuildContext context) {
      imgFrameHeight = MediaQuery.of(context).size.height * 0.4;
      imgFrameWidth = MediaQuery.of(context).size.width * 0.8;
      return ModalProgressHUD(
        inAsyncCall: isLoading,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('HomeScreen'),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: imgFrameHeight,
                  width: imgFrameWidth,
                  child: Stack(
                    children: [
                      Container(
                        height: imgFrameHeight,
                        width: imgFrameWidth,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black),
                            image: pickedImage == null ? null : DecorationImage(
                                image: FileImage(File(pickedImage!.path)),
                                fit: BoxFit.fill
                            )
                        ),
                        child: Visibility(
                          visible: pickedImage == null,
                          child: Center(
                            child: Text('No image selected'),
                          ),
                        ),
                      ),
                      ...boxes
                    ],
                  ),
                ),
                SizedBox(height: 20),
                prediction == null || confidence == null ? Container(child:null) : Text("Tag number: $recognizedText, \nPrediction: $prediction, \vConfidence: ${confidence!.toStringAsFixed(2)}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                // C(
                //   visible: prediction != null && confidence != null,
                //     child: Text("Tag number: $recognizedText, Prediction: $prediction, Confidence: ${confidence!.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold))),
                RoundedButton(text: 'Take photo', color: Colors.red, onPressed: () {
                  takePhoto();
                },),
                RoundedButton(text: 'Choose Image', color: Colors.red, onPressed: () {
                  getImageFromGallery();
                },),
                RoundedButton(text: 'Predict', color: Colors.red, onPressed: () async{
                  if(pickedImage != null) {
                    debugPrint("Detecting muzzle...");
                    await detectMuzzle(File(pickedImage!.path));
                    debugPrint("Predicting health...");
                    await predictHealth(File(pickedImage!.path));
                    debugPrint("Performing text recognition...");
                    await getEarTagNumber(File(pickedImage!.path));
                  }
                  debugPrint("Please select an image first");
                },),
                RoundedButton(text: 'View Report', color: Colors.red, onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReportScreen(reportData: myReportData)));
                },),
              ],
            ),
          ),
        ),
      );
    }
  }

class RoundedButton extends StatelessWidget {
  final String text;
  final Color color;
  final Function onPressed;

  RoundedButton({required this.text, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(MediaQuery.of(context).size.width * 0.8, 40),
        primary: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}