import SwiftUI

public struct RegionGlobe: View {
    private let regions: [RegionGlobeRegion]
    @Binding private var selectedRegionIDs: Set<String>
    @Binding private var focusedRegionID: String
    @Binding private var focusRequest: Int
    private let selectedCountryNames: Set<String>
    private let highlightedCountryNames: Set<String>
    private let focusedCoordinate: RegionGlobeCoordinate?
    private let configuration: RegionGlobeConfiguration

    public init(
        regions: [RegionGlobeRegion],
        selectedRegionIDs: Binding<Set<String>>,
        focusedRegionID: Binding<String>,
        focusRequest: Binding<Int>,
        selectedCountryNames: Set<String> = [],
        highlightedCountryNames: Set<String> = [],
        focusedCoordinate: RegionGlobeCoordinate? = nil,
        configuration: RegionGlobeConfiguration = .init()
    ) {
        self.regions = regions
        self._selectedRegionIDs = selectedRegionIDs
        self._focusedRegionID = focusedRegionID
        self._focusRequest = focusRequest
        self.selectedCountryNames = selectedCountryNames
        self.highlightedCountryNames = highlightedCountryNames
        self.focusedCoordinate = focusedCoordinate
        self.configuration = configuration
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .top) {
                VStack(spacing: configuration.globeCarouselSpacing) {
                    globeView(containerWidth: proxy.size.width)

                    if configuration.showsRegionPicker, configuration.carouselBottomPadding == nil {
                        regionCarousel
                            .frame(width: max(proxy.size.width - 36, 0))
                            .padding(.top, configuration.carouselTopPadding)
                    }
                }

                if configuration.showsRegionPicker, let carouselBottomPadding = configuration.carouselBottomPadding {
                    regionCarousel
                        .frame(width: max(proxy.size.width - 36, 0))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, carouselBottomPadding)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private func globeView(containerWidth: CGFloat) -> some View {
        ZStack {
            RegionGlobeBackdrop(style: configuration.style, ringOpacityScale: configuration.glowRingOpacityScale)
                .frame(width: globeGlowDiameter, height: globeGlowDiameter)
                .allowsHitTesting(false)
                .animation(.snappy(duration: 0.24), value: isFocusedRegionSelected)

            #if os(iOS)
            RegionGlobeRealityView(
                regions: regions,
                selectedRegionIDs: Binding(
                    get: { Array(selectedRegionIDs) },
                    set: { selectedRegionIDs = Set($0) }
                ),
                focusedRegionID: $focusedRegionID,
                focusRequest: $focusRequest,
                selectedCountryNames: selectedCountryNames,
                highlightedCountryNames: highlightedCountryNames,
                focusedCoordinate: focusedCoordinate,
                configuration: configuration
            )
            .frame(width: configuration.globeFrame.width, height: configuration.globeFrame.height)
            #else
            UnsupportedPlatformView(style: configuration.style)
                .frame(width: configuration.globeFrame.width, height: configuration.globeFrame.height)
            #endif
        }
        .frame(width: containerWidth, height: configuration.globeFrame.height)
    }

    private var isFocusedRegionSelected: Bool {
        selectedRegionIDs.contains(focusedRegionID)
    }

    private var globeGlowDiameter: CGFloat {
        let resolvedRingScale = configuration.ringScale ?? (isFocusedRegionSelected ? configuration.selectedRingScale : configuration.idleRingScale)
        return min(configuration.globeFrame.width, configuration.globeFrame.height) * resolvedRingScale
    }

    private var regionCarousel: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(regions) { region in
                        regionButton(for: region)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack {
                carouselEdgeFade(isLeading: true)
                Spacer(minLength: 0)
                carouselEdgeFade(isLeading: false)
            }
            .allowsHitTesting(false)
        }
        .frame(height: 54)
    }

    private func regionButton(for region: RegionGlobeRegion) -> some View {
        let isSelected = selectedRegionIDs.contains(region.id)

        return Button {
            focusedRegionID = region.id
            focusRequest += 1
            if isSelected {
                selectedRegionIDs.remove(region.id)
            } else {
                selectedRegionIDs.insert(region.id)
            }
        } label: {
            Text(region.displayTitle)
                .font(.system(size: 16, weight: .semibold, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(width: 150, height: 46)
                .foregroundStyle(isSelected ? configuration.style.selectedForeground : configuration.style.foreground)
                .background(isSelected ? configuration.style.selected : configuration.style.chipFill)
                .overlay(Rectangle().stroke(isSelected ? configuration.style.selected : configuration.style.chipStroke, lineWidth: 1))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(region.displayTitle)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }

    private func carouselEdgeFade(isLeading: Bool) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        configuration.style.background,
                        configuration.style.background.opacity(0)
                    ],
                    startPoint: isLeading ? .leading : .trailing,
                    endPoint: isLeading ? .trailing : .leading
                )
            )
            .frame(width: 28)
            .blur(radius: 3)
    }
}

private struct UnsupportedPlatformView: View {
    let style: RegionGlobeStyle

    var body: some View {
        Circle()
            .fill(style.foreground.opacity(0.08))
            .overlay(Circle().stroke(style.chipStroke, lineWidth: 1))
            .accessibilityLabel("Region globe requires iOS")
    }
}
