import Foundation
import UIKit
import CoreLocation

class Uploader: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    private var currentAddress: String = ""
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Falha ao obter localização: \(error.localizedDescription)")
    }

    func uploadVideo(fileURL: URL, userName: String, isFrontCamera: Bool, completion: @escaping (Bool, String) -> Void) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let cameraPosition = isFrontCamera ? "front" : "back"
        let filename = "\(userName)/\(timestamp)_\(cameraPosition).mov"
        print("📤 Iniciando upload para: \(filename)")

        // TODO: Explorar futuramente o envio de vídeo em tempo real
        // usando WebSocket, HTTP chunked ou outras estratégias de streaming,
        // para transmitir diretamente os dados da câmera frontal enquanto grava,
        // sem depender de salvar o .mov local e esperar a finalização.
        // Essa lógica pode substituir ou complementar o fluxo atual baseado em arquivos.

        // 1. Gerar Signed URL
        guard let url = URL(string: "https://generate-upload-url-825227664999.us-central1.run.app/generate-upload-url") else {
            print("❌ URL inválida para geração da Signed URL")
            completion(false, "")
            return
        }

        let requestBody = ["filename": filename]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let result = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                  let uploadURLString = result["upload_url"],
                  let publicURL = result["public_url"],
                  let uploadURL = URL(string: uploadURLString) else {
                print("❌ Erro ao gerar Signed URL")
                completion(false, "")
                return
            }

            // 2. Enviar o vídeo
            var uploadRequest = URLRequest(url: uploadURL)
            uploadRequest.httpMethod = "PUT"
            uploadRequest.addValue("video/quicktime", forHTTPHeaderField: "Content-Type")

            if let videoData = try? Data(contentsOf: fileURL) {
                URLSession.shared.uploadTask(with: uploadRequest, from: videoData) { _, res, err in
                    if let err = err {
                        print("❌ Erro no upload: \(err.localizedDescription)")
                        completion(false, "")
                        return
                    }
                    print("✅ Upload finalizado: \(publicURL)")
                    completion(true, publicURL)
                }.resume()
            } else {
                print("❌ Não foi possível ler o vídeo local")
                completion(false, "")
            }
        }.resume()
    }

    func analyzeVideos(frontURL: String, backURL: String, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "https://ai-video-825227664999.us-central1.run.app/analyze-video") else {
            print("❌ URL da análise inválida")
            completion(false, "Erro na URL da API")
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let device = UIDevice.current
        let latitude = currentLocation?.coordinate.latitude ?? 0.0
        let longitude = currentLocation?.coordinate.longitude ?? 0.0

        let payload: [String: Any] = [
            "front_url": frontURL,
            "back_url": backURL,
            "device_name": device.name,
            "device_model": device.model,
            "timestamp": timestamp,
            "address": currentAddress,
            "latitude": latitude,
            "longitude": longitude,
            "identifier": device.identifierForVendor?.uuidString ?? ""
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let isSafe = result["safe"] as? Bool,
                  let justification = result["justification"] as? String else {
                print("❌ Erro na resposta da análise")
                completion(false, "Erro ao analisar segurança")
                return
            }

            print("🧠 Resultado da IA:")
            print("- Seguro?: \(isSafe)")
            print("- Justificativa: \(justification)")
            print("- Áudio: \(result["audio_analysis"] ?? "")")
            print("- Visual: \(result["visual_analysis"] ?? "")")
            print("- Face detectada em: \(result["face_detected_at"] ?? "null")")

            completion(isSafe, justification)
        }.resume()
    }
}
