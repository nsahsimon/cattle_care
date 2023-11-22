import 'dart:io';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

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