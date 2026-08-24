import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  late Interpreter _interpreter;
  late IsolateInterpreter _isolateInterpreter;
  bool _isModelLoaded = false;

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      // Use XNNPACKDelegate if available or just default options
      // NnApiDelegate might not be available in this version directly or requires specific setup
      // options.addDelegate(XNNPackDelegate());

      _interpreter = await Interpreter.fromAsset(
        'assets/mobile_face_net.tflite',
        options: options,
      );
      _isolateInterpreter = await IsolateInterpreter.create(
        address: _interpreter.address,
      );
      _isModelLoaded = true;
    } catch (e) {
      debugPrint('Error loading model: $e');
      _isModelLoaded = false;
    }
  }

  Future<List<double>> generateEmbedding(String imagePath) async {
    if (!_isModelLoaded) {
      await loadModel();
    }

    if (!_isModelLoaded) {
      throw Exception('Model not loaded');
    }

    // 1. Read image
    final imageData = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(imageData);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // 2. Preprocess
    // The model typically expects 112x112 input
    // We assume the face is already centered/cropped or we resize the whole image
    // Ideally, we should crop the face using ML Kit logs if available, but for now we'll resize.
    // Liveness check screen seems to capture the whole screen or camera preview.
    // Better to just resize to 112x112 for now as a starting point.

    final resizedImage = img.copyResize(image, width: 112, height: 112);

    // Normalize to [-1, 1] usually or [0, 1]. MobileFaceNet often uses (pixel - 128) / 128
    // Shape: [1, 112, 112, 3]
    var input = List.generate(
      1,
      (i) => List.generate(
        112,
        (y) => List.generate(112, (x) {
          final pixel = resizedImage.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          return [(r - 128) / 128, (g - 128) / 128, (b - 128) / 128];
        }),
      ),
    );

    // Flatten logic if needed by the interpreter, but usually it takes the shape [1, 112, 112, 3]

    // Output shape: [1, 192] for MobileFaceNet
    var output = List.filled(1 * 192, 0.0).reshape([1, 192]);

    // Run inference
    await _isolateInterpreter.run(input, output);

    // Return the embedding
    return List<double>.from(output[0]);
  }
}
