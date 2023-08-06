import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:image/image.dart' as img;
import 'dart:math';

const int imageSize = 224;
const int classNum = 2;
const Map<String, String> labels = {
  "0" :"healthy",
  "1" :"unhealthy"
};

class MLService {
  static late Interpreter interpreter;
  static late Interpreter letterInterpreter;
  static InterpreterOptions interpreterOptions = InterpreterOptions()..threads = 2;

  MLService();

  static Future<void> initialize() async {
    try {
      interpreter = await Interpreter.fromAsset("models/disease_classifier/disease_classifier.tflite", options: interpreterOptions);
      debugPrint("Successfully initialized Model");
    }catch(e) {
      debugPrint("$e");
      debugPrint("Initializing model");
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
    return getPrediction(imgAsList);
  }


  Future<Map<String, dynamic>> getPrediction(Uint8List imgAsList) async {
    // final List<dynamic> resultBytes = List.filled(mnistSize * mnistSize, 0.0);
    final List<dynamic> resultBytes = List.filled(imageSize * imageSize * 3, 0.0);
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

    var input = resultBytes.reshape([1, imageSize, imageSize, 3]);
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
        prediction = labels["${i.toString()}"]??"";
      }
    }
    debugPrint("predicted_class : $prediction, confidence : ${highestProb * 100 / total}");
    return {"predicted_class" : prediction, "confidence" : highestProb * 100 / total };
  }

}
