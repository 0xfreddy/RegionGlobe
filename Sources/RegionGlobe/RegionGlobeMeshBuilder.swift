#if os(iOS)
import CoreGraphics
import Foundation
@preconcurrency import RealityKit

@MainActor
enum RegionGlobeMeshBuilder {
    struct CountryDotCell {
        let countryName: String
        let longitude: CGFloat
        let latitude: CGFloat
    }

    static let dotStepDegrees: CGFloat = 0.82
    static let globeRadius: Float = 1
    static let neutralCellSurfaceRadius: Float = 1.009
    static let selectedCellSurfaceRadius: Float = 1.026
    static let neutralCellAngularRadius: Float = 0.0026
    static let selectedCellAngularRadius: Float = 0.0064
    static let dotSegmentCount = 12

    private static var cachedCountryDotCells: [CountryDotCell]?
    private static var cachedNeutralCellMesh: MeshResource?
    private static var cachedSelectedCellMeshes: [String: MeshResource] = [:]

    static func neutralCountryCellMesh() -> MeshResource? {
        if let cachedNeutralCellMesh {
            return cachedNeutralCellMesh
        }

        let mesh = countryCellMesh(
            for: countryDotCells(),
            surfaceRadius: neutralCellSurfaceRadius,
            angularRadius: neutralCellAngularRadius
        )
        cachedNeutralCellMesh = mesh
        return mesh
    }

    static func selectedCountryCellMesh(selectedCountryNames: Set<String>, cacheKey: String) -> MeshResource? {
        if let cachedMesh = cachedSelectedCellMeshes[cacheKey] {
            return cachedMesh
        }

        let cells = countryDotCells().filter { selectedCountryNames.contains($0.countryName) }
        guard !cells.isEmpty else { return nil }
        let mesh = countryCellMesh(
            for: cells,
            surfaceRadius: selectedCellSurfaceRadius,
            angularRadius: selectedCellAngularRadius
        )
        if let mesh {
            cachedSelectedCellMeshes[cacheKey] = mesh
        }
        return mesh
    }

    private static func countryCellMesh(
        for cells: [CountryDotCell],
        surfaceRadius: Float,
        angularRadius: Float
    ) -> MeshResource? {
        guard !cells.isEmpty else { return nil }
        let segmentCount = dotSegmentCount

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        positions.reserveCapacity(cells.count * (segmentCount + 1))
        normals.reserveCapacity(cells.count * (segmentCount + 1))
        indices.reserveCapacity(cells.count * segmentCount * 3)

        for cell in cells {
            let latitude = Float(cell.latitude) * Float.pi / 180
            let longitude = Float(cell.longitude) * Float.pi / 180
            let center = spherePoint(latitude: latitude, longitude: longitude)
            let east = normalize(SIMD3<Float>(cos(longitude), 0, -sin(longitude)))
            let north = normalize(SIMD3<Float>(
                -sin(latitude) * sin(longitude),
                cos(latitude),
                -sin(latitude) * cos(longitude)
            ))
            let centerIndex = UInt32(positions.count)

            positions.append(center * surfaceRadius)
            normals.append(center)

            for side in 0..<segmentCount {
                let angle = Float(side) * 2 * Float.pi / Float(segmentCount)
                let tangentOffset = (cos(angle) * east + sin(angle) * north) * angularRadius
                let vertex = normalize(center + tangentOffset)
                positions.append(vertex * surfaceRadius)
                normals.append(vertex)
            }

            for side in 0..<segmentCount {
                indices.append(centerIndex)
                indices.append(centerIndex + UInt32(side) + 1)
                indices.append(centerIndex + UInt32((side + 1) % segmentCount) + 1)
            }
        }

        var descriptor = MeshDescriptor(name: "country-cells")
        descriptor.positions = MeshBuffers.Positions(positions)
        descriptor.normals = MeshBuffers.Normals(normals)
        descriptor.primitives = .triangles(indices)
        return try? MeshResource.generate(from: [descriptor])
    }

    private static func spherePoint(latitude: Float, longitude: Float) -> SIMD3<Float> {
        let cosLatitude = cos(latitude)
        return normalize(SIMD3<Float>(
            cosLatitude * sin(longitude),
            sin(latitude),
            cosLatitude * cos(longitude)
        ))
    }

    private static func countryDotCells() -> [CountryDotCell] {
        if let cachedCountryDotCells {
            return cachedCountryDotCells
        }

        let cells = RegionGlobeGeoJSONLoader.loadCountryShapes().flatMap(generateDotCells(for:))
        cachedCountryDotCells = cells
        return cells
    }

    private static func generateDotCells(for shape: RegionGlobeCountryShape) -> [CountryDotCell] {
        var cells: [CountryDotCell] = []
        for polygon in shape.polygons {
            cells.append(contentsOf: dotCells(for: polygon, countryName: shape.name))
        }
        return cells
    }

    private static func dotCells(for polygon: RegionGlobeCountryPolygon, countryName: String) -> [CountryDotCell] {
        let exterior = continuousGeoRing(polygon.exterior)
        var holes: [[RegionGlobeGeoPoint]] = []
        for hole in polygon.holes {
            holes.append(continuousGeoRing(hole))
        }
        let bounds = geoBounds(exterior)
        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else { return [] }

        let baseStep = dotStepDegrees
        let rowStep = baseStep * 0.86
        let minLatitude = max(-78, bounds.minY)
        let maxLatitude = min(84, bounds.maxY)
        var cells: [CountryDotCell] = []
        var row = Int(floor((minLatitude + 90) / rowStep))
        let finalRow = Int(ceil((maxLatitude + 90) / rowStep))

        while row <= finalRow {
            let latitude = -90 + CGFloat(row) * rowStep
            let cosLatitude = max(cos(latitude * .pi / 180), 0.38)
            let longitudeStep = baseStep / cosLatitude
            let stagger = row.isMultiple(of: 2) ? CGFloat.zero : longitudeStep / 2
            var column = Int(floor((bounds.minX + 180 - stagger) / longitudeStep))

            while true {
                let longitude = -180 + CGFloat(column) * longitudeStep + stagger
                guard longitude <= bounds.maxX + longitudeStep else { break }
                let point = RegionGlobeGeoPoint(longitude: longitude, latitude: latitude)
                var isInsideHole = false
                for hole in holes where contains(point, in: hole) {
                    isInsideHole = true
                    break
                }
                if longitude >= bounds.minX - longitudeStep,
                   contains(point, in: exterior),
                   !isInsideHole {
                    cells.append(CountryDotCell(
                        countryName: countryName,
                        longitude: longitude,
                        latitude: latitude
                    ))
                }
                column += 1
            }

            row += 1
        }

        if cells.isEmpty {
            let fallback = RegionGlobeGeoPoint(longitude: bounds.midX, latitude: bounds.midY)
            cells.append(CountryDotCell(
                countryName: countryName,
                longitude: fallback.longitude,
                latitude: fallback.latitude
            ))
        }

        return cells
    }

    private static func continuousGeoRing(_ ring: [RegionGlobeGeoPoint]) -> [RegionGlobeGeoPoint] {
        guard let first = ring.first else { return [] }

        var points = [first]
        for point in ring.dropFirst() {
            let previous = points[points.count - 1]
            var longitude = point.longitude
            while longitude - previous.longitude > 180 {
                longitude -= 360
            }
            while previous.longitude - longitude > 180 {
                longitude += 360
            }
            points.append(RegionGlobeGeoPoint(longitude: longitude, latitude: point.latitude))
        }
        return points
    }

    private static func geoBounds(_ ring: [RegionGlobeGeoPoint]) -> CGRect {
        var bounds = CGRect.null
        for point in ring {
            bounds = bounds.union(CGRect(x: point.longitude, y: point.latitude, width: 0.1, height: 0.1))
        }
        return bounds
    }

    private static func contains(_ point: RegionGlobeGeoPoint, in ring: [RegionGlobeGeoPoint]) -> Bool {
        guard ring.count > 2 else { return false }
        var inside = false
        var previousIndex = ring.count - 1

        for index in ring.indices {
            let current = ring[index]
            let previous = ring[previousIndex]
            let crossesLatitude = (current.latitude > point.latitude) != (previous.latitude > point.latitude)
            if crossesLatitude {
                let denominator = previous.latitude - current.latitude
                if abs(denominator) > 0.0001 {
                    let intersectionLongitude = (previous.longitude - current.longitude) * (point.latitude - current.latitude) / denominator + current.longitude
                    if point.longitude < intersectionLongitude {
                        inside.toggle()
                    }
                }
            }
            previousIndex = index
        }

        return inside
    }
}
#endif
