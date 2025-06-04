import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DetectionResult {
  final String name;
  final double accuracy;

  DetectionResult({required this.name, required this.accuracy});
}

class ObjectDetectionService {
  static final ObjectDetectionService _instance = ObjectDetectionService._internal();
  factory ObjectDetectionService() => _instance;

  ObjectDetectionService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;
  final MethodChannel _platform = const MethodChannel('com.accountable/object_detection');

  Future<void> loadModel() async {
    if (Platform.isAndroid) {
      try {
        _interpreter = await Interpreter.fromAsset('assets/best_float16.tflite');
        // Assuming the model outputs 4 bbox + 8 classes = 12 features per box
        // So, there are 8 classes.
        _labels = [
          'HamCheeseSandwich',
          'MirindaOrange',
          'BirdyEspressoGreenCan',
          'BirdyRobustaRedCan',
          'M150',
          'NescafeEspressoRoastGreenCan',
          'YenYen',
          'Pepsi_410ml'
        ]; // Actual labels provided by the user
        print('TFLite model loaded successfully.');
      } catch (e) {
        print('Failed to load TFLite model: $e');
      }
    } else if (Platform.isIOS) {
      // Core ML model is loaded and run natively via platform channels.
      // NOTE: The Core ML implementation has not been tested yet.
      print('Core ML model will be handled natively.');
    }
  }

  Future<DetectionResult?> detectObjects(String imagePath) async {
    if (Platform.isAndroid) {
      if (_interpreter == null) {
        await loadModel();
        if (_interpreter == null) {
          print('Model not loaded for Android.');
          return null;
        }
      }
      return _runTFLiteInference(imagePath);
    } else if (Platform.isIOS) {
      return _runCoreMLInference(imagePath);
    }
    return null;
  }

  Future<DetectionResult?> _runTFLiteInference(String imagePath) async {
    try {
      final imageBytes = File(imagePath).readAsBytesSync();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        print('Failed to decode image for TFLite inference.');
        return null;
      }

      // Preprocess image: resize to model input size (e.g., 640x640 for YOLOv8)
      // Assuming YOLOv8 input size is 640x640, float32, normalized to [0, 1]
      final resizedImage = img.copyResize(originalImage, width: 640, height: 640);
      final imageInput = imageToByteListFloat32(resizedImage, 640, 640);

      // Prepare output tensor
      // The output shape depends on the YOLO model. For YOLOv8, it's typically
      // [1, num_boxes, 4 + num_classes] or [1, num_classes, num_boxes]
      // For simplicity, let's assume a direct output of [1, num_classes] for classification
      // or [1, 1, num_classes] for a single detected object's class probabilities.
      // This needs to be adjusted based on the actual model output.
      // For object detection, the output is usually bounding boxes and class probabilities.
      // Let's assume a simplified output for now: [1, 1, 5] where 5 is [x, y, w, h, class_prob]
      // Or, if it's just classification, [1, num_classes]
      // Given the user's description "name, category, accuracy", it sounds like a classification.
      // Let's assume the model outputs a single best class and its confidence.
      // Output shape: [1, 1, 5] where 5 is [x, y, w, h, class_id, confidence]
      // Or, if it's just classification, [1, num_classes]
      // For a YOLO-based model, the output is usually more complex.
      // Let's assume for now it's a single detection with class and confidence.
      // Output shape: [1, 6] where 6 is [x, y, w, h, class_id, confidence]
      // Or, if it's just classification, [1, num_classes]
      // For YOLOv8, the output is typically [1, 84, 8400] where 84 is (4 bbox + 80 classes) and 8400 is num_boxes
      // Or [1, num_boxes, 84]
      // For simplicity, let's assume the model directly outputs a class index and confidence.
      // This will need to be refined based on the actual model's output structure.

      // Placeholder for actual model output interpretation
      // Assuming a simple classification output for now: [1, num_classes]
      // where num_classes is the number of classes the model was trained on.
      // For YOLO, it's usually bounding boxes + class probabilities.
      // Let's assume the model returns a list of detections, each with a class ID and confidence.
      // Output shape: [1, 12, 8400]
      // 12 features per box: 4 (bbox) + 8 (class probabilities)
      var output = List.filled(1 * 12 * 8400, 0.0).reshape([1, 12, 8400]);
      _interpreter!.run(imageInput, output);

      // Post-processing for YOLOv8 output
      // The output tensor is typically [1, num_features, num_boxes]
      // where num_features = 4 (bbox) + num_classes
      // In this case, num_features = 12, so num_classes = 8.
      // The output is transposed compared to some common YOLO exports.
      // We need to iterate through each box and find the best class.

      double maxOverallConfidence = 0.0;
      String? detectedObjectName;

      // Iterate through each of the 8400 boxes
      for (int i = 0; i < 8400; i++) {
        // The 4 bounding box coordinates are output[0][0-3][i]
        // The 8 class probabilities are output[0][4-11][i]
        
        double currentMaxClassConfidence = 0.0;
        int currentDetectedClassIndex = -1;

        // Find the class with the highest probability for the current box
        for (int j = 0; j < _labels!.length; j++) { // Iterate through 8 classes
          final classConfidence = output[0][4 + j][i]; // Class probabilities start at index 4
          if (classConfidence > currentMaxClassConfidence) {
            currentMaxClassConfidence = classConfidence;
            currentDetectedClassIndex = j;
          }
        }

        // Combine objectness (if present, often implicitly in class scores for YOLOv8)
        // and class confidence. For simplicity, we'll just use the class confidence.
        if (currentMaxClassConfidence > maxOverallConfidence) {
          maxOverallConfidence = currentMaxClassConfidence;
          if (currentDetectedClassIndex != -1) {
            detectedObjectName = _labels![currentDetectedClassIndex];
          }
        }
      }

      if (detectedObjectName != null && maxOverallConfidence > 0.25) { // Confidence threshold
        print('Detected object (TFLite): $detectedObjectName with accuracy $maxOverallConfidence');
        return DetectionResult(name: detectedObjectName, accuracy: maxOverallConfidence);
      } else {
        print('No object detected or confidence too low (TFLite).');
        return null;
      }
    } catch (e) {
      print('Error running TFLite inference: $e');
      return null;
    }
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputWidth, int inputHeight) {
    var convertedBytes = Float32List(1 * inputWidth * inputHeight * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (int i = 0; i < inputHeight; i++) {
      for (int j = 0; j < inputWidth; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future<DetectionResult?> _runCoreMLInference(String imagePath) async {
    try {
      final Map<dynamic, dynamic>? result = await _platform.invokeMethod(
        'detectObjectCoreML',
        {'imagePath': imagePath},
      );

      if (result != null && result['name'] != null && result['accuracy'] != null) {
        final String name = result['name'];
        final double accuracy = result['accuracy'];
        print('Detected object (Core ML): $name with accuracy $accuracy');
        return DetectionResult(name: name, accuracy: accuracy);
      } else {
        print('No object detected or invalid result from Core ML.');
        return null;
      }
    } catch (e) {
      print('Error running Core ML inference via platform channel: $e');
      return null;
    }
  }

  String getCategoryForDetectedObject(String objectName) {
    switch (objectName) {
      case 'HamCheeseSandwich':
      case 'MirindaOrange':
      case 'BirdyEspressoGreenCan':
      case 'BirdyRobustaRedCan':
      case 'M150':
      case 'NescafeEspressoRoastGreenCan':
      case 'YenYen':
      case 'Pepsi_410ml':
        return 'food';
      default:
        return 'other';
    }
  }

  void dispose() {
    _interpreter?.close();
  }
}
