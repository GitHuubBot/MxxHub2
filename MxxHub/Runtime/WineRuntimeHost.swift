import SwiftUI

struct WineRuntimeHost: UIViewControllerRepresentable {
    let executablePath: String

    func makeUIViewController(context: Context) -> MxxWineRuntimeViewController {
        MxxWineRuntimeViewController(executablePath: executablePath)
    }

    func updateUIViewController(_ uiViewController: MxxWineRuntimeViewController, context: Context) {}
}

struct WineRuntimeScreen: View {
    @Environment(\.dismiss) private var dismiss
    let executablePath: String

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WineRuntimeHost(executablePath: executablePath)
                .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Label("Back to MxxHub", systemImage: "xmark.circle.fill")
                    .font(.callout.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding()
        }
        .background(Color.black)
    }
}
