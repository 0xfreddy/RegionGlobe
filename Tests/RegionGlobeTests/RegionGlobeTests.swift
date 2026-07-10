import Testing
@testable import RegionGlobe

@Test func defaultWorldRegionsExposeExpectedIDsAndCountries() {
    let regions = [RegionGlobeRegion].defaultWorldRegions

    #expect(regions.map(\.id) == ["us", "middle_east", "europe", "asia", "africa", "latam", "russia"])
    #expect(regions.first { $0.id == "us" }?.countryNames == ["USA"])
    #expect(regions.first { $0.id == "latam" }?.displayTitle == "Latam")
    #expect(regions.first { $0.id == "europe" }?.countryNames.contains("France") == true)
}

@Test func bundledGeoJSONLoadsCountryShapes() {
    let shapes = RegionGlobeGeoJSONLoader.loadCountryShapes()
    let countryNames = Set(shapes.map(\.name))

    #expect(shapes.count > 100)
    #expect(countryNames.contains("USA"))
    #expect(countryNames.contains("France"))
    #expect(countryNames.contains("Brazil"))
    #expect(countryNames.contains("Russia"))
}

@Test func configurationDefaultsMatchPublicContract() {
    let configuration = RegionGlobeConfiguration()

    #expect(configuration.showsRegionPicker)
    #expect(configuration.autoRotates)
    #expect(configuration.allowsPan)
    #expect(configuration.idleZoom == 1.12)
    #expect(configuration.selectedZoom == 1.38)
    #expect(configuration.coordinateFocusZoom == 1.36)
}
