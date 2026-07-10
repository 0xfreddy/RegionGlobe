import RegionGlobe
import SwiftUI
import UIKit

@main
struct RegionGlobeDemoApp: App {
    var body: some Scene {
        WindowGroup {
            DemoControlSurface()
        }
    }
}

private struct DemoControlSurface: View {
    @State private var selectedRegionIDs: Set<String> = ["us"]
    @State private var focusedRegionID = "us"
    @State private var focusRequest = 0
    @State private var autoRotates = true
    @State private var showsRegionPicker = true
    @State private var allowsPan = true
    @State private var idleZoom = 1.12
    @State private var selectedZoom = 1.38
    @State private var rotationSpeed = 0.065
    @State private var ringScale = 0.62
    @State private var roughness = 0.92
    @State private var isMetallic = false
    @State private var textureMode = DemoTextureMode.none
    @State private var backgroundColor = Color(red: 0.006, green: 0.007, blue: 0.008)
    @State private var globeColor = Color(red: 0.008, green: 0.009, blue: 0.011)
    @State private var neutralCountryColor = Color.white.opacity(0.88)
    @State private var selectedCountryColor = Color(red: 0.984, green: 0.392, blue: 0.082)
    @State private var chipBorderColor = Color.white.opacity(0.22)
    @State private var ringColor = Color.white
    @State private var glowColor = Color.white
    @State private var shadowColor = Color.black

    private let regions = [RegionGlobeRegion].defaultWorldRegions

    var body: some View {
        ZStack {
            style.background.ignoresSafeArea()

            VStack(spacing: 0) {
                RegionGlobe(
                    regions: regions,
                    selectedRegionIDs: $selectedRegionIDs,
                    focusedRegionID: $focusedRegionID,
                    focusRequest: $focusRequest,
                    configuration: configuration
                )
                .frame(maxWidth: .infinity)
                .frame(height: 520)

                controls
                    .background(.thinMaterial)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var configuration: RegionGlobeConfiguration {
        RegionGlobeConfiguration(
            showsRegionPicker: showsRegionPicker,
            autoRotates: autoRotates,
            allowsPan: allowsPan,
            globeFrame: CGSize(width: 390, height: 430),
            carouselTopPadding: 10,
            globeCarouselSpacing: 8,
            ringScale: ringScale,
            idleZoom: Float(idleZoom),
            selectedZoom: Float(selectedZoom),
            rotationSpeed: Float(rotationSpeed),
            style: style
        )
    }

    private var style: RegionGlobeStyle {
        RegionGlobeStyle(
            background: backgroundColor,
            foreground: Color(red: 0.94, green: 0.93, blue: 0.89),
            muted: Color(red: 0.62, green: 0.63, blue: 0.61),
            chipFill: Color.white.opacity(0.07),
            chipStroke: chipBorderColor,
            selected: selectedCountryColor,
            selectedForeground: .white,
            glow: glowColor,
            ring: ringColor,
            shadow: shadowColor,
            globeMaterial: UIColor(globeColor),
            globeTexture: textureMode.texture,
            globeRoughness: Float(roughness),
            globeIsMetallic: isMetallic,
            neutralDot: UIColor(neutralCountryColor),
            selectedDot: UIColor(selectedCountryColor)
        )
    }

    private var controls: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 14) {
                Text("RegionGlobe Demo")
                    .font(.headline)

                Toggle("Auto-rotate", isOn: $autoRotates)
                Toggle("Show region picker", isOn: $showsRegionPicker)
                Toggle("Allow pan", isOn: $allowsPan)
                Toggle("Metallic globe", isOn: $isMetallic)

                Picker("Texture", selection: $textureMode) {
                    ForEach(DemoTextureMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                colorControls

                controlSlider("Idle zoom", value: $idleZoom, range: 0.9...1.4)
                controlSlider("Selected zoom", value: $selectedZoom, range: 1.0...1.7)
                controlSlider("Ring scale", value: $ringScale, range: 0.35...0.85)
                controlSlider("Rotation speed", value: $rotationSpeed, range: 0.0...0.16)
                controlSlider("Globe roughness", value: $roughness, range: 0.08...1.0)

                Text("Focus")
                    .font(.subheadline.weight(.semibold))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(regions) { region in
                        Button(region.displayTitle) {
                            focusedRegionID = region.id
                            focusRequest += 1
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(focusedRegionID == region.id ? style.selected : .secondary)
                    }
                }
            }
            .font(.subheadline)
            .padding(16)
        }
        .frame(maxHeight: 300)
    }

    private var colorControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.subheadline.weight(.semibold))

            ColorPicker("Background", selection: $backgroundColor, supportsOpacity: true)
            ColorPicker("Globe fill", selection: $globeColor, supportsOpacity: true)
            ColorPicker("Neutral continents", selection: $neutralCountryColor, supportsOpacity: true)
            ColorPicker("Selected continents", selection: $selectedCountryColor, supportsOpacity: true)
            ColorPicker("Picker border", selection: $chipBorderColor, supportsOpacity: true)
            ColorPicker("Glow", selection: $glowColor, supportsOpacity: true)
            ColorPicker("Ring border", selection: $ringColor, supportsOpacity: true)
            ColorPicker("Shadow", selection: $shadowColor, supportsOpacity: true)
        }
    }

    private func controlSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}

private enum DemoTextureMode: String, CaseIterable, Identifiable {
    case none
    case grid
    case bands

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: "None"
        case .grid: "Grid"
        case .bands: "Bands"
        }
    }

    var texture: RegionGlobeTexture? {
        switch self {
        case .none:
            nil
        case .grid:
            .image(Self.gridTexture, name: "demo-grid")
        case .bands:
            .image(Self.bandsTexture, name: "demo-bands")
        }
    }

    private static let gridTexture: UIImage = textureImage { context, size in
        UIColor(red: 0.02, green: 0.03, blue: 0.04, alpha: 1).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        UIColor(white: 1, alpha: 0.16).setStroke()
        context.setLineWidth(2)
        for step in stride(from: 0, through: Int(size.width), by: 32) {
            context.move(to: CGPoint(x: step, y: 0))
            context.addLine(to: CGPoint(x: step, y: Int(size.height)))
            context.move(to: CGPoint(x: 0, y: step))
            context.addLine(to: CGPoint(x: Int(size.width), y: step))
        }
        context.strokePath()
    }

    private static let bandsTexture: UIImage = textureImage { context, size in
        UIColor(red: 0.01, green: 0.015, blue: 0.018, alpha: 1).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        for index in 0..<8 {
            let alpha = index.isMultiple(of: 2) ? 0.20 : 0.08
            UIColor(red: 1.0, green: 0.55, blue: 0.20, alpha: alpha).setFill()
            context.fill(CGRect(x: 0, y: CGFloat(index) * size.height / 8, width: size.width, height: size.height / 8))
        }
    }

    private static func textureImage(draw: (CGContext, CGSize) -> Void) -> UIImage {
        let size = CGSize(width: 256, height: 256)
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            draw(rendererContext.cgContext, size)
        }
    }
}
