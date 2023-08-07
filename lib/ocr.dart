import 'dart:io';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<String?> performTextRecognition(File imageFile) async {
  // Create an instance of InputImage from the image file.
  final inputImage = InputImage.fromFile(imageFile);

  // Create an instance of TextRecognizer to perform text recognition.
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    // Perform text recognition on the image.
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    // Extract the recognized text.
    String text = recognizedText.text;

    // for (TextBlock block in recognizedText.blocks) {
    //   final Rect rect = block.boundingBox;
    //   final List<Point<int>> cornerPoints = block.cornerPoints;
    //   final String text = block.text;
    //   final List<String> languages = block.recognizedLanguages;
    //
    //   for (TextLine line in block.lines) {
    //     // Same getters as TextBlock
    //     for (TextElement element in line.elements) {
    //       // Same getters as TextBlock
    //     }
    //   }
    // }

    // Close the textRecognizer to free up resources.
    textRecognizer.close();

    return text;
  } catch (e) {
    debugPrint('Error performing text recognition: $e');
    // Close the textRecognizer even if there is an error.
    textRecognizer.close();
    return null;
  }
}