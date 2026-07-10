import SwiftUI

#if os(iOS)
import UIKit
#endif

public struct RegionGlobeStyle: @unchecked Sendable {
    public var background: Color
    public var foreground: Color
    public var muted: Color
    public var chipFill: Color
    public var chipStroke: Color
    public var selected: Color
    public var selectedForeground: Color
    public var glow: Color
    public var ring: Color
    public var shadow: Color

    #if os(iOS)
    public var globeMaterial: UIColor
    public var globeTexture: RegionGlobeTexture?
    public var globeRoughness: Float
    public var globeIsMetallic: Bool
    public var neutralDot: UIColor
    public var selectedDot: UIColor
    #endif

    public init(
        background: Color,
        foreground: Color,
        muted: Color,
        chipFill: Color,
        chipStroke: Color,
        selected: Color,
        selectedForeground: Color = .white,
        glow: Color,
        ring: Color? = nil,
        shadow: Color = .black,
        globeMaterial: PlatformColor = PlatformColor(red: 0.008, green: 0.009, blue: 0.011, alpha: 1),
        globeTexture: RegionGlobeTexture? = nil,
        globeRoughness: Float = 0.92,
        globeIsMetallic: Bool = false,
        neutralDot: PlatformColor = PlatformColor(white: 1, alpha: 0.88),
        selectedDot: PlatformColor = PlatformColor(red: 0.984, green: 0.392, blue: 0.082, alpha: 1)
    ) {
        self.background = background
        self.foreground = foreground
        self.muted = muted
        self.chipFill = chipFill
        self.chipStroke = chipStroke
        self.selected = selected
        self.selectedForeground = selectedForeground
        self.glow = glow
        self.ring = ring ?? glow
        self.shadow = shadow
        #if os(iOS)
        self.globeMaterial = globeMaterial
        self.globeTexture = globeTexture
        self.globeRoughness = globeRoughness
        self.globeIsMetallic = globeIsMetallic
        self.neutralDot = neutralDot
        self.selectedDot = selectedDot
        #endif
    }

    public static let darkOrange = RegionGlobeStyle(
        background: Color(red: 0.006, green: 0.007, blue: 0.008),
        foreground: Color(red: 0.94, green: 0.93, blue: 0.89),
        muted: Color(red: 0.62, green: 0.63, blue: 0.61),
        chipFill: Color.white.opacity(0.07),
        chipStroke: Color.white.opacity(0.22),
        selected: Color(red: 0.984, green: 0.392, blue: 0.082),
        glow: Color.white
    )

    public static let lightTeal = RegionGlobeStyle(
        background: Color(red: 0.958, green: 0.980, blue: 0.975),
        foreground: Color(red: 0.045, green: 0.075, blue: 0.080),
        muted: Color(red: 0.360, green: 0.430, blue: 0.430),
        chipFill: Color.white.opacity(0.84),
        chipStroke: Color(red: 0.0, green: 0.38, blue: 0.36).opacity(0.24),
        selected: Color(red: 0.0, green: 0.55, blue: 0.50),
        glow: Color(red: 0.0, green: 0.70, blue: 0.64),
        globeMaterial: PlatformColor(red: 0.018, green: 0.035, blue: 0.040, alpha: 1),
        neutralDot: PlatformColor(white: 1, alpha: 0.90),
        selectedDot: PlatformColor(red: 0.0, green: 0.76, blue: 0.68, alpha: 1)
    )
}

#if os(iOS)
public typealias PlatformColor = UIColor
public typealias PlatformImage = UIImage
#else
public struct PlatformColor: Sendable {
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {}
    public init(white: CGFloat, alpha: CGFloat) {}
}
public struct PlatformImage: Sendable {}
#endif
