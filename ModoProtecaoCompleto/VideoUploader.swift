import Foundation

class VideoUploader {
    /// Faz upload do vídeo para uma Signed URL do GCP
    func upload(to signedURL: String, fileURL: URL, completion: @escaping (Bool) -> Void) {
        guard let uploadURL = URL(string: signedURL) else {
            print("❌ URL inválida")
            completion(false)
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("video/quicktime", forHTTPHeaderField: "Content-Type")

        print("📤 Iniciando upload para GCP...")

        let task = URLSession.shared.uploadTask(with: request, fromFile: fileURL) { data, response, error in
            if let error = error {
                print("❌ Erro no upload: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("📤 Status do upload: \(httpResponse.statusCode)")
                completion(httpResponse.statusCode == 200 || httpResponse.statusCode == 201)
            } else {
                print("❌ Resposta inválida")
                completion(false)
            }
        }

        task.resume()
    }
}
