import Flutter
import UIKit
import CoreML
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let objectDetectionChannel = FlutterMethodChannel(name: "com.accountable/object_detection",
                                                      binaryMessenger: controller.binaryMessenger)

    objectDetectionChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "detectObjectCoreML" {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Image path not provided", details: nil))
          return
        }
        self.detectObjectCoreML(imagePath: imagePath, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // NOTE: The Core ML implementation has not been tested yet.
  private func detectObjectCoreML(imagePath: String, result: @escaping FlutterResult) {
    guard let modelURL = Bundle.main.url(forResource: "best", withExtension: "mlpackage", subdirectory: "assets/best.mlpackage") else {
        result(FlutterError(code: "MODEL_NOT_FOUND", message: "Core ML model not found.", details: nil))
        return
    }

    do {
        let model = try MLModel(contentsOf: modelURL)
        let visionModel = try VNCoreMLModel(for: model)
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            if let error = error {
                result(FlutterError(code: "COREML_ERROR", message: "Core ML request failed: \(error.localizedDescription)", details: nil))
                return
            }

            guard let observations = request.results as? [VNClassificationObservation] else {
                result(FlutterError(code: "COREML_ERROR", message: "Unexpected result type from Core ML.", details: nil))
                return
            }

            // Assuming the model outputs a single classification with confidence
            if let bestObservation = observations.first {
                let detectedName = bestObservation.identifier
                let accuracy = Double(bestObservation.confidence)
                print("Detected object (Core ML): \(detectedName) with accuracy \(accuracy)")
                result(["name": detectedName, "accuracy": accuracy])
            } else {
                result(["name": "unknown", "accuracy": 0.0]) // No detection
            }
        }

        // Handle image input
        let imageUrl = URL(fileURLWithPath: imagePath)
        let handler = VNImageRequestHandler(url: imageUrl, options: [:])
        try handler.perform([request])

    } catch {
        result(FlutterError(code: "COREML_INIT_ERROR", message: "Failed to initialize Core ML: \(error.localizedDescription)", details: nil))
    }
  }
}
