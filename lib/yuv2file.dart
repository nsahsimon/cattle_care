import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;

Future<File> convertYUVtoFile(CameraImage cameraImage) async{

  int width = cameraImage.width;
  int height = cameraImage.height;

  imglib.Image imgCamera = imglib.Image(width: width, height: height);
  imgColorBytes(imgCamera, cameraImage);

  return await rotateImageBy90Degrees(imgCamera);
}

void imgColorBytes(imglib.Image imgCamera, CameraImage cameraImage) {
  try {
    final int width = cameraImage.width;
    final int height = cameraImage.height;
    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    debugPrint("uvRowStride: " + uvRowStride.toString());
    debugPrint("uvPixelStride: " + uvPixelStride.toString());

    // imgLib -> Image package from https://pub.dartlang.org/packages/image
    for(int x=0; x < width; x++) {
    for(int y=0; y < height; y++) {
    final int uvIndex = uvPixelStride * (x/2).floor() + uvRowStride*(y/2).floor();
    final int index = y * width + x;

    final yp = cameraImage.planes[0].bytes[index];
    final up = cameraImage.planes[1].bytes[uvIndex];
    final vp = cameraImage.planes[2].bytes[uvIndex];
    // Calculate pixel color
    int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
    int g = (yp - up * 46549 / 131072 + 44 -vp * 93604 / 131072 + 91).round().clamp(0, 255);
    int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

    // img.data!.buffer.asUint8List()[index] = shift | (b << 16) | (g << 8) | r;
    Color color = Color.fromARGB(255, r, g, b);
    imgCamera.setPixel(x, y, imglib.ColorRgb8(r,g,b));
  }
  }

  } catch (e) {
    debugPrint(">>>>>>>>>>>> ERROR:" + e.toString());
  }
}


Future<File> rotateImageBy90Degrees(imglib.Image image) async {

  // Rotate the image by 90 degrees clockwise.
  imglib.Image rotatedImage = imglib.copyRotate(image, angle: 90);

  // Encode the rotated image to JPEG format.
  List<int> rotatedImageBytes = imglib.encodeJpg(rotatedImage);

  // Create a new File object to store the rotated image.
  File rotatedImageFile = File('${Directory.systemTemp.path}/rotated_image.jpg');

  // Write the rotated image bytes to the file.
  await rotatedImageFile.writeAsBytes(rotatedImageBytes);

  return rotatedImageFile;
}

