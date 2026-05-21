import Flutter
import UIKit
import MediaPipeTasksVision

/**
 * Flutter plugin wrapping MediaPipe FaceLandmarker for iOS.
 * Drop-in replacement for ML Kit face detection — works consistently
 * across all iOS devices with Metal GPU acceleration (CPU fallback).
 *
 * Method channel: `com.globalspace.youvai/mediapipe_face`
 */
class MediaPipeFaceDetectorPlugin: NSObject, FlutterPlugin {

    private var channel: FlutterMethodChannel?
    private var faceLandmarker: FaceLandmarker?
    private let queue = DispatchQueue(label: "com.globalspace.youvai.mediapipe", qos: .userInitiated)

    // MediaPipe 478-landmark indices → ML Kit 10-point format
    private static let LANDMARK_MAP: [Int] = [
        1,   // noseBase
        159, // leftEye
        386, // rightEye
        234, // leftEar
        454, // rightEar
        61,  // leftMouth
        291, // rightMouth
        116, // leftCheek
        345, // rightCheek
        17   // bottomMouth
    ]

    private static let modelFileName = "face_landmarker.task"
    private static let modelURL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task"

    // ── Plugin registration ──────────────────────────────────────
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.globalspace.youvai/mediapipe_face",
            binaryMessenger: registrar.messenger()
        )
        let instance = MediaPipeFaceDetectorPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(result: result)
        case "processFrame":
            handleProcessFrame(call: call, result: result)
        case "processImageFile":
            handleProcessImageFile(call: call, result: result)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ── Initialize ───────────────────────────────────────────────
    private func handleInitialize(result: @escaping FlutterResult) {
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let modelPath = try self.ensureModelDownloaded()

                let landmarker: FaceLandmarker
                do {
                    landmarker = try self.createLandmarker(modelPath: modelPath, useGPU: true)
                } catch {
                    landmarker = try self.createLandmarker(modelPath: modelPath, useGPU: false)
                }

                self.faceLandmarker = landmarker
                DispatchQueue.main.async { result(true) }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "INIT_FAILED",
                        message: "MediaPipe init: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
    }

    private func ensureModelDownloaded() throws -> String {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelFile = documentsDir.appendingPathComponent(Self.modelFileName)

        if FileManager.default.fileExists(atPath: modelFile.path),
           let attrs = try? FileManager.default.attributesOfItem(atPath: modelFile.path),
           let size = attrs[.size] as? Int, size > 1_000_000 {
            return modelFile.path
        }

        // Synchronous download (already on background queue)
        guard let url = URL(string: Self.modelURL) else {
            throw NSError(domain: "MediaPipe", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid model URL"
            ])
        }

        let data = try Data(contentsOf: url)
        guard data.count > 1_000_000 else {
            throw NSError(domain: "MediaPipe", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Downloaded model too small"
            ])
        }

        try data.write(to: modelFile, options: .atomic)
        return modelFile.path
    }

    private func createLandmarker(modelPath: String, useGPU: Bool) throws -> FaceLandmarker {
        let baseOptions = BaseOptions()
        baseOptions.modelAssetPath = modelPath
        if useGPU {
            baseOptions.delegate = .GPU
        } else {
            baseOptions.delegate = .CPU
        }

        let options = FaceLandmarkerOptions()
        options.baseOptions = baseOptions
        options.runningMode = .image
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.5
        options.minFacePresenceConfidence = 0.5

        return try FaceLandmarker(options: options)
    }

    // ── Process camera frame ─────────────────────────────────────
    private func handleProcessFrame(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let bytes = args["bytes"] as? FlutterStandardTypedData,
              let width = args["width"] as? Int,
              let height = args["height"] as? Int else {
            result(["hasFace": false])
            return
        }

        let rotation = args["rotation"] as? Int ?? 0
        let format = args["format"] as? String ?? "bgra8888"

        guard let landmarker = faceLandmarker else {
            result(["hasFace": false])
            return
        }

        queue.async { [weak self] in
            guard let self = self else { return }

            guard let bitmap = self.createUIImage(
                from: bytes.data, width: width, height: height, format: format
            ) else {
                DispatchQueue.main.async { result(["hasFace": false]) }
                return
            }

            let rotated = rotation != 0 ? self.rotateImage(bitmap, degrees: CGFloat(rotation)) : bitmap
            let processed = self.maybeDownscale(rotated, maxDim: 640)

            let resultMap = self.detectFace(landmarker: landmarker, image: processed)
            DispatchQueue.main.async { result(resultMap) }
        }
    }

    // ── Process image file ───────────────────────────────────────
    private func handleProcessImageFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
            result(["hasFace": false])
            return
        }

        guard let landmarker = faceLandmarker else {
            result(["hasFace": false])
            return
        }

        queue.async { [weak self] in
            guard let self = self,
                  let image = UIImage(contentsOfFile: imagePath) else {
                DispatchQueue.main.async { result(["hasFace": false]) }
                return
            }

            let processed = self.maybeDownscale(image, maxDim: 1024)
            let resultMap = self.detectFace(landmarker: landmarker, image: processed)
            DispatchQueue.main.async { result(resultMap) }
        }
    }

    // ── Core detection ───────────────────────────────────────────
    private func detectFace(landmarker: FaceLandmarker, image: UIImage) -> [String: Any?] {
        guard let mpImage = try? MPImage(uiImage: image) else {
            return ["hasFace": false]
        }

        guard let faceResult = try? landmarker.detect(image: mpImage),
              let landmarks = faceResult.faceLandmarks.first,
              !landmarks.isEmpty else {
            return ["hasFace": false]
        }

        let imgW = Float(image.size.width * image.scale)
        let imgH = Float(image.size.height * image.scale)

        // Map 478 → 10 ML Kit format (pixel coords)
        var mapped: [[Double]] = []
        for mpIdx in Self.LANDMARK_MAP {
            if mpIdx < landmarks.count {
                let lm = landmarks[mpIdx]
                mapped.append([
                    Double(lm.x * imgW),
                    Double(lm.y * imgH)
                ])
            } else {
                mapped.append([Double.nan, Double.nan])
            }
        }

        // Bounding box
        var minX: Float = .greatestFiniteMagnitude
        var minY: Float = .greatestFiniteMagnitude
        var maxX: Float = -.greatestFiniteMagnitude
        var maxY: Float = -.greatestFiniteMagnitude
        for lm in landmarks {
            let px = lm.x * imgW; let py = lm.y * imgH
            if px < minX { minX = px }; if py < minY { minY = py }
            if px > maxX { maxX = px }; if py > maxY { maxY = py }
        }

        // Euler angles
        let euler = computeEulerAngles(landmarks: landmarks)

        return [
            "hasFace": true,
            "landmarks": mapped,
            "eulerAngleX": euler.0, // pitch
            "eulerAngleY": euler.1, // yaw
            "eulerAngleZ": euler.2, // roll
            "bbLeft": Double(minX),
            "bbTop": Double(minY),
            "bbWidth": Double(maxX - minX),
            "bbHeight": Double(maxY - minY),
            "imageWidth": Int(imgW),
            "imageHeight": Int(imgH)
        ]
    }

    // ── Euler angles from landmarks ──────────────────────────────
    private func computeEulerAngles(
        landmarks: [NormalizedLandmark]
    ) -> (Double, Double, Double) {
        guard landmarks.count >= 478 else { return (0.0, 0.0, 0.0) }

        // Pitch
        let forehead = landmarks[10]
        let noseTip  = landmarks[1]
        let chin     = landmarks[152]
        let foreheadToNose = abs(noseTip.y - forehead.y)
        let noseToChin = abs(chin.y - noseTip.y)
        let pitch: Double = noseToChin > 0.001
            ? min(max(atan(Double(foreheadToNose / noseToChin)) * 180.0 / .pi, 0), 90)
            : 0.0

        // Yaw
        let leftEar  = landmarks[234]
        let rightEar = landmarks[454]
        let faceWidth = abs(rightEar.x - leftEar.x)
        let yaw: Double = faceWidth > 0.001 ? {
            let centerX = (leftEar.x + rightEar.x) / 2.0
            let offset = noseTip.x - centerX
            return min(max(Double(offset / faceWidth) * 90.0, -45), 45)
        }() : 0.0

        // Roll
        let leftEye  = landmarks[159]
        let rightEye = landmarks[386]
        let eyeDx = Double(rightEye.x - leftEye.x)
        let eyeDy = Double(rightEye.y - leftEye.y)
        let roll: Double = abs(eyeDx) > 0.001
            ? min(max(atan2(eyeDy, eyeDx) * 180.0 / .pi, -45), 45)
            : 0.0

        return (pitch, yaw, roll)
    }

    // ── Image utilities ──────────────────────────────────────────
    private func createUIImage(from data: Data, width: Int, height: Int, format: String) -> UIImage? {
        if format == "bgra8888" {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(
                data: UnsafeMutableRawPointer(mutating: (data as NSData).bytes),
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ), let cgImage = context.makeImage() else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }

        // NV21/YUV fallback: should not happen on iOS (BGRA is default)
        return nil
    }

    private func rotateImage(_ image: UIImage, degrees: CGFloat) -> UIImage {
        let radians = degrees * .pi / 180.0
        var newSize = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians)).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        image.draw(in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        let rotated = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotated ?? image
    }

    private func maybeDownscale(_ image: UIImage, maxDim: Int) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > CGFloat(maxDim) else { return image }
        let scale = CGFloat(maxDim) / longest
        let newSize = CGSize(
            width: floor(image.size.width * scale),
            height: floor(image.size.height * scale)
        )
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized ?? image
    }

    // ── Dispose ──────────────────────────────────────────────────
    private func handleDispose(result: @escaping FlutterResult) {
        faceLandmarker = nil
        result(true)
    }
}
