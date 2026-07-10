#if os(iOS)
import SwiftUI
import UIKit
@preconcurrency import RealityKit

struct RegionGlobeRealityView: UIViewRepresentable {
    let regions: [RegionGlobeRegion]
    @Binding var selectedRegionIDs: [String]
    @Binding var focusedRegionID: String
    @Binding var focusRequest: Int
    var selectedCountryNames: Set<String> = []
    var highlightedCountryNames: Set<String> = []
    var focusedCoordinate: RegionGlobeCoordinate?
    var configuration: RegionGlobeConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator(
            regions: regions,
            selectedRegionIDs: $selectedRegionIDs,
            focusedRegionID: $focusedRegionID,
            focusRequest: $focusRequest,
            selectedCountryNames: selectedCountryNames,
            highlightedCountryNames: highlightedCountryNames,
            focusedCoordinate: focusedCoordinate,
            configuration: configuration
        )
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.backgroundColor = .clear
        view.environment.background = .color(.clear)
        view.renderOptions.insert(.disableMotionBlur)
        context.coordinator.configure(view)

        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.isEnabled = configuration.allowsPan
        view.addGestureRecognizer(pan)
        context.coordinator.panRecognizer = pan

        return view
    }

    func updateUIView(_ view: ARView, context: Context) {
        context.coordinator.regions = regions
        context.coordinator.selectedRegionIDs = $selectedRegionIDs
        context.coordinator.focusedRegionID = $focusedRegionID
        context.coordinator.focusRequest = $focusRequest
        context.coordinator.selectedCountryNames = selectedCountryNames
        context.coordinator.highlightedCountryNames = highlightedCountryNames
        context.coordinator.focusedCoordinate = focusedCoordinate
        context.coordinator.configuration = configuration
        context.coordinator.panRecognizer?.isEnabled = configuration.allowsPan
        context.coordinator.applyState(animated: true)
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        coordinator.teardown()
    }

    @MainActor
    final class Coordinator: NSObject {
        var regions: [RegionGlobeRegion]
        var selectedRegionIDs: Binding<[String]>
        var focusedRegionID: Binding<String>
        var focusRequest: Binding<Int>
        var selectedCountryNames: Set<String>
        var highlightedCountryNames: Set<String>
        var focusedCoordinate: RegionGlobeCoordinate?
        var configuration: RegionGlobeConfiguration
        weak var panRecognizer: UIPanGestureRecognizer?

        private weak var view: ARView?
        private let root = Entity()
        private weak var earthEntity: ModelEntity?
        private weak var neutralCellsEntity: ModelEntity?
        private weak var selectedCellsEntity: ModelEntity?
        private var cachedTextureKey: String?
        private var cachedGlobeTextureResource: TextureResource?
        private var currentYaw: Float = 0
        private var currentPitch: Float = 0
        private var currentZoom: Float = 1
        private var panStartYaw: Float = 0
        private var panStartPitch: Float = 0
        private var appliedSelectionKey = ""
        private var lastFocusedRegionID: String?
        private var lastFocusedCoordinate: RegionGlobeCoordinate?
        private var lastSelectedRegionIDs = Set<String>()
        private var lastFocusRequest = -1
        private var displayLink: CADisplayLink?
        private var autoRotatePausedUntil: CFTimeInterval = 0

        private static let minPolarAngle = Float.pi / Float(3.5)
        private static let maxPolarAngle = Float.pi - (Float.pi / 3)
        private static let minPitch = (Float.pi / 2) - maxPolarAngle
        private static let maxPitch = (Float.pi / 2) - minPolarAngle

        init(
            regions: [RegionGlobeRegion],
            selectedRegionIDs: Binding<[String]>,
            focusedRegionID: Binding<String>,
            focusRequest: Binding<Int>,
            selectedCountryNames: Set<String>,
            highlightedCountryNames: Set<String>,
            focusedCoordinate: RegionGlobeCoordinate?,
            configuration: RegionGlobeConfiguration
        ) {
            self.regions = regions
            self.selectedRegionIDs = selectedRegionIDs
            self.focusedRegionID = focusedRegionID
            self.focusRequest = focusRequest
            self.selectedCountryNames = selectedCountryNames
            self.highlightedCountryNames = highlightedCountryNames
            self.focusedCoordinate = focusedCoordinate
            self.configuration = configuration
        }

        func configure(_ view: ARView) {
            self.view = view
            view.scene.anchors.removeAll()

            let anchor = AnchorEntity(world: .zero)
            anchor.addChild(root)
            view.scene.addAnchor(anchor)

            let camera = PerspectiveCamera()
            camera.position = [0, 0, 3.75]
            camera.look(at: .zero, from: camera.position, relativeTo: nil)
            anchor.addChild(camera)

            let light = DirectionalLight()
            light.light.intensity = 2_800
            light.look(at: .zero, from: [1.6, 1.2, 2.4], relativeTo: nil)
            anchor.addChild(light)

            let fillLight = DirectionalLight()
            fillLight.light.intensity = 1_450
            fillLight.look(at: .zero, from: [-1.8, -0.4, 2.2], relativeTo: nil)
            anchor.addChild(fillLight)

            let sphere = ModelEntity(
                mesh: .generateSphere(radius: RegionGlobeMeshBuilder.globeRadius),
                materials: globeBaseMaterials()
            )
            sphere.name = "earth"
            earthEntity = sphere
            root.addChild(sphere)

            if let neutralMesh = RegionGlobeMeshBuilder.neutralCountryCellMesh() {
                let neutralCells = ModelEntity(
                    mesh: neutralMesh,
                    materials: neutralCellMaterials()
                )
                neutralCells.name = "country-cells-neutral"
                neutralCellsEntity = neutralCells
                root.addChild(neutralCells)
            }

            let selectedCells = ModelEntity(
                mesh: .generateBox(size: 0.001),
                materials: selectedCellMaterials()
            )
            selectedCells.name = "country-cells-selected"
            selectedCells.isEnabled = false
            selectedCellsEntity = selectedCells
            root.addChild(selectedCells)

            applyState(animated: false)
            updateAutoRotation()
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view)
            switch recognizer.state {
            case .began:
                pauseAutoRotation(for: 1.5)
                panStartYaw = currentYaw
                panStartPitch = currentPitch
            case .changed:
                pauseAutoRotation(for: 1.5)
                let yaw = panStartYaw + Float(translation.x) * 0.008
                let pitch = panStartPitch + Float(translation.y) * 0.004
                applyGlobeTransform(
                    yaw: yaw,
                    pitch: Self.clampedPitch(pitch),
                    zoom: currentZoom,
                    animated: false
                )
            case .ended, .cancelled, .failed:
                pauseAutoRotation(for: 1.2)
            default:
                break
            }
        }

        func teardown() {
            displayLink?.invalidate()
            displayLink = nil
        }

        func applyState(animated: Bool) {
            let selected = Set(selectedRegionIDs.wrappedValue)
            let focusID = focusedRegionID.wrappedValue
            let currentFocusRequest = focusRequest.wrappedValue
            refreshBaseMaterials()
            updateGlobeMaterial(selected: selected)
            updateAutoRotation()

            if lastFocusedRegionID != focusID ||
                lastFocusedCoordinate != focusedCoordinate ||
                lastSelectedRegionIDs != selected ||
                lastFocusRequest != currentFocusRequest {
                if let focusedCoordinate {
                    focus(coordinate: focusedCoordinate, animated: animated)
                } else {
                    focus(regionID: focusID, selected: selected, animated: animated)
                }
                lastFocusedRegionID = focusID
                lastFocusedCoordinate = focusedCoordinate
                lastSelectedRegionIDs = selected
                lastFocusRequest = currentFocusRequest
            }
        }

        private func focus(regionID: String, selected: Set<String>, animated: Bool) {
            let target = regions.first { $0.id == regionID }?.focus ?? regions.first?.focus ?? .init(latitude: 0, longitude: 0)
            let latitude = Float(target.latitude) * Float.pi / 180
            let longitude = Float(target.longitude) * Float.pi / 180
            let zoom = selected.contains(regionID) ? configuration.selectedZoom : configuration.idleZoom
            let duration = animated ? configuration.animationDuration : 0
            pauseAutoRotation(for: duration + 4.0)
            applyGlobeTransform(
                yaw: -longitude,
                pitch: Self.clampedPitch(latitude),
                zoom: zoom,
                animated: animated,
                duration: duration
            )
        }

        private func focus(coordinate: RegionGlobeCoordinate, animated: Bool) {
            let latitude = Float(coordinate.latitude) * Float.pi / 180
            let longitude = Float(coordinate.longitude) * Float.pi / 180
            let duration = animated ? configuration.animationDuration : 0
            pauseAutoRotation(for: duration + 4.0)
            applyGlobeTransform(
                yaw: -longitude,
                pitch: Self.clampedPitch(latitude),
                zoom: configuration.coordinateFocusZoom,
                animated: animated,
                duration: duration
            )
        }

        private func applyGlobeTransform(
            yaw: Float,
            pitch: Float,
            zoom: Float,
            animated: Bool,
            duration: TimeInterval = 0
        ) {
            currentYaw = yaw
            currentPitch = Self.clampedPitch(pitch)
            currentZoom = zoom

            let yawRotation = simd_quatf(angle: currentYaw, axis: [0, 1, 0])
            let pitchRotation = simd_quatf(angle: currentPitch, axis: [1, 0, 0])
            let transform = Transform(
                scale: [currentZoom, currentZoom, currentZoom],
                rotation: pitchRotation * yawRotation,
                translation: .zero
            )

            if animated {
                root.move(to: transform, relativeTo: root.parent, duration: duration, timingFunction: .easeInOut)
            } else {
                root.transform = transform
            }
        }

        private func startAutoRotation() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
            if #available(iOS 15.0, *) {
                link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            }
            link.add(to: .main, forMode: .common)
            displayLink = link
            pauseAutoRotation(for: 1.4)
        }

        private func updateAutoRotation() {
            if configuration.autoRotates {
                startAutoRotation()
            } else {
                displayLink?.invalidate()
                displayLink = nil
            }
        }

        private func pauseAutoRotation(for seconds: CFTimeInterval) {
            autoRotatePausedUntil = max(autoRotatePausedUntil, CACurrentMediaTime() + seconds)
        }

        @objc private func handleDisplayLink(_ link: CADisplayLink) {
            guard CACurrentMediaTime() >= autoRotatePausedUntil else { return }
            applyGlobeTransform(
                yaw: currentYaw + Float(link.duration) * configuration.rotationSpeed,
                pitch: currentPitch,
                zoom: currentZoom,
                animated: false
            )
        }

        private static func clampedPitch(_ pitch: Float) -> Float {
            min(max(pitch, minPitch), maxPitch)
        }

        private func updateGlobeMaterial(selected: Set<String>) {
            let activeCountryNames = countryNames(for: selected)
                .union(selectedCountryNames)
                .union(highlightedCountryNames)
            let selectionKey = activeCountryNames.sorted().joined(separator: ",")
            if selectionKey == appliedSelectionKey {
                if selectedCellsEntity?.isEnabled == true {
                    selectedCellsEntity?.model?.materials = selectedCellMaterials()
                }
                return
            }

            guard !activeCountryNames.isEmpty else {
                selectedCellsEntity?.isEnabled = false
                appliedSelectionKey = selectionKey
                return
            }

            if let mesh = RegionGlobeMeshBuilder.selectedCountryCellMesh(selectedCountryNames: activeCountryNames, cacheKey: selectionKey),
               let selectedCellsEntity {
                var component = selectedCellsEntity.model ?? ModelComponent(mesh: mesh, materials: selectedCellMaterials())
                component.mesh = mesh
                component.materials = selectedCellMaterials()
                selectedCellsEntity.model = component
                selectedCellsEntity.isEnabled = true
            } else {
                selectedCellsEntity?.isEnabled = false
            }

            appliedSelectionKey = selectionKey
        }

        private func refreshBaseMaterials() {
            earthEntity?.model?.materials = globeBaseMaterials()
            neutralCellsEntity?.model?.materials = neutralCellMaterials()
            if selectedCellsEntity?.isEnabled == true {
                selectedCellsEntity?.model?.materials = selectedCellMaterials()
            }
        }

        private func globeBaseMaterials() -> [any RealityKit.Material] {
            let texture = globeTextureResource().map { MaterialParameters.Texture($0) }
            var material = SimpleMaterial()
            material.color = PhysicallyBasedMaterial.BaseColor(tint: configuration.style.globeMaterial, texture: texture)
            material.roughness = .float(configuration.style.globeRoughness)
            material.metallic = configuration.style.globeIsMetallic ? 1 : 0
            return [material]
        }

        private func neutralCellMaterials() -> [any RealityKit.Material] {
            var material = UnlitMaterial()
            material.color = .init(tint: configuration.style.neutralDot)
            return [material]
        }

        private func selectedCellMaterials() -> [any RealityKit.Material] {
            var material = UnlitMaterial()
            material.color = .init(tint: configuration.style.selectedDot)
            return [material]
        }

        private func countryNames(for selectedRegionIDs: Set<String>) -> Set<String> {
            selectedRegionIDs.reduce(into: Set<String>()) { names, regionID in
                names.formUnion(regions.first { $0.id == regionID }?.countryNames ?? [])
            }
        }

        private func globeTextureResource() -> TextureResource? {
            guard let texture = configuration.style.globeTexture else {
                cachedTextureKey = nil
                cachedGlobeTextureResource = nil
                return nil
            }

            let key = texture.cacheKey
            if cachedTextureKey == key, let cachedGlobeTextureResource {
                return cachedGlobeTextureResource
            }

            let options = TextureResource.CreateOptions(semantic: .color)
            let resource: TextureResource?
            switch texture {
            case let .resource(name, fileExtension, bundle):
                guard let url = bundle.url(forResource: name, withExtension: fileExtension) else {
                    resource = nil
                    break
                }
                resource = try? TextureResource.load(contentsOf: url, withName: name, options: options)
            case let .image(image, name):
                guard let cgImage = image.cgImage else {
                    resource = nil
                    break
                }
                resource = try? TextureResource.generate(from: cgImage, withName: name, options: options)
            case let .cgImage(cgImage, name):
                resource = try? TextureResource.generate(from: cgImage, withName: name, options: options)
            }

            cachedTextureKey = key
            cachedGlobeTextureResource = resource
            return resource
        }
    }
}
#endif
