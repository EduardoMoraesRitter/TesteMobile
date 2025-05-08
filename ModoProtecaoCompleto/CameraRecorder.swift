import Foundation
import AVFoundation
import UIKit

class CameraRecorder: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    private var movieOutput = AVCaptureMovieFileOutput()
    private var session: AVCaptureSession?
    private var completionHandler: ((URL?) -> Void)?

    // Flag para ativar/desativar a câmera traseira
    var isBackCameraEnabled: Bool = false

    func recordFrontCamera(duration: Int, completion: @escaping (URL?) -> Void) {
        record(isFront: true, duration: duration, completion: completion)
    }

    func recordBackCamera(duration: Int, completion: @escaping (URL?) -> Void) {
        guard isBackCameraEnabled else {
            print("🚫 Câmera traseira desativada por configuração")
            completion(nil)
            return
        }
        record(isFront: false, duration: duration, completion: completion)
    }

    private func record(isFront: Bool, duration: Int, completion: @escaping (URL?) -> Void) {
        session = AVCaptureSession()
        session?.beginConfiguration()

        // 📸 Vídeo input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: isFront ? .front : .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session?.canAddInput(videoInput) == true else {
            print("❌ Erro ao configurar a câmera \(isFront ? "frontal" : "traseira")")
            completion(nil)
            return
        }
        session?.addInput(videoInput)

        // 🎙️ Áudio input
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session?.canAddInput(audioInput) == true {
            session?.addInput(audioInput)
        } else {
            print("⚠️ Áudio não incluído")
        }

        movieOutput = AVCaptureMovieFileOutput()
        if session?.canAddOutput(movieOutput) == true {
            session?.addOutput(movieOutput)
        } else {
            print("❌ Não foi possível adicionar saída de vídeo")
            completion(nil)
            return
        }

        session?.commitConfiguration()
        session?.startRunning()

        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let position = isFront ? "front" : "back"
        let fileURL = tempDir.appendingPathComponent("video_\(position)_\(timestamp).mov")

        print("🎬 Gravando \(position) em: \(fileURL.lastPathComponent)")

        completionHandler = completion
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(duration)) {
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            self.session?.stopRunning()
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("❌ Erro ao finalizar gravação: \(error.localizedDescription)")
            completionHandler?(nil)
        } else {
            print("✅ Vídeo salvo: \(outputFileURL.lastPathComponent)")
            completionHandler?(outputFileURL)
        }
        completionHandler = nil
    }
}
