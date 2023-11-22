import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'dart:math' as Math;
import 'dart:async' as async;

const int imageSize = 416;
const int imageSizeHealth = 224;
const Map<String, String> healthLabels = {
  "0" :"healthy",
  "1" :"unhealthy"
};

late Interpreter muzzleDetectionInterpreter;

class MLService {
  static late Interpreter interpreter;
  static InterpreterOptions interpreterOptions = InterpreterOptions()..threads = 2;

  MLService();

  static Future<void> initialize() async {
    try {
      interpreter = await Interpreter.fromAsset("models/disease_classifier/disease_classifier.tflite", options: interpreterOptions);
      debugPrint("Successfully initialized disease classifier Model");
    }catch(e) {
      debugPrint("$e");
      debugPrint("Failed to Initialize disease classifier model");
    }
    try {
      muzzleDetectionInterpreter = await Interpreter.fromAsset("models/muzzle_detector/muzzle_detector.tflite", options: interpreterOptions);
      debugPrint("Successfully initialized muzzle detection Model");
    }catch(e) {
      debugPrint("$e");
      debugPrint("Failed to initialize muzzle detection model");
    }

  }

  Future<Map<String, dynamic>> detectDisease(String imagePath) async {
    var _file = io.File(imagePath);
    img.Image imageTemp = img.decodeImage(_file.readAsBytesSync())!;
    debugPrint("Resizing image");
    img.Image resizedImage = img.copyResize(imageTemp, width: 224, height: 224);
    debugPrint("Number of channels: ${resizedImage.numChannels}, Format: ${resizedImage.format}");
    Uint8List imgBytes = resizedImage.getBytes();
    Uint8List imgAsList = imgBytes.buffer.asUint8List();
    debugPrint("Getting predictions for: ${imagePath}");
    return getHealthPrediction(imgAsList);
  }

  /// Detecting muzzles using google object detection API (google_ml_kit)
  Future<Map<String, dynamic>> _detectMuzzle(String imagePath) async {
    final InputImage  inputImage = InputImage.fromFilePath(imagePath);
    // Options to configure the detector while using with base model.
    final mode = DetectionMode.single;
    final modelPath = await getModelPath('models/muzzle_detector/muzzle_detector.tflite');
    final options = LocalObjectDetectorOptions(
      mode: mode,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );


    final objectDetector = ObjectDetector(options: options);

    final List<DetectedObject> objects = await objectDetector.processImage(inputImage);

    debugPrint("Detected : ${objects.length} muzzles");

    for(DetectedObject detectedObject in objects){
      final rect = detectedObject.boundingBox;
      final trackingId = detectedObject.trackingId;

      for(Label label in detectedObject.labels){
        debugPrint('${label.text} ${label.confidence}');
      }
    }


    return <String, dynamic>{};
  }

  /// Detecting muzzles using tensorflow
  Future<List<Map<String, dynamic>>> detectMuzzle(String imagePath) async {
    var _file = io.File(imagePath);
    img.Image imageTemp = img.decodeImage(_file.readAsBytesSync())!;
    debugPrint("Resizing image");
    img.Image resizedImage = img.copyResize(imageTemp, width: imageSize, height: imageSize);
    debugPrint("Number of channels: ${resizedImage.numChannels}, Format: ${resizedImage.format}");
    Uint8List imgBytes = resizedImage.getBytes();
    Uint8List imgAsList = imgBytes.buffer.asUint8List();
    debugPrint("Getting predictions for: ${imagePath}");
    return await getMuzzlePrediction(imgAsList);
  }

  // Future<List<Map<String, dynamic>>> isolateGetMuzzlePrediction(Map<String, dynamic> data) async {
  //   var imageAsList = data['image_as_list'];
  //   var muzzleInterpreter = data['muzzle_interpreter'];
  //   var
  //   getM
  // }

  Future<Map<String, dynamic>> getHealthPrediction(Uint8List imgAsList) async {
    int classNum = healthLabels.length;
    // final List<dynamic> resultBytes = List.filled(mnistSize * mnistSize, 0.0);
    final List<dynamic> resultBytes = List.filled(imageSizeHealth * imageSizeHealth * 3, 0.0);
    debugPrint("Image as list length: ${imgAsList.length}");
    int index = 0;
    try {
      for (int i = 0; i < imgAsList.length - 3; i += 3) {
        final r = imgAsList[i];
        final g = imgAsList[i+1];
        final b = imgAsList[i+2];

        // Take the mean of R,G,B channel into single GrayScale
        resultBytes[index] = (r / 127.5) - 1; //(((r + g + b) / 3) / 255);
        index++;
        resultBytes[index+1] = (g / 127.5) - 1;
        index++;
        resultBytes[index+2] = (b / 127.5) - 1;
        index++;
      }
    }catch (e) {
      debugPrint("$e");
    }

    debugPrint("Result bytes length: ${resultBytes.length}");

    var input = resultBytes.reshape([1, imageSizeHealth, imageSizeHealth, 3]);
    var output = List.filled(classNum, 0.0).reshape([1, classNum]);

    // Track how long it took to do inference
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    try {
      interpreter.run(input, output);
    } catch (e) {
      debugPrint('Error loading or running model: ' + e.toString());
    }

    int endTime = new DateTime.now().millisecondsSinceEpoch;
    debugPrint("Inference took ${endTime - startTime} ms");

    // Obtain the highest score from the output of the model
    double highestProb = 0;
    late String prediction;

    // double total = output[0].reduce((a, b) => a + b);
    double total = 0.0;
    for (int i = 0; i < output[0].length; i++) {
      total+=output[0][i];
      if (output[0][i] > highestProb) {
        highestProb = output[0][i];
        prediction = healthLabels["${i.toString()}"]??"";
      }
    }
    debugPrint("predicted_class : $prediction, confidence : ${highestProb * 100 / total}");
    return {"predicted_class" : prediction, "confidence" : highestProb * 100 / total };
  }

  /// Get muzzle prediction using the tflite_flutter package
  static Future<List<Map<String, dynamic>>> getMuzzlePrediction(Uint8List imgAsList) async {
    // final List<dynamic> resultBytes = List.filled(mnistSize * mnistSize, 0.0);
    final List<dynamic> inputBytes = List.filled(imageSize * imageSize * 3, 0.0);
    debugPrint("Image as list length: ${imgAsList.length}");
    int index = 0;
    try {
      for (int i = 0; i < imgAsList.length - 6; i += 3) {
        final r = imgAsList[i];
        final g = imgAsList[i+1];
        final b = imgAsList[i+2];

        // Normalize the pixel values
        inputBytes[index] = r / 255.0; // (r / 127.5) - 1; // (((r + g + b) / 3) / 255);
        index++;
        inputBytes[index+1] = g / 255.0; // (g / 127.5) - 1;
        index++;
        inputBytes[index+2] = b / 255.0; // (b / 127.5) - 1;
        index++;
      }
    }catch (e) {
      debugPrint("$e");
    }

    debugPrint("Result bytes length: ${inputBytes.length}");

    var input = inputBytes.reshape([1, imageSize, imageSize, 3]);
    var outputTensors = muzzleDetectionInterpreter.getOutputTensors();
    List<int> outputShape = outputTensors.first.shape;

    debugPrint("There are ${outputTensors.length} Output tensors");
    for(var tensor in outputTensors) {
      String name = tensor.name;
      var shape = tensor.shape;
      debugPrint("**Tensor name: $name, Tensor shape: $shape");
    }

    // var output = List.filled(classNum, 0.0).reshape([1, classNum]);

    int totalLength = 1;
    for(int dim in outputShape) {
      totalLength *= dim;
    }

    var output = List.filled(totalLength, 0.0).reshape(outputShape);

    // Track how long it took to do inference
    int startTime = new DateTime.now().millisecondsSinceEpoch;

    try {
      muzzleDetectionInterpreter.run(input, output);
    } catch (e) {
      debugPrint('Error loading or running model: ' + e.toString());
    }

    int endTime = new DateTime.now().millisecondsSinceEpoch;
    debugPrint("Inference took ${endTime - startTime} ms");


    debugPrint("Output: ${output}");
    var decodedOutput;
    try{
      decodedOutput = decodeYoloOutput(outputTensor: output, outputShape: outputShape, labels: <String>['muzzle']);
    }catch(e) {
      debugPrint("$e");
      debugPrint("Failed to decode results");
    }

    // double total = output[0].reduce((a, b) => a + b);
    // double total = 0.0;
    // for (int i = 0; i < output[0].length; i++) {
    //   total+=output[0][i];
    //   if (output[0][i] > highestProb) {
    //     highestProb = output[0][i];
    //     prediction = labels["${i.toString()}"]??"";
    //   }
    // }

    // debugPrint("predicted_class : $prediction, confidence : ${highestProb * 100 / total}");
    // return {"predicted_class" : prediction, "confidence" : highestProb * 100 / total };
    return decodedOutput;
  }

  static dynamic decodeYoloOutput({required List outputTensor, required List<int> outputShape, required List<String> labels }) {
    debugPrint("Decoding the output");
    List<Map<String , dynamic>> results = [];
    int colCount = outputShape[1];
    int rowCount = outputShape[2];
    int anchorCount = (outputShape[3] / (5 + labels.length)).toInt();
    debugPrint("Number of anchors: $anchorCount");
    List<double> anchorSize = [1.5, 5.5]; //Size of the anchor relative to the grid size [rel_height, rel_width]

    for(int rowIdx = 0; rowIdx < rowCount; rowIdx++) {
      for(int colIdx = 0; colIdx < colCount; colIdx++) {
        var rawBoxes = List.filled(outputShape.last, 0.0).reshape([anchorCount, (5 + labels.length)]);

        // List<List<double>> rawBoxes = outputTensor[0][rowIdx][colIdx].reshape([anchorCount, 5 + labels.length]);

        // populate the rawBoxes list with required data
        for(int anchorIdx = 0; anchorIdx < anchorCount; anchorIdx++) {
          int dataLength = 5 + labels.length;
          for(int dataIdx = 0; dataIdx < dataLength; dataIdx++) {
            rawBoxes[anchorIdx][dataIdx] = outputTensor[0][rowIdx][colIdx][dataIdx + anchorIdx * dataLength];
          }
        }

        // todo: Might delete this line of code afterwards.
        // was just a test
        // if(rawBoxes.length == anchorCount) {
        //   debugPrint("Found expected number of anchors");
        // }

        for(var rawBox in rawBoxes) {
          ///Note all the dimensions below are on the grid's scale
          double center_y_grid = sigmoid(rawBox[0]); //box center y-coordinate w.r.t the grid's top-left corner
          double center_x_grid = sigmoid(rawBox[1]); //box center x-coordinate w.r.t the grid's top-left corner
          double center_y_image = center_y_grid + rowIdx; //box center y-coordinate w.r.t the image's top-left corner
          double center_x_image = center_x_grid + colIdx; //box center x-coordinate w.r.t the image's top-left corner
          double box_height = Math.exp(rawBox[2]) * anchorSize[0];
          double box_width = Math.exp(rawBox[3]) * anchorSize[1];

          /// Converting dimensions from grid scale to image scale
          double height = box_height / rowCount;
          double width = box_width / colCount;
          double center_y = center_y_image / rowCount;
          double center_x = center_x_image /colCount;
          double topLeftY = center_y - (height / 2);
          double topLeftX = center_x - (width / 2);

          /// extract object score
          double objectScore = sigmoid(rawBox[4]);

          /// extract predicted class with highest probability
          int classProbOffset = 5;
          List<double> rawClassProbs = List.generate(labels.length, (i) => rawBox[i + classProbOffset]);
          //apply softmax activation to get the true on raw class probabilities
          //to obtain the true class probabilities.
          List<double> classProbs = softmax(rawClassProbs);
          String predictedClass = labels[indexOfMax(classProbs)];

          if(objectScore > 0.3) {
            results.add(
                {"rect": {
                  'x': topLeftX, 'y' : topLeftY,
                  'w' : width, 'h' : height,
                  'predicted_class' : predictedClass, 'confidence' : objectScore }});
          }

        }
      }
    }

    debugPrint("** Extracted ${results.length} muzzles **");

    return results;
  }

  static Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  static List<double> softmax(List<double> input) {
    double sumExp = 0.0;
    List<double> result = List<double>.filled(input.length, 0);

    // Calculate the sum of exponentials
    for (int i = 0; i < input.length; i++) {
      sumExp += Math.exp(input[i]);
    }

    // Calculate softmax values
    for (int i = 0; i < input.length; i++) {
      result[i] = Math.exp(input[i]) / sumExp;
    }

    return result;
  }

  static double sigmoid(double x) {
    return 1 / (1 + Math.exp(-x));
  }

  static int indexOfMax(List<double> numbers) {
    if (numbers.isEmpty) {
      throw ArgumentError('List is empty');
    }

    int maxIndex = 0;
    double maxValue = numbers[0];

    for (int i = 1; i < numbers.length; i++) {
      if (numbers[i] > maxValue) {
        maxIndex = i;
        maxValue = numbers[i];
      }
    }

    return maxIndex;
  }

}




