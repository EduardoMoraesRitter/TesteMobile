import Foundation
import CoreLocation

class VideoAnalyzer {
    func analyze(videoURL: String,
                 user: String,
                 device: String,
                 latitude: Double,
                 longitude: Double,
                 completion: @escaping (Bool) -> Void) {

        guard let url = URL(string: "https://ai-video-825227664999.us-central1.run.app/analyze-video") else {
            print("❌ URL inválida para análise")
            completion(false)
            return
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())

        let payload: [String: Any] = [
            "video_url": videoURL,
            "user": user,
            "device": device,
            "timestamp": timestamp,
            "latitude": latitude,
            "longitude": longitude
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erro ao chamar API de análise:", error.localizedDescription)
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("🧠 Análise enviada. Status:", httpResponse.statusCode)
                completion(httpResponse.statusCode == 200)
            } else {
                completion(false)
            }
        }.resume()
    }
}
