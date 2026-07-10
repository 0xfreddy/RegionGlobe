import CoreGraphics
import Foundation

struct RegionGlobeGeoPoint {
    let longitude: CGFloat
    let latitude: CGFloat
}

struct RegionGlobeCountryPolygon {
    let exterior: [RegionGlobeGeoPoint]
    let holes: [[RegionGlobeGeoPoint]]
}

struct RegionGlobeCountryShape {
    let name: String
    let polygons: [RegionGlobeCountryPolygon]
}

enum RegionGlobeGeoJSONLoader {
    static func loadCountryShapes(bundle: Bundle = .module) -> [RegionGlobeCountryShape] {
        guard let url = bundle.url(forResource: "countries", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = object["features"] as? [[String: Any]] else {
            return []
        }

        func ringPoints(_ ring: [[Double]]) -> [RegionGlobeGeoPoint] {
            var points: [RegionGlobeGeoPoint] = []
            for coordinate in ring {
                guard coordinate.count >= 2 else { continue }
                points.append(RegionGlobeGeoPoint(longitude: CGFloat(coordinate[0]), latitude: CGFloat(coordinate[1])))
            }
            return points
        }

        func polygonShape(from polygon: [[[Double]]]) -> RegionGlobeCountryPolygon? {
            var rings: [[RegionGlobeGeoPoint]] = []
            for ring in polygon {
                let points = ringPoints(ring)
                if !points.isEmpty {
                    rings.append(points)
                }
            }
            guard let exterior = rings.first else { return nil }
            return RegionGlobeCountryPolygon(exterior: exterior, holes: Array(rings.dropFirst()))
        }

        var shapes: [RegionGlobeCountryShape] = []
        for feature in features {
            guard let properties = feature["properties"] as? [String: Any],
                  let name = properties["name"] as? String,
                  let geometry = feature["geometry"] as? [String: Any],
                  let type = geometry["type"] as? String else {
                continue
            }

            if type == "Polygon",
               let polygon = geometry["coordinates"] as? [[[Double]]],
               let countryPolygon = polygonShape(from: polygon) {
                shapes.append(RegionGlobeCountryShape(name: name, polygons: [countryPolygon]))
                continue
            }

            if type == "MultiPolygon",
               let multiPolygon = geometry["coordinates"] as? [[[[Double]]]] {
                var polygons: [RegionGlobeCountryPolygon] = []
                for polygon in multiPolygon {
                    if let countryPolygon = polygonShape(from: polygon) {
                        polygons.append(countryPolygon)
                    }
                }
                if !polygons.isEmpty {
                    shapes.append(RegionGlobeCountryShape(name: name, polygons: polygons))
                }
            }
        }
        return shapes
    }
}
