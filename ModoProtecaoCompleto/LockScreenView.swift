import SwiftUI

struct LockScreenView: View {
    @Binding var isUnlocked: Bool
    @State private var enteredPasscode: String = ""
    private let fakePasscode = "1234"

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text(currentTime())
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(.white)
                    .padding(.top, 60)

                Text(currentDate())
                    .font(.title2)
                    .foregroundColor(.gray)

                Spacer()

                VStack(spacing: 12) {
                    SecureField("Digite a senha", text: $enteredPasscode)
                        .padding()
                        .keyboardType(.numberPad)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .foregroundColor(.white)

                    Button("Desbloquear") {
                        if enteredPasscode == fakePasscode {
                            isUnlocked = true
                        } else {
                            enteredPasscode = ""
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
        }
    }

    private func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    private func currentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: Date()).capitalized
    }
}
