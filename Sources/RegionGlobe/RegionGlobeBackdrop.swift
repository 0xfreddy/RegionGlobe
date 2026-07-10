import SwiftUI

struct RegionGlobeBackdrop: View {
    let style: RegionGlobeStyle
    var ringOpacityScale = 1.0

    var body: some View {
        ZStack {
            Ellipse()
                .fill(style.shadow.opacity(0.52))
                .frame(width: 380, height: 96)
                .blur(radius: 30)
                .offset(y: 188)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            style.glow.opacity(0.045),
                            style.glow.opacity(0.018),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.5, y: 0.42),
                        startRadius: 118,
                        endRadius: 266
                    )
                )
                .blur(radius: 10)
                .scaleEffect(x: 1.03, y: 1.01)

            Circle()
                .stroke(style.ring.opacity(0.44 * ringOpacityScale), lineWidth: 40)
                .blur(radius: 28)
                .scaleEffect(x: 0.985, y: 0.985)

            Circle()
                .stroke(style.ring.opacity(0.62 * ringOpacityScale), lineWidth: 13)
                .blur(radius: 7)
                .scaleEffect(x: 0.985, y: 0.985)

            Circle()
                .stroke(style.ring.opacity(0.95 * ringOpacityScale), lineWidth: 1.6)
                .blur(radius: 0.25)
                .scaleEffect(x: 0.985, y: 0.985)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.035),
                            Color.white.opacity(0.012),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 146,
                        endRadius: 224
                    )
                )
        }
        .compositingGroup()
    }
}
