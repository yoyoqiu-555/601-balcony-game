//
//  BalconyGameView.swift
//  6th balcony
//
//  横屏阳台场景：仅用精灵图与场景交互，界面不出现物品名称与占位色块。
//

import SwiftUI

// MARK: - 场景图尺寸（与资源一致）

private enum SceneImage {
    static let size = CGSize(width: 1024, height: 574)
}

enum HideableItem: String, CaseIterable, Identifiable {
    case scissors
    case flowerPot
    case bugNet
    case wateringCan

    var id: String { rawValue }

    var startCenter: CGPoint {
        switch self {
        case .scissors: return CGPoint(x: 0.42, y: 0.68)
        case .flowerPot: return CGPoint(x: 0.50, y: 0.56)
        case .bugNet: return CGPoint(x: 0.68, y: 0.50)
        case .wateringCan: return CGPoint(x: 0.62, y: 0.63)
        }
    }
}

private extension HideableItem {
    var spriteAsset: String {
        switch self {
        case .scissors: return "ItemScissors"
        case .flowerPot: return "ItemFlowerPot"
        case .bugNet: return "ItemBugNet"
        case .wateringCan: return "ItemWateringCan"
        }
    }
}

private enum ToolHotspot {
    /// 晾衣场景精灵（按住拖动整块图作为拾取反馈）
    static let cloth = CGRect(x: 0.04, y: 0.20, width: 0.24, height: 0.48)
    static let rugBodyFull = CGRect(x: 0.30, y: 0.52, width: 0.32, height: 0.28)
    static let rugUnderCorner = CGRect(x: 0.44, y: 0.60, width: 0.20, height: 0.20)

    static let box = CGRect(x: 0.73, y: 0.55, width: 0.15, height: 0.24)
    static let boxInterior = CGRect(x: 0.735, y: 0.58, width: 0.13, height: 0.14)

    static let cabinet = CGRect(x: 0.855, y: 0.38, width: 0.11, height: 0.38)
    static let cabinetHandle = CGRect(x: 0.852, y: 0.50, width: 0.04, height: 0.09)
    static let cabinetInterior = CGRect(x: 0.862, y: 0.45, width: 0.09, height: 0.24)
}

private enum HideMethod: Equatable {
    case cloth
    case rug
    case box
    case cabinet
}

// MARK: - 几何

private func fittedImageRect(in container: CGSize) -> CGRect {
    let iw = SceneImage.size.width
    let ih = SceneImage.size.height
    let scale = min(container.width / iw, container.height / ih)
    let w = iw * scale
    let h = ih * scale
    let x = (container.width - w) * 0.5
    let y = (container.height - h) * 0.5
    return CGRect(x: x, y: y, width: w, height: h)
}

private func scenePoint(normalized n: CGPoint, in scene: CGRect) -> CGPoint {
    CGPoint(x: scene.minX + n.x * scene.width, y: scene.minY + n.y * scene.height)
}

private func normalizedPoint(scene p: CGPoint, in scene: CGRect) -> CGPoint {
    CGPoint(x: (p.x - scene.minX) / scene.width, y: (p.y - scene.minY) / scene.height)
}

private func clampItemCenter(_ p: CGPoint) -> CGPoint {
    CGPoint(x: min(max(p.x, 0.06), 0.94), y: min(max(p.y, 0.40), 0.88))
}

private func clampClothCenter(_ p: CGPoint) -> CGPoint {
    CGPoint(x: min(max(p.x, 0.04), 0.92), y: min(max(p.y, 0.18), 0.88))
}

private func itemFootprint(center: CGPoint, radius: CGFloat = 0.038) -> CGRect {
    CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    )
}

private func overlaps(_ a: CGRect, _ b: CGRect) -> Bool {
    a.intersects(b)
}

private func rectInScene(_ n: CGRect, scene: CGRect) -> CGRect {
    CGRect(
        x: scene.minX + n.minX * scene.width,
        y: scene.minY + n.minY * scene.height,
        width: n.width * scene.width,
        height: n.height * scene.height
    )
}

private func clothIsAboveCoveringItem(cloth: CGPoint, item: CGPoint) -> Bool {
    let dy = item.y - cloth.y
    let dx = abs(cloth.x - item.x)
    return dy > 0.018 && dy < 0.14 && dx < 0.078
}

// MARK: - ViewModel

@MainActor
final class BalconyGameViewModel: ObservableObject {
    @Published private(set) var itemCenters: [HideableItem: CGPoint]
    @Published private var hidden: [HideableItem: HideMethod] = [:]

    @Published var rugCornerLifted = false
    @Published var boxOpen = false
    @Published var cabinetOpen = false

    @Published var itemPendingCabinet: HideableItem?
    @Published var itemPendingBox: HideableItem?

    @Published var carryingCloth = false
    @Published var clothNormCenter: CGPoint = CGPoint(x: ToolHotspot.cloth.midX, y: ToolHotspot.cloth.midY)

    @Published var clothWrapPulseNorm: CGPoint?

    init() {
        var centers: [HideableItem: CGPoint] = [:]
        for item in HideableItem.allCases {
            centers[item] = item.startCenter
        }
        itemCenters = centers
    }

    var hiddenCount: Int { hidden.count }

    func isHidden(_ item: HideableItem) -> Bool {
        hidden[item] != nil
    }

    func reset() {
        hidden = [:]
        rugCornerLifted = false
        boxOpen = false
        cabinetOpen = false
        itemPendingCabinet = nil
        itemPendingBox = nil
        carryingCloth = false
        clothWrapPulseNorm = nil
        clothNormCenter = CGPoint(x: ToolHotspot.cloth.midX, y: ToolHotspot.cloth.midY)
        var centers: [HideableItem: CGPoint] = [:]
        for item in HideableItem.allCases {
            centers[item] = item.startCenter
        }
        itemCenters = centers
    }

    func setItemCenter(_ item: HideableItem, _ norm: CGPoint) {
        guard !isHidden(item) else { return }
        itemCenters[item] = clampItemCenter(norm)
    }

    func beginClothDragIfNeeded() {
        if !carryingCloth {
            carryingCloth = true
        }
    }

    func updateClothDuringDrag(_ norm: CGPoint) {
        clothNormCenter = norm
    }

    func endClothDrag(at norm: CGPoint) {
        carryingCloth = false
        clothNormCenter = CGPoint(x: ToolHotspot.cloth.midX, y: ToolHotspot.cloth.midY)

        for item in HideableItem.allCases where !isHidden(item) {
            let c = itemCenters[item] ?? item.startCenter
            guard clothIsAboveCoveringItem(cloth: norm, item: c) else { continue }
            let pulse = itemCenters[item] ?? c
            clothWrapPulseNorm = pulse
            hidden[item] = .cloth
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
                self?.clothWrapPulseNorm = nil
            }
            return
        }
    }

    func tapRug() {
        if !rugCornerLifted {
            rugCornerLifted = true
        } else {
            sealRugIfItemUnderCorner()
        }
    }

    private func sealRugIfItemUnderCorner() {
        for item in HideableItem.allCases where !isHidden(item) {
            let c = itemCenters[item] ?? item.startCenter
            if overlaps(itemFootprint(center: c), ToolHotspot.rugUnderCorner) {
                hidden[item] = .rug
                break
            }
        }
        rugCornerLifted = false
    }

    func tapBox() {
        if boxOpen {
            boxOpen = false
            if let pending = itemPendingBox {
                hidden[pending] = .box
                itemPendingBox = nil
            }
        } else {
            boxOpen = true
            itemPendingBox = nil
        }
    }

    func syncBoxAndCabinetPendingAfterItemMove(_ item: HideableItem) {
        let c = itemCenters[item] ?? item.startCenter
        if boxOpen {
            if overlaps(itemFootprint(center: c), ToolHotspot.boxInterior) {
                itemPendingBox = item
            } else if itemPendingBox == item {
                itemPendingBox = nil
            }
        }
        if cabinetOpen {
            if overlaps(itemFootprint(center: c), ToolHotspot.cabinetInterior) {
                itemPendingCabinet = item
            } else if itemPendingCabinet == item {
                itemPendingCabinet = nil
            }
        }
    }

    func tapCabinetHandle() {
        cabinetOpen = true
    }

    func tapCabinetBody() {
        guard cabinetOpen else { return }
        cabinetOpen = false
        if let pending = itemPendingCabinet {
            hidden[pending] = .cabinet
            itemPendingCabinet = nil
        }
    }
}

// MARK: - 主界面

struct BalconyGameView: View {
    @StateObject private var model = BalconyGameViewModel()
    @State private var itemDragOriginNorm: [HideableItem: CGPoint] = [:]
    @State private var clothDragOriginNorm: CGPoint?
    @State private var wrapPulseScale: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let scene = fittedImageRect(in: geo.size)
            ZStack {
                Color.black.ignoresSafeArea()
                sceneLayer(scene: scene)
                rugSpriteOverlay(scene: scene)
                boxSpriteOverlay(scene: scene)
                toolTapLayer(scene: scene)
                itemLayer(scene: scene)
                clothWrapPulseLayer(scene: scene)
                clothVisual(scene: scene)
                clothGestureLayer(scene: scene)
                hud
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: model.clothWrapPulseNorm) { _, new in
                if new != nil {
                    wrapPulseScale = 0.5
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.75)) {
                        wrapPulseScale = 1.0
                    }
                }
            }
        }
    }

    private func sceneLayer(scene: CGRect) -> some View {
        Image("BalconyScene")
            .resizable()
            .interpolation(.high)
            .aspectRatio(SceneImage.size.width / SceneImage.size.height, contentMode: .fit)
            .frame(width: scene.width, height: scene.height)
            .position(x: scene.midX, y: scene.midY)
            .allowsHitTesting(false)
    }

    private func rugSpriteOverlay(scene: CGRect) -> some View {
        let rugFrame = rectInScene(ToolHotspot.rugBodyFull, scene: scene)
        return ZStack {
            Image("ToolRugFlat")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: rugFrame.width * 1.02, height: rugFrame.height * 1.02)
                .opacity(model.rugCornerLifted ? 0 : 1)
            Image("ToolRugLifted")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: rugFrame.width * 1.02, height: rugFrame.height * 1.02)
                .opacity(model.rugCornerLifted ? 1 : 0)
        }
        .position(x: rugFrame.midX, y: rugFrame.midY)
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.2), value: model.rugCornerLifted)
    }

    private func boxSpriteOverlay(scene: CGRect) -> some View {
        let r = rectInScene(ToolHotspot.box, scene: scene)
        let name = model.boxOpen ? "ToolBoxOpen" : "ToolBoxClosed"
        return Image(name)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: r.width * 1.08, height: r.height * 1.12)
            .position(x: r.midX, y: r.midY)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.18), value: model.boxOpen)
    }

    private func toolTapLayer(scene: CGRect) -> some View {
        ZStack {
            tapRect(ToolHotspot.rugBodyFull, scene: scene) { model.tapRug() }
            tapRect(ToolHotspot.box, scene: scene) { model.tapBox() }
            if model.cabinetOpen {
                tapRect(ToolHotspot.cabinet, scene: scene) { model.tapCabinetBody() }
            } else {
                tapRect(ToolHotspot.cabinetHandle, scene: scene) { model.tapCabinetHandle() }
            }
        }
    }

    private func tapRect(_ n: CGRect, scene: CGRect, action: @escaping () -> Void) -> some View {
        let r = rectInScene(n, scene: scene)
        return Color.clear
            .frame(width: r.width, height: r.height)
            .contentShape(Rectangle())
            .position(x: r.midX, y: r.midY)
            .onTapGesture(perform: action)
    }

    private func itemLayer(scene: CGRect) -> some View {
        ForEach(HideableItem.allCases) { item in
            if !model.isHidden(item) {
                itemToken(item: item, scene: scene)
            }
        }
    }

    private func itemToken(item: HideableItem, scene: CGRect) -> some View {
        let center = model.itemCenters[item] ?? item.startCenter
        let pt = scenePoint(normalized: center, in: scene)
        let side = min(scene.width, scene.height) * 0.11

        return Image(item.spriteAsset)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: side * 1.35, height: side)
            .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
            .position(pt)
            .accessibilityHidden(true)
            .gesture(itemDragGesture(item: item, scene: scene))
    }

    private func itemDragGesture(item: HideableItem, scene: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if itemDragOriginNorm[item] == nil {
                    itemDragOriginNorm[item] = model.itemCenters[item] ?? item.startCenter
                }
                guard let origin = itemDragOriginNorm[item] else { return }
                let startPt = scenePoint(normalized: origin, in: scene)
                let endPt = CGPoint(x: startPt.x + value.translation.width, y: startPt.y + value.translation.height)
                let endNorm = normalizedPoint(scene: endPt, in: scene)
                model.setItemCenter(item, clampItemCenter(endNorm))
            }
            .onEnded { _ in
                itemDragOriginNorm[item] = nil
                model.syncBoxAndCabinetPendingAfterItemMove(item)
            }
    }

    private func clothWrapPulseLayer(scene: CGRect) -> some View {
        Group {
            if let n = model.clothWrapPulseNorm {
                let pt = scenePoint(normalized: n, in: scene)
                Image("ToolClothRack")
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: scene.width * 0.14)
                    .scaleEffect(wrapPulseScale)
                    .opacity(0.75 + 0.2 * (2.0 - Double(wrapPulseScale)))
                    .position(pt)
                    .allowsHitTesting(false)
            }
        }
    }

    private func clothVisual(scene: CGRect) -> some View {
        let clothPt = scenePoint(normalized: model.clothNormCenter, in: scene)
        let w = scene.width * 0.22
        return Image("ToolClothRack")
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: w)
            .shadow(color: .black.opacity(model.carryingCloth ? 0.35 : 0.18), radius: model.carryingCloth ? 10 : 5, y: 4)
            .position(clothPt)
            .allowsHitTesting(false)
    }

    private func clothGestureLayer(scene: CGRect) -> some View {
        let r = rectInScene(ToolHotspot.cloth, scene: scene)
        return Color.clear
            .frame(width: r.width, height: r.height)
            .contentShape(Rectangle())
            .position(x: r.midX, y: r.midY)
            .gesture(clothDragGesture(scene: scene))
    }

    private func clothDragGesture(scene: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if clothDragOriginNorm == nil {
                    clothDragOriginNorm = model.clothNormCenter
                }
                guard let origin = clothDragOriginNorm else { return }
                model.beginClothDragIfNeeded()
                let startPt = scenePoint(normalized: origin, in: scene)
                let endPt = CGPoint(x: startPt.x + value.translation.width, y: startPt.y + value.translation.height)
                let n = clampClothCenter(normalizedPoint(scene: endPt, in: scene))
                model.updateClothDuringDrag(n)
            }
            .onEnded { _ in
                clothDragOriginNorm = nil
                model.endClothDrag(at: model.clothNormCenter)
            }
    }

    private var hud: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .overlay(alignment: .top) {
                HStack(spacing: 10) {
                    HStack(spacing: 5) {
                        ForEach(0..<HideableItem.allCases.count, id: \.self) { i in
                            Circle()
                                .fill(Color.primary.opacity(i < model.hiddenCount ? 0.85 : 0.18))
                                .frame(width: 7, height: 7)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Spacer()
                    Button {
                        model.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.primary.opacity(0.9))
                    }
                    .accessibilityLabel(Text("Reset"))
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .allowsHitTesting(true)
            }
            .overlay(alignment: .bottom) {
                statusHints
                    .padding(.bottom, 10)
                    .allowsHitTesting(false)
            }
    }

    private var statusHints: some View {
        VStack(spacing: 4) {
            if model.rugCornerLifted {
                Text("Move a piece into the folded area, then tap the same floor region again.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            if model.boxOpen {
                Text(model.itemPendingBox != nil ? "Tap the same spot again to close." : "Move a piece over the opening, then tap to close.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            if model.cabinetOpen {
                Text(model.itemPendingCabinet != nil ? "Tap the same spot again to close." : "Move a piece inside, then tap to close.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    BalconyGameView()
}
