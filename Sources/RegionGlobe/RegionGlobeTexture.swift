import CoreGraphics
import Foundation

#if os(iOS)
import UIKit
#endif

public enum RegionGlobeTexture: @unchecked Sendable {
    case resource(name: String, extension: String = "png", bundle: Bundle = .main)

    #if os(iOS)
    case image(PlatformImage, name: String? = nil)
    case cgImage(CGImage, name: String? = nil)
    #endif
}

#if os(iOS)
extension RegionGlobeTexture {
    var cacheKey: String {
        switch self {
        case let .resource(name, fileExtension, bundle):
            return "resource:\(bundle.bundleIdentifier ?? bundle.bundlePath):\(name).\(fileExtension)"
        case let .image(image, name):
            return "image:\(name ?? "\(ObjectIdentifier(image))")"
        case let .cgImage(image, name):
            return "cgImage:\(name ?? "\(ObjectIdentifier(image))")"
        }
    }
}
#endif
