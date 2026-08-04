import SwiftUI

enum PlantState {
    case withered
    case recovering
    case healthy
}

struct PlantingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var plantState: PlantState = .withered
    @State private var hasRemovedBug = false
    @State private var hasWatered = false
    @State private var hasTrimmed = false
    @State private var bugOffset: CGFloat = 0
    @State private var showWaterDrops = false
    @State private var showScissors = false
    @State private var showCompletion = false

    private let witheredPlantImage = "半枯萎状态"
    private let healthyPlantImage = "阳台近景"

    private var isHealthy: Bool {
        hasRemovedBug && hasWatered && hasTrimmed
    }

    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.86, blue: 0.74).ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                    }
                    Spacer()
                    Text("植物养护")
                        .font(.title2.bold())
                    Spacer()
                    Color.clear.frame(width: 28)
                }

                ZStack {
                    plantImage
                    if showWaterDrops { waterEffect }
                    if showScissors {
                        Text("✂️")
                            .font(.system(size: 42))
                            .offset(x: 90, y: 15)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                    if !hasRemovedBug {
                        Text("🐛")
                            .font(.system(size: 28))
                            .offset(x: 95 + bugOffset, y: -105)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 300)
                .clipped()

                Text(isHealthy ? "植物已经恢复健康！" : "完成三项养护，让植物恢复生机")
                    .font(.headline)
                    .foregroundStyle(.primary.opacity(0.8))
                    .animation(.easeInOut, value: isHealthy)

                VStack(spacing: 12) {
                    careButton("🐛", "除虫", completed: hasRemovedBug) { removeBug() }
                    careButton("💧", "浇水", completed: hasWatered) { waterPlant() }
                    careButton("✂️", "修剪枝叶", completed: hasTrimmed) { trimPlant() }
                }
                .padding(.horizontal, 28)

                Spacer()
            }
            .padding(20)

            if showCompletion {
                Text("养护完成")
                    .font(.title3.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.green.opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 70)
            }
        }
    }

    private var plantImage: some View {
        Image(isHealthy ? healthyPlantImage : witheredPlantImage)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 390, maxHeight: 330)
            .scaleEffect(plantState == .recovering ? 0.94 : 1)
            .opacity(plantState == .recovering ? 0.25 : 1)
            .animation(.easeInOut(duration: 1), value: isHealthy)
            .animation(.spring(response: 0.45, dampingFraction: 0.65), value: plantState == .recovering)
    }

    private var waterEffect: some View {
        VStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { _ in Text("💧") }
        }
        .font(.title3)
        .offset(y: -130)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func careButton(_ icon: String, _ title: String, completed: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(icon).font(.title3)
                Text(completed ? "\(title)完成" : title).font(.headline)
                Spacer()
                Image(systemName: completed ? "checkmark.circle.fill" : "chevron.right")
            }
            .foregroundStyle(completed ? .green : .primary)
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(completed)
    }

    private func finishIfNeeded() {
        guard isHealthy else { return }
        withAnimation(.easeInOut(duration: 1)) { plantState = .healthy }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(0.8)) { showCompletion = true }
    }

    private func removeBug() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { bugOffset = 180 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation { hasRemovedBug = true; plantState = .recovering }
            finishIfNeeded()
        }
    }

    private func waterPlant() {
        withAnimation(.easeInOut(duration: 0.55)) { showWaterDrops = true; plantState = .recovering }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation { hasWatered = true; showWaterDrops = false }
            finishIfNeeded()
        }
    }

    private func trimPlant() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showScissors = true; plantState = .recovering }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation { hasTrimmed = true; showScissors = false }
            finishIfNeeded()
        }
    }
}

#Preview {
    PlantingView()
}
