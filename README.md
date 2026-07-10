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
            selectedCountryNames: ["France", "Japan"],
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

## Public API

### RegionGlobe

```swift
RegionGlobe(
    regions: [RegionGlobeRegion],
    selectedRegionIDs: Binding<Set<String>>,
    focusedRegionID: Binding<String>,
    focusRequest: Binding<Int>,
    selectedCountryNames: Set<String> = [],
    highlightedCountryNames: Set<String> = [],
    focusedCoordinate: RegionGlobeCoordinate? = nil,
    configuration: RegionGlobeConfiguration = .init()
)
```

| Prop | Type | Description |
| --- | --- | --- |
| `regions` | `[RegionGlobeRegion]` | Region definitions to show in the picker and use for country highlighting/focus. |
| `selectedRegionIDs` | `Binding<Set<String>>` | Selected region IDs. Matching countries render with the selected continent/dot color. |
| `focusedRegionID` | `Binding<String>` | Region ID the globe should rotate/focus toward. |
| `focusRequest` | `Binding<Int>` | Increment this value to replay focus animation for the current region or coordinate. |
| `selectedCountryNames` | `Set<String>` | First-class country-level selection. These countries render with `selectedDot` even when their regions are not selected. |
| `highlightedCountryNames` | `Set<String>` | Backward-compatible alias for extra country highlights. Prefer `selectedCountryNames` for new code. |
| `focusedCoordinate` | `RegionGlobeCoordinate?` | Optional latitude/longitude focus target. Overrides `focusedRegionID` when present. |
| `configuration` | `RegionGlobeConfiguration` | Layout, interaction, animation, zoom, and style options. |

### RegionGlobeConfiguration

| Prop | Type | Default | Description |
| --- | --- | --- | --- |
| `showsRegionPicker` | `Bool` | `true` | Shows or hides the built-in horizontal region picker. |
| `autoRotates` | `Bool` | `true` | Enables idle globe rotation. |
| `allowsPan` | `Bool` | `true` | Enables drag/pan rotation. |
| `globeFrame` | `CGSize` | `520 x 558` | Fixed RealityKit globe view size inside the SwiftUI layout. |
| `carouselTopPadding` | `CGFloat` | `28` | Top padding above the region picker when it is placed below the globe. |
| `globeCarouselSpacing` | `CGFloat` | `24` | Vertical spacing between globe and picker. |
| `carouselBottomPadding` | `CGFloat?` | `nil` | When set, pins the picker to the bottom of the component with this padding. |
| `idleRingScale` | `CGFloat` | `0.55` | Glow/ring diameter scale when the focused region is not selected. |
| `selectedRingScale` | `CGFloat` | `0.67` | Glow/ring diameter scale when the focused region is selected. |
| `ringScale` | `CGFloat?` | `nil` | Fixed override for ring scale. |
| `glowRingOpacityScale` | `Double` | `1` | Multiplier for ring/glow opacity. |
| `idleZoom` | `Float` | `1.12` | Globe zoom when focusing an unselected region. |
| `selectedZoom` | `Float` | `1.38` | Globe zoom when focusing a selected region. |
| `coordinateFocusZoom` | `Float` | `1.36` | Globe zoom when `focusedCoordinate` is used. |
| `rotationSpeed` | `Float` | `0.065` | Idle auto-rotation speed. |
| `animationDuration` | `TimeInterval` | `0.82` | Focus animation duration. |
| `style` | `RegionGlobeStyle` | `.darkOrange` | Full color/material/texture styling. |

### RegionGlobeStyle

| Prop | Type | Description |
| --- | --- | --- |
| `background` | `Color` | Background color used by fades and examples. Apply it to your own surrounding view if needed. |
| `foreground` | `Color` | Unselected picker text color. |
| `muted` | `Color` | Secondary text color for host/demo UI. |
| `chipFill` | `Color` | Unselected picker chip fill. |
| `chipStroke` | `Color` | Unselected picker chip border. |
| `selected` | `Color` | Selected picker chip fill and the default selected accent. |
| `selectedForeground` | `Color` | Selected picker text color. |
| `glow` | `Color` | Soft radial glow color behind the globe. |
| `ring` | `Color` | Bright ring/border color around the globe. Defaults to `glow` when omitted. |
| `shadow` | `Color` | Ellipse shadow under the globe. |
| `globeMaterial` | `UIColor` | Base material/tint color of the globe sphere. iOS only. |
| `globeTexture` | `RegionGlobeTexture?` | Optional texture for the globe sphere. iOS only. |
| `globeRoughness` | `Float` | RealityKit material roughness. Lower is glossier, higher is flatter. |
| `globeIsMetallic` | `Bool` | Enables metallic material response for the globe sphere. |
| `neutralDot` | `UIColor` | Color of unselected country/continent dots. iOS only. |
| `selectedDot` | `UIColor` | Color of selected/highlighted country/continent dots. iOS only. |

Preset styles:

```swift
RegionGlobeStyle.darkOrange
RegionGlobeStyle.lightTeal
```

### RegionGlobeTexture

| Case | Use When |
| --- | --- |
| `.resource(name:extension:bundle:)` | Texture image is bundled in your app or another bundle. |
| `.image(_:name:)` | You already have a `UIImage`. |
| `.cgImage(_:name:)` | You already have a `CGImage`. |

Examples:

```swift
// App bundle PNG
globeTexture: .resource(name: "earth-topology", extension: "png", bundle: .main)

// UIImage generated at runtime
globeTexture: .image(myGeneratedImage, name: "brand-grid")

// CGImage from your rendering pipeline
globeTexture: .cgImage(myCGImage, name: "custom-map")
```

Textures are applied to the globe sphere material. Country/continent dots remain separate meshes controlled by `neutralDot` and `selectedDot`.

### Country-Level Selection

Use `selectedCountryNames` when you want to highlight individual countries without creating a region or selecting a continent-style group:

```swift
RegionGlobe(
    regions: .defaultWorldRegions,
    selectedRegionIDs: $selectedRegionIDs,
    focusedRegionID: $focusedRegionID,
    focusRequest: $focusRequest,
    selectedCountryNames: ["France", "Japan", "Brazil"]
)
```

Country names must match `properties.name` in the bundled GeoJSON. Common examples include `USA`, `France`, `Japan`, `Brazil`, `India`, `South Africa`, and `Australia`.

You can combine both levels:

```swift
RegionGlobe(
    regions: .defaultWorldRegions,
    selectedRegionIDs: $selectedRegionIDs, // e.g. ["europe"]
    focusedRegionID: $focusedRegionID,
    focusRequest: $focusRequest,
    selectedCountryNames: ["Japan", "Brazil"]
)
```

The selected country mesh is the union of selected region countries plus `selectedCountryNames`.

### RegionGlobeRegion

| Prop | Type | Description |
| --- | --- | --- |
| `id` | `String` | Stable region ID used by selection and focus bindings. |
| `title` | `String` | Region name. |
| `displayTitle` | `String` | Optional picker label override. Defaults to `title`. |
| `countryNames` | `Set<String>` | GeoJSON country names highlighted when the region is selected. |
| `focus` | `RegionGlobeCoordinate` | Latitude/longitude target used when focusing this region. |

### RegionGlobeCoordinate

| Prop | Type | Description |
| --- | --- | --- |
| `latitude` | `Double` | Latitude in degrees. |
| `longitude` | `Double` | Longitude in degrees. |

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
- `selectedCountryNames` can highlight countries independently from region selection.
- `highlightedCountryNames` is still supported as a compatibility hook for country highlights.
- `focusedCoordinate` can focus arbitrary latitude/longitude coordinates instead of a region.

## GeoJSON Attribution

The bundled `countries.geojson` was extracted from the original app handoff source. Its upstream source and license should be confirmed before a `1.0` public tag. Do not publish a final release until that attribution is verified.

## License

MIT. See `LICENSE`.
