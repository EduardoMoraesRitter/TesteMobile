import Foundation
import CoreMotion

class MotionManager {
    private let motion = CMMotionManager()
    private let queue = OperationQueue()
    private var lastTriggerTime: Date?

    /// Callback que será chamado quando o movimento for detectado
    var onMovementDetected: (() -> Void)?

    // Sensibilidade
    private let threshold: Double = 2.8
    private let cooldown: TimeInterval = 3.0 // evita triggers seguidos

    func startMonitoring() {
        guard motion.isAccelerometerAvailable else {
            print("Acelerômetro não disponível")
            return
        }

        motion.accelerometerUpdateInterval = 0.1

        motion.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let self = self, let acc = data?.acceleration else { return }

            let totalAcceleration = abs(acc.x) + abs(acc.y) + abs(acc.z)

            if totalAcceleration > self.threshold {
                let now = Date()
                if let last = self.lastTriggerTime, now.timeIntervalSince(last) < self.cooldown {
                    // Evita múltiplos triggers seguidos
                    return
                }

                self.lastTriggerTime = now
                print("🚨 Movimento brusco detectado: \(totalAcceleration)")
                DispatchQueue.main.async {
                    self.onMovementDetected?()
                }
            }
        }

        print("📡 Monitoramento iniciado.")
    }

    func stopMonitoring() {
        motion.stopAccelerometerUpdates()
        print("🛑 Monitoramento parado.")
    }
}
