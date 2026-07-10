import Foundation
import SwiftUI

public struct RegionGlobeConfiguration {
    public var showsRegionPicker: Bool
    public var autoRotates: Bool
    public var allowsPan: Bool
    public var globeFrame: CGSize
    public var carouselTopPadding: CGFloat
    public var globeCarouselSpacing: CGFloat
    public var carouselBottomPadding: CGFloat?
    public var idleRingScale: CGFloat
    public var selectedRingScale: CGFloat
    public var ringScale: CGFloat?
    public var glowRingOpacityScale: Double
    public var idleZoom: Float
    public var selectedZoom: Float
    public var coordinateFocusZoom: Float
    public var rotationSpeed: Float
    public var animationDuration: TimeInterval
    public var style: RegionGlobeStyle

    public init(
        showsRegionPicker: Bool = true,
        autoRotates: Bool = true,
        allowsPan: Bool = true,
        globeFrame: CGSize = CGSize(width: 520, height: 558),
        carouselTopPadding: CGFloat = 28,
        globeCarouselSpacing: CGFloat = 24,
        carouselBottomPadding: CGFloat? = nil,
        idleRingScale: CGFloat = 0.55,
        selectedRingScale: CGFloat = 0.67,
        ringScale: CGFloat? = nil,
        glowRingOpacityScale: Double = 1,
        idleZoom: Float = 1.12,
        selectedZoom: Float = 1.38,
        coordinateFocusZoom: Float = 1.36,
        rotationSpeed: Float = 0.065,
        animationDuration: TimeInterval = 0.82,
        style: RegionGlobeStyle = .darkOrange
    ) {
        self.showsRegionPicker = showsRegionPicker
        self.autoRotates = autoRotates
        self.allowsPan = allowsPan
        self.globeFrame = globeFrame
        self.carouselTopPadding = carouselTopPadding
        self.globeCarouselSpacing = globeCarouselSpacing
        self.carouselBottomPadding = carouselBottomPadding
        self.idleRingScale = idleRingScale
        self.selectedRingScale = selectedRingScale
        self.ringScale = ringScale
        self.glowRingOpacityScale = glowRingOpacityScale
        self.idleZoom = idleZoom
        self.selectedZoom = selectedZoom
        self.coordinateFocusZoom = coordinateFocusZoom
        self.rotationSpeed = rotationSpeed
        self.animationDuration = animationDuration
        self.style = style
    }
}
