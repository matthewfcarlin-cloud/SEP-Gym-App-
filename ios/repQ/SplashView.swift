import SwiftUI

/// Brand splash shown over the app on cold launch, then faded out.
/// The generated Info.plist only supports a plain launch screen, so the logo is
/// presented here rather than in a LaunchScreen storyboard.
struct SplashView: View {
    private let holdDuration = 0.75
    private let fadeDuration = 0.45

    @State private var hasFaded = false
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .scaleEffect(hasFaded ? 1.06 : 1)
        }
        .opacity(hasFaded ? 0 : 1)
        .task {
            try? await Task.sleep(for: .seconds(holdDuration))
            withAnimation(.easeInOut(duration: fadeDuration)) { hasFaded = true }
            try? await Task.sleep(for: .seconds(fadeDuration))
            onFinish()
        }
    }
}
