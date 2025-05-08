import SwiftUI
import CoreMotion

struct ContentView: View {
    @StateObject private var cameraRecorder = CameraRecorder()
    @StateObject private var uploader = Uploader()

    @State private var logs: [String] = []
    @State private var isProcessing = false
    @State private var locked = false

    private let motionManager = CMMotionManager()
    private let motionThreshold = 2.0

    var body: some View {
        VStack(spacing: 20) {
            Text(locked ? "🔒 Proteção Ativada" : "🟢 Proteção Ativa")
                .font(.title2)
                .bold()
                .foregroundColor(locked ? .red : .green)

            ScrollView {
                ForEach(logs.indices, id: \.self) { i in
                    Text(logs[i])
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 14, design: .monospaced))
                        .padding(.horizontal)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            cameraRecorder.isBackCameraEnabled = false // 👈 Desativado
            startMotionDetection()
        }
    }

    func startMotionDetection() {
        logs.append("📡 Monitorando movimento...")
        motionManager.accelerometerUpdateInterval = 0.2

        motionManager.startAccelerometerUpdates(to: .main) { data, _ in
            guard let acc = data?.acceleration else { return }

            let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)

            // TODO: substituir esse cálculo simples de magnitude
            // por um modelo local Core ML que classifica padrões de movimento
            // como "queda", "corrida", "arrancada" e produzir uma classificação
            // ex: se mlModel.predict(acceleration: [x,y,z])
            
            // Rodar um modelo Core ML continuamente em background é difícil no iOS,
            // porque o sistema suspende o app em segundo plano após alguns segundos
            // se não houver uma tarefa ativa (como gravação ou música).
            // Para que funcione, o app teria que manter uma "background task"
            // ou estar usando modos especiais (ex: `audio`, `location`).

            if magnitude > motionThreshold && !isProcessing {
                logs.append("⚠️ Movimento brusco detectado: \(String(format: "%.2f", magnitude))")
                processSecurityFlow()
            }
        }
    }


    func processSecurityFlow() {
        logs.removeAll()
        isProcessing = true
        locked = false

        logs.append("🎥 Gravando câmera frontal com áudio...")
        let userName = UIDevice.current.name

        cameraRecorder.recordFrontCamera(duration: 4) { frontURL in
            guard let front = frontURL else {
                logs.append("❌ Erro ao gravar a câmera frontal.")
                isProcessing = false
                return
            }

            logs.append("✅ Vídeo frontal gravado: \(front.lastPathComponent)")
            logs.append("📤 Enviando vídeo frontal...")

            uploader.uploadVideo(fileURL: front, userName: userName, isFrontCamera: true) { success, frontPublicURL in
                if success {
                    logs.append("✅ Upload frontal OK")
                } else {
                    logs.append("❌ Upload frontal falhou")
                    isProcessing = false
                    return
                }

                logs.append("🧠 Enviando para análise de segurança...")

                uploader.analyzeVideos(frontURL: frontPublicURL, backURL: "") { isSafe, message in
                    logs.append("📊 Resultado da IA: \(message)")
                    if !isSafe {
                        logs.append("🔒 Dispositivo bloqueado (simulado)")
                        locked = true
                    } else {
                        logs.append("✅ Nenhum risco detectado")
                    }
                    isProcessing = false
                }
            }
        }
    }
}
