# RegionGlobe

`RegionGlobe` is a SwiftUI component for rendering a selectable, focusable region globe with RealityKit. It bundles a GeoJSON world map, builds country dot meshes locally, and exposes a small public API for custom regions, selected highlights, focus targets, styles, pan, and auto-rotation.

## Requirements

- iOS 15+
- Swift 6.2+
- Swift Package Manager
- RealityKit

The interactive globe renderer is iOS-only. The package can still be built and tested on macOS for model and resource validation.

## Installation

Add this repository as a Swift Package dependency in Xcode:

```text
File > Add Package Dependencies...
```

Then import the library:

```swift
import RegionGlobe
import SwiftUI
```

## Basic Usage

```swift
struct ExampleView: View {
    @State private var selectedRegionIDs: Set<String> = ["us"]
    @State private var focusedRegionID = "us"
    @State private var focusRequest = 0

    var body: some View {
        RegionGlobe(
            regions: .defaultWorldRegions,
            selectedRegionIDs: $selectedRegionIDs,
            focusedRegionID: $focusedRegionID,
            focusRequest: $focusRequest,
            configuration: .init(
                autoRotates: true,
                showsRegionPicker: true,
                style: .darkOrange
            )
        )
        .frame(height: 620)
        .background(RegionGlobeStyle.darkOrange.background)
    }
}
```

Increment `focusRequest` when you want to re-run the focus animation for the current `focusedRegionID`.

## Custom Style

```swift
import UIKit

let style = RegionGlobeStyle(
    background: Color(red: 0.02, green: 0.02, blue: 0.03),
    foreground: .white,
    muted: .white.opacity(0.62),
    chipFill: .white.opacity(0.08),
    chipStroke: .cyan.opacity(0.35),
    selected: .orange,
    selectedForeground: .white,
    glow: .cyan,
    ring: .orange,
    shadow: .black,
    globeMaterial: UIColor(red: 0.01, green: 0.02, blue: 0.03, alpha: 1),
    globeTexture: .resource(name: "earth-topology", extension: "png", bundle: .main),
    globeRoughness: 0.86,
    globeIsMetallic: false,
    neutralDot: UIColor(white: 1, alpha: 0.78),
    selectedDot: UIColor.systemOrange
)

RegionGlobe(
    regions: .defaultWorldRegions,
    selectedRegionIDs: $selectedRegionIDs,
    focusedRegionID: $focusedRegionID,
    focusRequest: $focusRequest,
    configuration: .init(
        idleZoom: 1.08,
        selectedZoom: 1.32,
        style: .lightTeal
    )
)
```

`globeTexture` accepts a bundled image resource, a `UIImage`, or a `CGImage` on iOS. Leave it as `nil` for a solid-color globe.

## Custom Regions

```swift
let regions: [RegionGlobeRegion] = [
    .init(
        id: "north_america",
        title: "North America",
        countryNames: ["USA", "Canada", "Mexico"],
        focus: .init(latitude: 42.0, longitude: -105.0)
    ),
    .init(
        id: "japan",
        title: "Japan",
        countryNames: ["Japan"],
        focus: .init(latitude: 38.0, longitude: 138.0)
    )
]
```

`countryNames` must match the `properties.name` values in the bundled `countries.geojson` file. For example, the United States is named `USA` in this dataset.

## Notes

- First render builds and caches neutral country dot meshes from GeoJSON.
- Selected regions build and cache separate highlight meshes by country-name selection.
- `configuration.allowsPan` controls manual drag rotation.
- `configuration.autoRotates` controls idle rotation.
- `highlightedCountryNames` can highlight countries independently from region selection.
- `focusedCoordinate` can focus arbitrary latitude/longitude coordinates instead of a region.

## GeoJSON Attribution

The bundled `countries.geojson` was extracted from the original app handoff source. Its upstream source and license should be confirmed before a `1.0` public tag. Do not publish a final release until that attribution is verified.

## License

MIT. See `LICENSE`.
