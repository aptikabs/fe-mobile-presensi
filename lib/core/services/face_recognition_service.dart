import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
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

    final imageData = await File(imagePath).readAsBytes();
    final decodedImage = img.decodeImage(imageData);

    if (decodedImage == null) {
      throw Exception('Failed to decode image');
    }

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
    final faces = await faceDetector.processImage(
      InputImage.fromFilePath(imagePath),
    );
    await faceDetector.close();
    if (faces.length != 1) {
      throw Exception('Tepat satu wajah diperlukan untuk verifikasi.');
    }

    final image = img.bakeOrientation(decodedImage);
    final face = faces.single.boundingBox;
    final left = face.left.round().clamp(0, image.width - 1);
    final top = face.top.round().clamp(0, image.height - 1);
    final right = face.right.round().clamp(left + 1, image.width);
    final bottom = face.bottom.round().clamp(top + 1, image.height);
    final croppedFace = img.copyCrop(
      image,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );

    final inputShape = _interpreter.getInputTensor(0).shape;
    if (inputShape.length != 4 || inputShape[0] != 1 || inputShape[3] != 3) {
      throw Exception('Bentuk input model wajah tidak didukung.');
    }
    final inputHeight = inputShape[1];
    final inputWidth = inputShape[2];
    final resizedImage = img.copyResize(
      croppedFace,
      width: inputWidth,
      height: inputHeight,
    );
    final inputType = _interpreter.getInputTensor(0).type;
    final input = _buildInput(resizedImage, inputType);

    final outputShape = _interpreter.getOutputTensor(0).shape;
    final embeddingSize = outputShape.skip(1).fold<int>(1, (a, b) => a * b);
    if (embeddingSize <= 0) {
      throw Exception('Bentuk output model wajah tidak valid.');
    }
    final output = List.generate(
      outputShape[0],
      (_) => List<double>.filled(embeddingSize, 0),
    );
    await _isolateInterpreter.run(input, output);

    return _l2Normalize(List<double>.from(output.first));
  }

  List<List<List<List<num>>>> _buildInput(img.Image image, TensorType type) {
    final useBytes = type.toString().contains('uint8');
    return [
      List.generate(
        image.height,
        (y) => List.generate(image.width, (x) {
          final pixel = image.getPixel(x, y);
          if (useBytes) {
            return [pixel.r.round(), pixel.g.round(), pixel.b.round()];
          }
          return [
            (pixel.r - 128) / 128,
            (pixel.g - 128) / 128,
            (pixel.b - 128) / 128,
          ];
        }),
      ),
    ];
  }

  List<double> _l2Normalize(List<double> vector) {
    final magnitude = vector.fold<double>(
      0,
      (sum, value) => sum + value * value,
    );
    if (magnitude == 0) {
      throw Exception('Embedding wajah kosong.');
    }
    final norm = math.sqrt(magnitude);
    return vector.map((value) => value / norm).toList(growable: false);
  }

  double cosineSimilarity(List<double> first, List<double> second) {
    if (first.length != second.length || first.isEmpty) return 0;
    var dot = 0.0;
    var firstMagnitude = 0.0;
    var secondMagnitude = 0.0;
    for (var index = 0; index < first.length; index++) {
      dot += first[index] * second[index];
      firstMagnitude += first[index] * first[index];
      secondMagnitude += second[index] * second[index];
    }
    if (firstMagnitude == 0 || secondMagnitude == 0) return 0;
    return dot / (math.sqrt(firstMagnitude) * math.sqrt(secondMagnitude));
  }
}
